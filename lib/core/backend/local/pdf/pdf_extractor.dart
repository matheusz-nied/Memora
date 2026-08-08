import 'dart:typed_data';

import 'pdf_document.dart';
import 'pdf_text.dart';

export 'pdf_document.dart' show PdfParseException;

/// Texto de um PDF e quantas páginas ele tinha.
class PdfTextResult {
  const PdfTextResult({required this.text, required this.pages});

  final String text;
  final int pages;
}

/// Extrai o texto de um PDF inteiro.
///
/// Ponto de entrada do extrator próprio do app — é síncrono de propósito, para
/// caber num `compute` sem adaptação, e não depende de Flutter, para poder ser
/// testado como Dart puro.
///
/// Quando [maxPages] é informado e o documento passa do limite, devolve texto
/// vazio com a contagem real: quem chamou vai recusar o arquivo de qualquer
/// jeito, e extrair centenas de páginas para depois descartar é trabalho jogado
/// fora no aparelho do usuário.
PdfTextResult extractPdfText(Uint8List bytes, {int? maxPages}) {
  final document = PdfDocument.parse(bytes);
  final pages = document.pageDicts();

  if (maxPages != null && pages.length > maxPages) {
    return PdfTextResult(text: '', pages: pages.length);
  }

  final extractor = PdfTextExtractor(document);
  final buffer = StringBuffer();

  for (final dict in pages) {
    final String text;
    try {
      text = extractor.extractPage(document.loadPage(dict));
    } catch (_) {
      // Uma página ilegível não invalida o documento. Slide com objeto
      // corrompido no meio é comum, e as outras páginas ainda rendem cards.
      continue;
    }

    if (text.trim().isEmpty) continue;
    if (buffer.isNotEmpty) buffer.write('\n\n');
    buffer.write(text);
  }

  return PdfTextResult(text: _tidy(buffer.toString()), pages: pages.length);
}

/// Normaliza o resultado para leitura.
///
/// A saída bruta carrega marcas do desenho: espaço no fim da linha, linha
/// vazia onde havia cabeçalho, e a quebra que o PDF usa para justificar dentro
/// do parágrafo. Nada disso é conteúdo, e tudo isso consome contexto do modelo
/// que vai gerar os cards.
String _tidy(String text) {
  final lines = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .toList();

  final out = StringBuffer();
  var blankRun = 0;

  for (final line in lines) {
    if (line.isEmpty) {
      blankRun++;
      // Mais de uma linha em branco seguida vira uma só.
      if (blankRun <= 1 && out.isNotEmpty) out.write('\n');
      continue;
    }
    blankRun = 0;
    if (out.isNotEmpty) out.write('\n');
    out.write(line);
  }

  return out.toString().trim();
}
