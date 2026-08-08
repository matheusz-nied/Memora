import 'package:flutter/material.dart';

import '../../core/config/app_mode.dart';

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
  static const String start = 'Começar';
  static const String setupKey = 'Cadastrar minha chave';
  static const String skipKey = 'Depois, quero só criar cards';

  /// As páginas do modo ativo.
  ///
  /// Os dois modos são produtos diferentes na primeira impressão: um tem conta
  /// e sincroniza, o outro roda só no aparelho com a chave do usuário. Prometer
  /// o que não existe no build instalado é o jeito mais rápido de perder quem
  /// acabou de baixar.
  static List<OnboardingPageModel> get pages =>
      kIsLocalMode ? localPages : cloudPages;

  static const List<OnboardingPageModel> localPages = [
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

  static const List<OnboardingPageModel> cloudPages = [
    OnboardingPageModel(
      icon: Icons.auto_awesome,
      title: 'Domine qualquer assunto',
      description: 'Transforme PDFs e textos em decks claros para estudar.',
    ),
    OnboardingPageModel(
      icon: Icons.psychology_alt_outlined,
      title: 'Aprenda com IA',
      description: 'Gere cards, insights e explicações adaptadas ao seu deck.',
    ),
    OnboardingPageModel(
      icon: Icons.offline_bolt_outlined,
      title: 'Estude no seu ritmo',
      description: 'Revise cards offline e sincronize o progresso depois.',
    ),
    OnboardingPageModel(
      icon: Icons.school_outlined,
      title: 'Pronto para começar?',
      description: 'Configure seus decks e mantenha sua evolução em dia.',
    ),
  ];
}
