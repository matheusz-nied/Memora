import 'dart:typed_data';

import 'pdf_filters.dart';
import 'pdf_lexer.dart';
import 'pdf_objects.dart';

/// Falha de leitura do PDF com um motivo que dá para explicar ao usuário.
class PdfParseException implements Exception {
  const PdfParseException(this.reason);

  final String reason;

  @override
  String toString() => 'PdfParseException: $reason';
}

/// Uma página, já com os atributos herdados da árvore resolvidos.
class PdfPage {
  const PdfPage({required this.content, required this.resources});

  /// Bytes concatenados de `/Contents`, já descomprimidos.
  final Uint8List content;

  /// `/Resources` da página ou do ancestral mais próximo que declarou um.
  final Map<String, Object?> resources;
}

/// O arquivo PDF inteiro: tabela de objetos, resolução de referências e a
/// árvore de páginas.
///
/// A leitura da tabela tem dois caminhos. O normal segue a cadeia de `xref` a
/// partir de `startxref`, como manda a especificação. Quando isso falha — e
/// falha bastante, porque PDF sai truncado de download, remendado por editor
/// que não atualizou os offsets, ou concatenado por script — cai numa
/// varredura bruta que acha todo `N G obj` do arquivo. A varredura é mais lenta
/// e ignora a semântica de atualização incremental, mas abre documento que
/// leitor estrito recusa, e aqui abrir vale mais que ser rigoroso.
class PdfDocument {
  PdfDocument._(this._bytes);

  final Uint8List _bytes;

  final Map<int, _XrefEntry> _xref = {};
  final Map<int, Object?> _cache = {};
  final Map<int, Map<int, Object?>> _objectStreams = {};
  // Mutável de propósito: `_loadFromXref` funde os trailers da cadeia neste
  // mapa. Um `const {}` aqui compila e explode em tempo de execução no
  // primeiro `putIfAbsent`, derrubando o caminho normal de leitura para a
  // varredura bruta — sem erro visível, só mais lento e menos preciso.
  Map<String, Object?> _trailer = <String, Object?>{};

  /// Teto de páginas percorridas na árvore.
  ///
  /// Não é a regra de negócio (essa é do gateway) — é só um freio contra
  /// `/Kids` montado de propósito para não terminar nunca.
  static const int _pageWalkLimit = 50000;

  static PdfDocument parse(Uint8List bytes) {
    if (bytes.length < 32) {
      throw const PdfParseException('arquivo pequeno demais para ser um PDF');
    }

    final document = PdfDocument._(bytes);
    document._load();
    return document;
  }

  void _load() {
    var viaXref = false;
    try {
      viaXref = _loadFromXref();
    } catch (_) {
      viaXref = false;
    }

    // A tabela só vale se levar mesmo ao catálogo: offset defasado costuma
    // apontar para o meio de outro objeto e produzir um `/Root` inútil.
    if (!viaXref || _resolveRootPages() == null) {
      _xref.clear();
      _cache.clear();
      _objectStreams.clear();
      _scanAllObjects();
    }

    if (_trailer['Encrypt'] != null) {
      // Sem suporte a criptografia: os streams sairiam como ruído e o usuário
      // veria "PDF sem texto", que manda ele procurar o arquivo errado.
      throw const PdfParseException('PDF protegido por criptografia');
    }

    if (_resolveRootPages() == null) {
      throw const PdfParseException('árvore de páginas não encontrada');
    }
  }

  // -------------------------------------------------------- tabela de objetos

  bool _loadFromXref() {
    final start = _findStartXref();
    if (start < 0) return false;

    final visited = <int>{};
    var offset = start;
    var loadedAny = false;

    while (offset >= 0 && offset < _bytes.length && visited.add(offset)) {
      final trailer = _readXrefSection(offset);
      if (trailer == null) break;
      loadedAny = true;

      // Dicionários mais novos vêm primeiro: quem já está no mapa vence.
      for (final entry in trailer.entries) {
        _trailer.putIfAbsent(entry.key, () => entry.value);
      }

      // Arquivo híbrido: a seção clássica é um esqueleto e os objetos de
      // verdade estão no xref stream apontado por `/XRefStm`.
      final hybrid = trailer['XRefStm'];
      if (hybrid is num && visited.add(hybrid.toInt())) {
        _readXrefSection(hybrid.toInt());
      }

      final prev = trailer['Prev'];
      offset = prev is num ? prev.toInt() : -1;
    }

    return loadedAny && _xref.isNotEmpty;
  }

  int _findStartXref() {
    // `startxref` fica no rodapé, mas há arquivos com lixo depois do `%%EOF`.
    // Uma janela generosa cobre isso sem varrer o arquivo todo.
    const window = 4096;
    final from = _bytes.length > window ? _bytes.length - window : 0;
    const word = 'startxref';

    for (var i = _bytes.length - word.length; i >= from; i--) {
      var hit = true;
      for (var j = 0; j < word.length; j++) {
        if (_bytes[i + j] != word.codeUnitAt(j)) {
          hit = false;
          break;
        }
      }
      if (!hit) continue;

      final lexer = PdfLexer(_bytes, i + word.length);
      final value = lexer.parseObject();
      return value is num ? value.toInt() : -1;
    }
    return -1;
  }

  /// Lê uma seção de xref — clássica ou stream — e devolve o trailer dela.
  Map<String, Object?>? _readXrefSection(int offset) {
    if (offset < 0 || offset >= _bytes.length) return null;

    final lexer = PdfLexer(_bytes, offset)..skipWhitespace();

    if (lexer.matches('xref')) {
      lexer.pos += 'xref'.length;
      return _readClassicXref(lexer);
    }

    // Xref stream: o offset aponta para `N G obj << /Type /XRef ... >>`.
    final object = _parseIndirectAt(offset);
    if (object is! PdfStream) return null;
    _readXrefStream(object);
    return object.dict;
  }

  Map<String, Object?>? _readClassicXref(PdfLexer lexer) {
    while (true) {
      lexer.skipWhitespace();
      if (lexer.atEnd) return null;

      if (lexer.matches('trailer')) {
        lexer.pos += 'trailer'.length;
        final dict = lexer.parseObject();
        return dict is Map<String, Object?> ? dict : const {};
      }

      final first = lexer.parseObject();
      final count = lexer.parseObject();
      if (first is! num || count is! num) return const {};

      final start = first.toInt();
      final total = count.toInt();
      if (total < 0 || total > 5000000) return const {};

      for (var i = 0; i < total; i++) {
        final position = lexer.parseObject();
        final generation = lexer.parseObject();
        final kind = lexer.parseObject();
        if (position is! num || generation is! num) return const {};

        // `n` é objeto vivo; `f` é slot livre e não entra na tabela.
        if (kind is PdfKeyword && kind.value == 'n') {
          _xref.putIfAbsent(start + i, () => _AtOffset(position.toInt()));
        }
      }
    }
  }

  void _readXrefStream(PdfStream stream) {
    final widths = resolve(stream.dict['W']);
    if (widths is! List || widths.length < 3) return;

    final w = widths.map((e) => (resolve(e) as num?)?.toInt() ?? 0).toList();
    final rowLength = w.fold<int>(0, (sum, value) => sum + value);
    if (rowLength <= 0) return;

    final data = PdfFilters.decode(stream, resolve);

    // Sem `/Index`, a seção cobre de 0 até `/Size`.
    final indexObject = resolve(stream.dict['Index']);
    final index = <int>[];
    if (indexObject is List && indexObject.length >= 2) {
      for (final value in indexObject) {
        final resolved = resolve(value);
        if (resolved is num) index.add(resolved.toInt());
      }
    }
    if (index.length < 2) {
      final size = resolve(stream.dict['Size']);
      index
        ..clear()
        ..addAll([0, size is num ? size.toInt() : data.length ~/ rowLength]);
    }

    var cursor = 0;
    for (var section = 0; section + 1 < index.length; section += 2) {
      final start = index[section];
      final count = index[section + 1];

      for (var i = 0; i < count; i++) {
        if (cursor + rowLength > data.length) return;

        var field = 0;
        final values = <int>[];
        for (final width in w) {
          var value = 0;
          for (var b = 0; b < width; b++) {
            value = (value << 8) | data[cursor++];
          }
          values.add(value);
          field++;
        }
        if (field < 3) return;

        // Campo 1 ausente (`W[0] == 0`) significa tipo 1, por especificação.
        final type = w[0] == 0 ? 1 : values[0];
        final number = start + i;

        if (type == 1) {
          _xref.putIfAbsent(number, () => _AtOffset(values[1]));
        } else if (type == 2) {
          _xref.putIfAbsent(
            number,
            () => _InObjectStream(values[1], values[2]),
          );
        }
        // Tipo 0 é slot livre: fica de fora.
      }
    }
  }

  /// Varre o arquivo inteiro atrás de `N G obj`, ignorando a tabela.
  ///
  /// Última definição vence, que é a aproximação certa para atualização
  /// incremental na esmagadora maioria dos arquivos.
  void _scanAllObjects() {
    final limit = _bytes.length - 3;

    for (var i = 0; i < limit; i++) {
      // Procura `obj` e volta lendo os dois inteiros que o antecedem.
      if (_bytes[i] != 0x6F || _bytes[i + 1] != 0x62 || _bytes[i + 2] != 0x6A) {
        continue;
      }
      // `obj` tem que ser palavra inteira, e não o fim de `endobj`.
      if (i + 3 < _bytes.length && PdfLexer.isRegular(_bytes[i + 3])) continue;

      var cursor = i - 1;
      cursor = _skipBackWhitespace(cursor);
      final generationEnd = cursor;
      cursor = _skipBackDigits(cursor);
      if (cursor == generationEnd) continue;

      cursor = _skipBackWhitespace(cursor);
      final numberEnd = cursor;
      final numberStart = _skipBackDigits(cursor);
      if (numberStart == numberEnd) continue;

      final number = int.tryParse(
        String.fromCharCodes(_bytes, numberStart + 1, numberEnd + 1),
      );
      if (number == null) continue;

      _xref[number] = _AtOffset(numberStart + 1);
    }

    _scanObjectStreams();
    _recoverTrailer();
  }

  /// Registra os objetos que vivem comprimidos dentro de um `/Type /ObjStm`.
  ///
  /// A varredura por `N G obj` não os enxerga: eles não existem como objeto
  /// solto no arquivo, e sim como carga de outro. Num PDF 1.5 em diante é ali
  /// que costuma estar o catálogo e a árvore de páginas — sem este passo, a
  /// varredura acha milhares de objetos e mesmo assim não encontra a primeira
  /// página.
  void _scanObjectStreams() {
    // Ordenar uma vez permite achar o dono de cada ocorrência por busca
    // binária, em vez de reparsear todo objeto do arquivo só para descobrir
    // quais são object streams.
    final starts =
        _xref.entries
            .where((entry) => entry.value is _AtOffset)
            .map(
              (entry) => (
                offset: (entry.value as _AtOffset).offset,
                number: entry.key,
              ),
            )
            .toList()
          ..sort((a, b) => a.offset.compareTo(b.offset));

    if (starts.isEmpty) return;

    final containers = <int>{};
    var from = 0;

    while (true) {
      final at = _indexOf('/ObjStm', from);
      if (at < 0) break;
      from = at + 1;

      var low = 0;
      var high = starts.length - 1;
      var owner = -1;
      while (low <= high) {
        final middle = (low + high) >> 1;
        if (starts[middle].offset <= at) {
          owner = starts[middle].number;
          low = middle + 1;
        } else {
          high = middle - 1;
        }
      }

      if (owner >= 0) containers.add(owner);
    }

    for (final container in containers) {
      final contents = _objectStreams[container] ??= _loadObjectStream(
        container,
      );
      for (final number in contents.keys) {
        // `putIfAbsent`: objeto solto no arquivo é mais novo que a cópia
        // comprimida, então o que a varredura já achou tem preferência.
        _xref.putIfAbsent(number, () => _InObjectStream(container, 0));
      }
    }
  }

  int _indexOf(String word, int from) {
    final first = word.codeUnitAt(0);
    final limit = _bytes.length - word.length;
    for (var i = from; i <= limit; i++) {
      if (_bytes[i] != first) continue;
      var hit = true;
      for (var j = 1; j < word.length; j++) {
        if (_bytes[i + j] != word.codeUnitAt(j)) {
          hit = false;
          break;
        }
      }
      if (hit) return i;
    }
    return -1;
  }

  int _skipBackWhitespace(int from) {
    var i = from;
    while (i >= 0 && PdfLexer.isWhitespace(_bytes[i])) {
      i--;
    }
    return i;
  }

  int _skipBackDigits(int from) {
    var i = from;
    while (i >= 0 && _bytes[i] >= 0x30 && _bytes[i] <= 0x39) {
      i--;
    }
    return i;
  }

  /// Reconstrói o trailer quando a varredura assumiu o comando.
  void _recoverTrailer() {
    final recovered = <String, Object?>{};

    // Primeiro os `trailer` explícitos: o último do arquivo é o mais novo.
    var search = _bytes.length;
    while (search > 0) {
      final at = _lastIndexOf('trailer', search);
      if (at < 0) break;
      final dict = PdfLexer(_bytes, at + 'trailer'.length).parseObject();
      if (dict is Map<String, Object?>) {
        for (final entry in dict.entries) {
          recovered.putIfAbsent(entry.key, () => entry.value);
        }
      }
      if (recovered['Root'] != null) break;
      search = at;
    }

    // Ainda sem `/Root`: o catálogo é achado pelo próprio `/Type /Catalog`.
    // Também cobre arquivo cujo trailer só existe dentro de um xref stream.
    if (recovered['Root'] == null) {
      for (final number in _xref.keys) {
        final object = _objectAt(number);
        final dict = switch (object) {
          final Map<String, Object?> map => map,
          final PdfStream stream => stream.dict,
          _ => null,
        };
        if (dict == null) continue;

        if (dict['Type'] == 'Catalog' && dict['Pages'] != null) {
          recovered['Root'] = PdfRef(number, 0);
          break;
        }
        if (dict['Type'] == 'XRef' && dict['Root'] != null) {
          recovered.putIfAbsent('Root', () => dict['Root']);
          recovered.putIfAbsent('Encrypt', () => dict['Encrypt']);
        }
      }
    }

    // `/Encrypt` do trailer original importa mesmo na varredura: sem ele,
    // seguiríamos adiante decodificando ruído.
    if (recovered['Encrypt'] == null) {
      final at = _lastIndexOf('/Encrypt', _bytes.length);
      if (at >= 0) {
        final value = PdfLexer(_bytes, at + '/Encrypt'.length).parseObject();
        if (value is PdfRef || value is Map<String, Object?>) {
          recovered['Encrypt'] = value;
        }
      }
    }

    _trailer = recovered;
  }

  int _lastIndexOf(String word, int before) {
    for (var i = before - word.length; i >= 0; i--) {
      var hit = true;
      for (var j = 0; j < word.length; j++) {
        if (_bytes[i + j] != word.codeUnitAt(j)) {
          hit = false;
          break;
        }
      }
      if (hit) return i;
    }
    return -1;
  }

  // ------------------------------------------------------------- resolução

  /// Segue referências indiretas até chegar num objeto de verdade.
  Object? resolve(Object? value) {
    var current = value;
    // Ciclo de referência (`1 0 obj 2 0 R` / `2 0 obj 1 0 R`) existe em
    // arquivo corrompido; o teto corta sem precisar de conjunto de visitados.
    for (var hops = 0; hops < 32; hops++) {
      if (current is! PdfRef) return current;
      current = _objectAt(current.number);
    }
    return null;
  }

  Map<String, Object?>? dictOf(Object? value) {
    final resolved = resolve(value);
    return switch (resolved) {
      final Map<String, Object?> map => map,
      final PdfStream stream => stream.dict,
      _ => null,
    };
  }

  /// Bytes já descomprimidos de um stream.
  Uint8List? streamBytes(Object? value) {
    final resolved = resolve(value);
    if (resolved is! PdfStream) return null;
    try {
      return PdfFilters.decode(resolved, resolve);
    } catch (_) {
      return null;
    }
  }

  Object? _objectAt(int number) {
    if (_cache.containsKey(number)) return _cache[number];

    // Marca antes de carregar: objeto que se referencia indiretamente durante
    // o próprio parse (via `/Length`) pararia num laço infinito.
    _cache[number] = null;

    final entry = _xref[number];
    final Object? value = switch (entry) {
      _AtOffset(offset: final offset) => _parseIndirectAt(offset, number),
      _InObjectStream(container: final container, index: final index) =>
        _fromObjectStream(container, index, number),
      _ => null,
    };

    _cache[number] = value;
    return value;
  }

  /// Lê `N G obj <objeto> endobj` a partir de [offset].
  ///
  /// Quando [expected] é informado e o número não bate, o offset está defasado
  /// — devolve `null` para o chamador cair na varredura em vez de entregar um
  /// objeto que pertence a outro lugar do arquivo.
  Object? _parseIndirectAt(int offset, [int? expected]) {
    if (offset < 0 || offset >= _bytes.length) return null;

    final lexer = PdfLexer(_bytes, offset);
    final number = lexer.parseObject();
    final generation = lexer.parseObject();
    if (number is! num || generation is! num) return null;
    if (expected != null && number.toInt() != expected) return null;

    lexer.skipWhitespace();
    if (!lexer.matches('obj')) return null;
    lexer.pos += 'obj'.length;

    final value = lexer.parseObject();
    if (value == PdfToken.endOfInput ||
        value == PdfToken.arrayEnd ||
        value == PdfToken.dictEnd) {
      return null;
    }
    return value;
  }

  Object? _fromObjectStream(int container, int index, int expected) {
    final contents = _objectStreams[container] ??= _loadObjectStream(container);
    return contents[expected] ?? (index < 0 ? null : contents[expected]);
  }

  /// Descomprime um `/Type /ObjStm` e devolve os objetos que ele guarda.
  ///
  /// O layout é um cabeçalho de `N` pares `número deslocamento`, seguido pelos
  /// objetos a partir de `/First`.
  Map<int, Object?> _loadObjectStream(int number) {
    final entry = _xref[number];
    if (entry is! _AtOffset) return const {};

    final stream = _parseIndirectAt(entry.offset, number);
    if (stream is! PdfStream) return const {};

    final Uint8List data;
    try {
      data = PdfFilters.decode(stream, resolve);
    } catch (_) {
      return const {};
    }

    final count = resolve(stream.dict['N']);
    final first = resolve(stream.dict['First']);
    if (count is! num || first is! num) return const {};

    final header = PdfLexer(data);
    final offsets = <int, int>{};
    for (var i = 0; i < count.toInt(); i++) {
      final objectNumber = header.parseObject();
      final objectOffset = header.parseObject();
      if (objectNumber is! num || objectOffset is! num) break;
      offsets[objectNumber.toInt()] = first.toInt() + objectOffset.toInt();
    }

    final out = <int, Object?>{};
    for (final pair in offsets.entries) {
      if (pair.value < 0 || pair.value >= data.length) continue;
      final value = PdfLexer(data, pair.value).parseObject();
      if (value == PdfToken.endOfInput) continue;
      out[pair.key] = value;
    }
    return out;
  }

  // ----------------------------------------------------------------- páginas

  Map<String, Object?>? _resolveRootPages() {
    final root = dictOf(_trailer['Root']);
    final pages = dictOf(root?['Pages']);
    if (pages != null && pages['Kids'] != null) return pages;

    // Catálogo quebrado mas páginas intactas: acha o nó raiz pelo tipo. É o
    // que salva PDF remendado, em que só o `/Root` ficou apontando errado.
    for (final number in _xref.keys) {
      final dict = dictOf(PdfRef(number, 0));
      if (dict == null) continue;
      if (dict['Type'] == 'Pages' && dict['Kids'] != null) {
        // Só o nó de topo: um nó intermediário perderia as outras páginas.
        if (dict['Parent'] == null) return dict;
      }
    }
    return null;
  }

  /// Percorre a árvore e devolve as páginas na ordem do documento.
  ///
  /// Não descomprime `/Contents` aqui: contar páginas é barato e o gateway
  /// precisa da contagem antes de decidir se vale extrair alguma coisa.
  List<Map<String, Object?>> pageDicts() {
    final root = _resolveRootPages();
    if (root == null) return const [];

    final out = <Map<String, Object?>>[];
    final seen = <Object>{};

    void walk(Map<String, Object?> node, Map<String, Object?> inherited) {
      if (out.length >= _pageWalkLimit) return;

      // Atributos herdáveis: o nó filho sobrescreve, o resto desce.
      final context = Map<String, Object?>.from(inherited);
      for (final key in const ['Resources', 'MediaBox', 'CropBox', 'Rotate']) {
        if (node[key] != null) context[key] = node[key];
      }

      final kids = resolve(node['Kids']);
      if (kids is! List || kids.isEmpty) {
        // Folha. `/Type` costuma dizer `/Page`, mas falta em arquivo ruim —
        // não ter `/Kids` já é sinal suficiente.
        if (node['Type'] != 'Pages') {
          out.add({...context, ...node});
        }
        return;
      }

      for (final kid in kids) {
        // `/Kids` cíclico trava a varredura; a marca é a referência, porque é
        // ela que se repete.
        if (kid is PdfRef && !seen.add(kid)) continue;
        final child = dictOf(kid);
        if (child == null) continue;
        walk(child, context);
        if (out.length >= _pageWalkLimit) return;
      }
    }

    walk(root, const {});
    return out;
  }

  /// Monta a página [index], já com conteúdo descomprimido e concatenado.
  PdfPage loadPage(Map<String, Object?> dict) {
    final builder = BytesBuilder(copy: false);

    final contents = resolve(dict['Contents']);
    final parts = contents is List ? contents : [dict['Contents']];

    for (final part in parts) {
      final data = streamBytes(part);
      if (data == null) continue;
      builder.add(data);
      // `/Contents` em array é um único fluxo partido em pedaços, e a quebra
      // pode cair no meio de um operador. O separador reconstitui o token.
      builder.addByte(0x0A);
    }

    return PdfPage(
      content: builder.takeBytes(),
      resources: dictOf(dict['Resources']) ?? const {},
    );
  }
}

sealed class _XrefEntry {
  const _XrefEntry();
}

/// Objeto gravado direto no arquivo, em [offset].
class _AtOffset extends _XrefEntry {
  const _AtOffset(this.offset);

  final int offset;
}

/// Objeto guardado comprimido dentro de um `/Type /ObjStm`.
class _InObjectStream extends _XrefEntry {
  const _InObjectStream(this.container, this.index);

  final int container;
  final int index;
}
