/// Um card validado, ainda sem identidade ou progresso persistidos.
class CardDraft {
  const CardDraft({required this.front, required this.back});

  final String front;
  final String back;
}
