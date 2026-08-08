import 'package:flutter/material.dart';

class OnboardingPageModel {
  const OnboardingPageModel({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
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
      icon: Icons.psychology_outlined,
      title: 'Estude o que está para esquecer',
      description:
          'O Memora agenda cada card pela repetição espaçada e mostra só o '
          'que vence hoje. Você estuda menos e lembra mais.',
    ),
    OnboardingPageModel(
      icon: Icons.auto_awesome,
      title: 'A IA é sua, com a sua chave',
      description:
          'Cole sua chave da DeepSeek e gere cards de textos e PDFs, peça '
          'explicações e converse com um tutor. Você paga direto à DeepSeek — '
          'o app não cobra nada nem intermedia.',
    ),
    OnboardingPageModel(
      icon: Icons.phonelink_lock_outlined,
      title: 'Seus dados não saem daqui',
      description:
          'Sem conta, sem servidor, sem nuvem: decks, cards e histórico ficam '
          'neste aparelho. Por isso, exporte um backup de vez em quando.',
    ),
    OnboardingPageModel(
      icon: Icons.key_outlined,
      title: 'Falta só a chave',
      description:
          'Crie uma chave em platform.deepseek.com e cole no app. Sem ela você '
          'ainda cria e estuda cards à mão — só os recursos de IA ficam '
          'desligados.',
    ),
  ];
}
