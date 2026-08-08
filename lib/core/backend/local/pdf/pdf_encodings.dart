/// Tabelas fixas da especificação: codificações padrão, nomes de glifo e as
/// métricas das fontes base.
///
/// São dados, não lógica — ficam separados de `pdf_fonts.dart` para que o
/// arquivo com as regras continue legível.
///
/// As tabelas de codificação são listas de codepoints em hexadecimal, e não
/// strings com os caracteres de verdade. Escrever `‚` e `„` direto no fonte
/// parece mais claro e é justamente o contrário: são tabelas **posicionais**,
/// em que um caractere a mais ou a menos desloca todo o resto e passa a trocar
/// letras sem erro nenhum aparecer. Em hexadecimal a posição é contável, o
/// diff é legível e `0` (sem glifo) para de ser um byte invisível.
library;

/// Nome de glifo → codepoint.
///
/// É o subconjunto da Adobe Glyph List que aparece de fato em `/Differences`.
/// Nomes de uma letra só (`A`, `z`, `7`) não estão aqui: são resolvidos pela
/// regra em [glyphToRune], que também cobre as formas `uniXXXX` e `uXXXXXX`.
const String _glyphList =
    // ASCII com nome
    'space:20 exclam:21 quotedbl:22 numbersign:23 dollar:24 percent:25 '
    'ampersand:26 quotesingle:27 parenleft:28 parenright:29 asterisk:2A '
    'plus:2B comma:2C hyphen:2D period:2E slash:2F colon:3A semicolon:3B '
    'less:3C equal:3D greater:3E question:3F at:40 bracketleft:5B '
    'backslash:5C bracketright:5D asciicircum:5E underscore:5F grave:60 '
    'braceleft:7B bar:7C braceright:7D asciitilde:7E '
    // dígitos por extenso, como a AGL escreve
    'zero:30 one:31 two:32 three:33 four:34 five:35 six:36 seven:37 '
    'eight:38 nine:39 '
    // Latin-1
    'exclamdown:A1 cent:A2 sterling:A3 currency:A4 yen:A5 brokenbar:A6 '
    'section:A7 dieresis:A8 copyright:A9 ordfeminine:AA guillemotleft:AB '
    'logicalnot:AC registered:AE macron:AF degree:B0 plusminus:B1 '
    'twosuperior:B2 threesuperior:B3 acute:B4 mu:B5 paragraph:B6 '
    'periodcentered:B7 cedilla:B8 onesuperior:B9 ordmasculine:BA '
    'guillemotright:BB onequarter:BC onehalf:BD threequarters:BE '
    'questiondown:BF multiply:D7 divide:F7 '
    'Agrave:C0 Aacute:C1 Acircumflex:C2 Atilde:C3 Adieresis:C4 Aring:C5 '
    'AE:C6 Ccedilla:C7 Egrave:C8 Eacute:C9 Ecircumflex:CA Edieresis:CB '
    'Igrave:CC Iacute:CD Icircumflex:CE Idieresis:CF Eth:D0 Ntilde:D1 '
    'Ograve:D2 Oacute:D3 Ocircumflex:D4 Otilde:D5 Odieresis:D6 Oslash:D8 '
    'Ugrave:D9 Uacute:DA Ucircumflex:DB Udieresis:DC Yacute:DD Thorn:DE '
    'germandbls:DF agrave:E0 aacute:E1 acircumflex:E2 atilde:E3 '
    'adieresis:E4 aring:E5 ae:E6 ccedilla:E7 egrave:E8 eacute:E9 '
    'ecircumflex:EA edieresis:EB igrave:EC iacute:ED icircumflex:EE '
    'idieresis:EF eth:F0 ntilde:F1 ograve:F2 oacute:F3 ocircumflex:F4 '
    'otilde:F5 odieresis:F6 oslash:F8 ugrave:F9 uacute:FA ucircumflex:FB '
    'udieresis:FC yacute:FD thorn:FE ydieresis:FF '
    // Latin estendido e acentos soltos
    'dotlessi:131 Lslash:141 lslash:142 OE:152 oe:153 Scaron:160 '
    'scaron:161 Ydieresis:178 Zcaron:17D zcaron:17E florin:192 '
    'circumflex:2C6 caron:2C7 breve:2D8 dotaccent:2D9 ring:2DA ogonek:2DB '
    'tilde:2DC hungarumlaut:2DD '
    // pontuação tipográfica
    'endash:2013 emdash:2014 quoteleft:2018 quoteright:2019 '
    'quotesinglbase:201A quotedblleft:201C quotedblright:201D '
    'quotedblbase:201E dagger:2020 daggerdbl:2021 bullet:2022 '
    'ellipsis:2026 perthousand:2030 guilsinglleft:2039 guilsinglright:203A '
    'fraction:2044 Euro:20AC trademark:2122 minus:2212 fi:FB01 fl:FB02 '
    // símbolos que aparecem em texto técnico
    'Delta:394 Omega:3A9 pi:3C0 partialdiff:2202 product:220F '
    'summation:2211 radical:221A infinity:221E integral:222B '
    'approxequal:2248 notequal:2260 lessequal:2264 greaterequal:2265 '
    'lozenge:25CA apple:F8FF';

Map<String, int>? _glyphCache;

Map<String, int> get _glyphs {
  final cached = _glyphCache;
  if (cached != null) return cached;

  final map = <String, int>{};
  for (final entry in _glyphList.split(' ')) {
    final split = entry.indexOf(':');
    if (split <= 0) continue;
    final rune = int.tryParse(entry.substring(split + 1), radix: 16);
    if (rune != null) map[entry.substring(0, split)] = rune;
  }
  return _glyphCache = map;
}

/// Converte um nome de glifo de `/Differences` no caractere correspondente.
///
/// Devolve `0` quando não dá para saber — caso de `g23` ou `cid117`, nomes que
/// carregam índice interno da fonte e nenhuma informação sobre o texto.
int glyphToRune(String name) {
  if (name.isEmpty) return 0;

  final known = _glyphs[name];
  if (known != null) return known;

  // Nome de um caractere só: `A`, `7`, `%`.
  if (name.length == 1) return name.codeUnitAt(0);

  // Formas explícitas da AGL: `uni0041` e `u1F600`.
  if (name.startsWith('uni') && name.length >= 7) {
    final rune = int.tryParse(name.substring(3, 7), radix: 16);
    if (rune != null) return rune;
  }
  if (name.startsWith('u') && name.length >= 5 && name.length <= 7) {
    final rune = int.tryParse(name.substring(1), radix: 16);
    if (rune != null) return rune;
  }

  // `Aacute.sc`, `one.oldstyle`: sufixo de variante estilística. A base ainda
  // diz qual é o texto.
  final dot = name.indexOf('.');
  if (dot > 0) return glyphToRune(name.substring(0, dot));

  return 0;
}

/// Nome de glifo → texto, já resolvendo ligaduras escritas com `_` (`f_i`).
String glyphToText(String name) {
  if (name.contains('_')) {
    final buffer = StringBuffer();
    for (final part in name.split('_')) {
      final rune = glyphToRune(part);
      if (rune > 0) buffer.writeCharCode(rune);
    }
    return buffer.toString();
  }

  final rune = glyphToRune(name);
  return rune > 0 ? String.fromCharCode(rune) : '';
}

// --------------------------------------------------------------- codificações

/// 0x80–0x9F do WinAnsiEncoding, um por linha de oito. O resto do intervalo
/// alto é Latin-1 puro, então sai por cálculo em [buildEncoding].
const String _winAnsiUpper =
    '20AC,0,201A,192,201E,2026,2020,2021,' // 80–87
    '2C6,2030,160,2039,152,0,17D,0,' // 88–8F
    '0,2018,2019,201C,201D,2022,2013,2014,' // 90–97
    '2DC,2122,161,203A,153,0,17E,178'; // 98–9F

/// 0x80–0xFF do MacRomanEncoding, na variante do PDF (0xCA é `space`).
const String _macRomanUpper =
    'C4,C5,C7,C9,D1,D6,DC,E1,' // 80–87
    'E0,E2,E4,E3,E5,E7,E9,E8,' // 88–8F
    'EA,EB,ED,EC,EE,EF,F1,F3,' // 90–97
    'F2,F4,F6,F5,FA,F9,FB,FC,' // 98–9F
    '2020,B0,A2,A3,A7,2022,B6,DF,' // A0–A7
    'AE,A9,2122,B4,A8,2260,C6,D8,' // A8–AF
    '221E,B1,2264,2265,A5,B5,2202,2211,' // B0–B7
    '220F,3C0,222B,AA,BA,3A9,E6,F8,' // B8–BF
    'BF,A1,AC,221A,192,2248,394,AB,' // C0–C7
    'BB,2026,20,C0,C3,D5,152,153,' // C8–CF
    '2013,2014,201C,201D,2018,2019,F7,25CA,' // D0–D7
    'FF,178,2044,A4,2039,203A,FB01,FB02,' // D8–DF
    '2021,B7,201A,201E,2030,C2,CA,C1,' // E0–E7
    'CB,C8,CD,CE,CF,CC,D3,D4,' // E8–EF
    'F8FF,D2,DA,DB,D9,131,2C6,2DC,' // F0–F7 (F8FF é o logo da Apple)
    'AF,2D8,2D9,2DA,B8,2DD,2DB,2C7'; // F8–FF

/// 0xA1–0xFF do StandardEncoding. Esparso de propósito: a tabela original tem
/// buracos, e cada um deles é um `0` aqui.
const String _standardUpper =
    'A1,A2,A3,2044,A5,192,A7,A4,' // A1–A8
    '27,201C,AB,2039,203A,FB01,FB02,0,' // A9–B0
    '2013,2020,2021,B7,0,B6,2022,201A,' // B1–B8
    '201E,201D,BB,2026,2030,0,BF,0,' // B9–C0
    '60,B4,2C6,2DC,AF,2D8,2D9,A8,' // C1–C8
    '0,2DA,B8,0,2DD,2DB,2C7,2014,' // C9–D0
    '0,0,0,0,0,0,0,0,' // D1–D8
    '0,0,0,0,0,0,0,0,' // D9–E0
    'C6,0,AA,0,0,0,0,141,' // E1–E8
    'D8,152,BA,0,0,0,0,0,' // E9–F0
    'E6,0,0,0,131,0,0,142,' // F1–F8
    'F8,153,DF,0,0,0,0'; // F9–FF

List<int> _codes(String source) =>
    source.split(',').map((value) => int.parse(value, radix: 16)).toList();

/// Nome da codificação base → tabela de 256 codepoints (`0` = sem glifo).
///
/// O intervalo 0x20–0x7E é ASCII nas três, com as duas exceções históricas do
/// StandardEncoding: `'` vira aspa curva de fechamento e `` ` `` vira a de
/// abertura, porque no desenho original elas eram acentos tipográficos.
List<int> buildEncoding(String? name) {
  final table = List<int>.filled(256, 0);

  for (var code = 0x20; code <= 0x7E; code++) {
    table[code] = code;
  }

  switch (name) {
    case 'WinAnsiEncoding':
      final upper = _codes(_winAnsiUpper);
      assert(upper.length == 32, 'WinAnsi 0x80–0x9F tem 32 posições');
      for (var i = 0; i < upper.length; i++) {
        table[0x80 + i] = upper[i];
      }
      // 0xA0–0xFF do CP1252 coincide com Latin-1, que coincide com Unicode.
      for (var code = 0xA0; code <= 0xFF; code++) {
        table[code] = code;
      }

    case 'MacRomanEncoding':
      final upper = _codes(_macRomanUpper);
      assert(upper.length == 128, 'MacRoman 0x80–0xFF tem 128 posições');
      for (var i = 0; i < upper.length; i++) {
        table[0x80 + i] = upper[i];
      }

    default:
      // StandardEncoding, e também o caso de fonte sem `/Encoding` — é a
      // codificação embutida que a especificação manda assumir.
      final upper = _codes(_standardUpper);
      assert(upper.length == 95, 'Standard 0xA1–0xFF tem 95 posições');
      table[0x27] = 0x2019;
      table[0x60] = 0x2018;
      for (var i = 0; i < upper.length; i++) {
        table[0xA1 + i] = upper[i];
      }
  }

  return table;
}

// ------------------------------------------------------------------ métricas

/// Larguras de 0x20 a 0x7E da Helvetica, em milésimos de em.
const String _helveticaWidths =
    '278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,'
    '556,556,556,556,556,556,556,556,556,556,278,278,584,584,584,556,'
    '1015,667,667,722,722,667,611,778,722,278,500,667,556,833,722,778,'
    '667,778,722,667,611,722,667,944,667,667,611,278,278,278,469,556,'
    '333,556,556,500,556,556,278,556,556,222,222,500,222,833,556,556,'
    '556,556,333,500,278,556,500,722,500,500,500,334,260,334,584';

/// Idem para a Times-Roman.
const String _timesWidths =
    '250,333,408,500,500,833,778,333,333,333,500,564,250,333,250,278,'
    '500,500,500,500,500,500,500,500,500,500,278,278,564,564,564,444,'
    '921,722,667,667,722,611,556,722,722,333,389,722,611,889,722,722,'
    '556,722,667,556,611,722,722,944,722,722,611,333,278,333,469,500,'
    '333,444,500,444,500,444,333,500,500,278,278,500,278,778,500,500,'
    '500,500,333,389,278,500,500,722,500,500,444,480,200,480,541';

Map<String, List<double>>? _metricsCache;

/// Métricas embutidas das fontes base do PDF (as "standard 14").
///
/// Essas fontes não trazem `/Widths` no arquivo — o leitor precisa conhecê-las.
/// Sem isso o cálculo de avanço erra e o extrator inventa espaço no meio das
/// palavras. As variantes negrito e itálico usam a métrica da reta: o erro é
/// pequeno e só desloca onde cai o espaço, nunca qual é o caractere.
Map<String, List<double>> get _metrics {
  final cached = _metricsCache;
  if (cached != null) return cached;

  List<double> parse(String source) {
    final values = source.split(',').map(double.parse).toList();
    assert(values.length == 95, 'métrica cobre 0x20–0x7E, que são 95 códigos');
    return values;
  }

  return _metricsCache = {
    'helvetica': parse(_helveticaWidths),
    'times': parse(_timesWidths),
    'courier': List<double>.filled(95, 600), // monoespaçada
  };
}

/// Largura do código [code] na fonte base [baseFont], ou `null` quando ela não
/// é uma das conhecidas.
double? standardWidth(String baseFont, int code) {
  if (code < 0x20 || code > 0x7E) return null;

  // O nome vem como `ABCDEF+Helvetica-BoldOblique`: prefixo de subconjunto na
  // frente e variante no fim, então a busca é por trecho.
  final name = baseFont.toLowerCase();
  final family = switch (name) {
    _ when name.contains('courier') || name.contains('mono') => 'courier',
    _
        when name.contains('times') ||
            name.contains('roman') ||
            name.contains('georgia') ||
            name.contains('serif') =>
      'times',
    _ when name.contains('helvetica') || name.contains('arial') => 'helvetica',
    _ => null,
  };

  if (family == null) return null;
  return _metrics[family]![code - 0x20];
}
