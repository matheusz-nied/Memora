class BackupText {
  const BackupText._();

  static const String title = 'Backup dos seus dados';
  static const String subtitle =
      'Seus decks, cards e histórico de estudo ficam apenas neste aparelho. '
      'Exporte um arquivo de vez em quando: é o que permite recuperar tudo se '
      'você trocar de celular ou reinstalar o app.';

  static const String profileHint =
      'Exporte ou restaure seus decks, cards e histórico.';

  static const String exportTitle = 'Exportar';
  static const String exportDescription =
      'Gera um arquivo .json com tudo o que você tem hoje.';
  static const String exportAction = 'Exportar backup';
  static const String exportCanceled = 'Exportação cancelada.';
  static const String exportFailed =
      'Não foi possível exportar o backup. Verifique a permissão de acesso aos '
      'arquivos e tente de novo.';
  static String exportSuccess(String path) => 'Backup salvo em $path';

  static const String importTitle = 'Importar';
  static const String importDescription =
      'Lê um arquivo exportado antes. Nada é apagado: o que já existe aqui só '
      'é substituído se a versão do arquivo for mais recente.';
  static const String importAction = 'Importar backup';
  static const String importCanceled = 'Importação cancelada.';
  static const String importNothing =
      'Nada novo para importar: seus dados já estão em dia.';
  static const String importUnreadable =
      'Não foi possível ler o arquivo selecionado.';
  static const String importFailed =
      'Não foi possível importar o backup. Verifique a permissão de acesso aos '
      'arquivos e tente de novo.';

  static String importSuccess({
    required int decks,
    required int cards,
    required int reviews,
  }) {
    return 'Importados: $decks decks, $cards cards e $reviews revisões.';
  }

  static String fileName(DateTime moment) {
    final date = moment.toIso8601String().split('T').first;
    return 'memora-backup-$date.json';
  }
}
