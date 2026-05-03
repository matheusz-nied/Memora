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
  static const String start = 'Começar';

  static const List<OnboardingPageModel> pages = [
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
