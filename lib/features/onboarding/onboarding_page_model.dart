enum OnboardingVisualType { study, ai, privacy, apiKey }

class OnboardingPageModel {
  const OnboardingPageModel({
    required this.visualType,
    required this.title,
    required this.titleAccent,
    required this.description,
  });

  final OnboardingVisualType visualType;
  final String title;
  final String titleAccent;
  final String description;
}

class OnboardingText {
  const OnboardingText._();

  static const String skip = 'Pular';
  static const String next = 'Próximo';
  static const String setupKey = 'Cadastrar minha chave';
  static const String skipKey = 'Depois, quero só criar cards';

  /// A primeira impressão do app.
  ///
  /// Prometer o que ele não faz — conta, sync, IA inclusa — é o jeito mais
  /// rápido de perder quem acabou de baixar. As quatro páginas dizem
  /// exatamente o que existe.
  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      visualType: OnboardingVisualType.study,
      title: 'Estude o que está para esquecer',
      titleAccent: 'para esquecer',
      description:
          'O Memora agenda cada card pela repetição espaçada e mostra só o '
          'que vence hoje. Você estuda menos e lembra mais.',
    ),
    OnboardingPageModel(
      visualType: OnboardingVisualType.ai,
      title: 'A IA é sua, com a sua chave',
      titleAccent: 'sua chave',
      description:
          'Cole sua chave da DeepSeek e gere cards de textos e PDFs, peça '
          'explicações e converse com um tutor. Você paga direto à DeepSeek — '
          'o app não cobra nada nem intermedia.',
    ),
    OnboardingPageModel(
      visualType: OnboardingVisualType.privacy,
      title: 'Seus dados não saem daqui',
      titleAccent: 'não saem daqui',
      description:
          'Sem conta, sem servidor, sem nuvem: decks, cards e histórico ficam '
          'neste aparelho. Por isso, exporte um backup de vez em quando.',
    ),
    OnboardingPageModel(
      visualType: OnboardingVisualType.apiKey,
      title: 'Falta só a chave',
      titleAccent: 'a chave',
      description:
          'Crie uma chave em platform.deepseek.com e cole no app. Sem ela você '
          'ainda cria e estuda cards à mão — só os recursos de IA ficam '
          'desligados.',
    ),
  ];
}
