class StatsText {
  const StatsText._();

  static const String title = 'Seu progresso';
  static const String streak = 'Sequência';
  static const String accuracy = 'Acertos';
  static const String reviewsToday = 'Hoje';
  static const String windowTotal = 'Em 30 dias';
  static const String windowStart = 'há 30 dias';
  static const String upcoming = 'Próximos 7 dias';

  static const String emptyTitle = 'Seu progresso aparece aqui';
  static const String emptyMessage =
      'Estude alguns cards e esta área passa a mostrar sequência, acertos e '
      'o que vence nos próximos dias.';

  static String days(int value) => value == 1 ? '1 dia' : '$value dias';
  static String cards(int value) => value == 1 ? '1 card' : '$value cards';
  static String reviews(int value) =>
      value == 1 ? '1 revisão' : '$value revisões';
  static String percent(double value) => '${(value * 100).round()}%';

  /// Abreviações dos dias da semana, indexadas por `DateTime.weekday - 1`.
  static const List<String> weekdayShort = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];
}
