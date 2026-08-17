/// Texto extraído de um PDF, pronto para ser fatiado e virar cards.
class PdfExtractionResult {
  const PdfExtractionResult({required this.text, required this.pages});

  final String text;
  final int pages;
}
