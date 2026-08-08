import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Trava a regra 10 do AGENTS.md: só o adaptador conhece o backend concreto.
///
/// A regra existia apenas escrita, e regra escrita apodrece — um import
/// acidental numa tela passa despercebido até o dia em que trocar de backend
/// deixa de ser trocar um provider. Este teste roda no `flutter test`, então
/// vale localmente e na CI sem configuração extra.
void main() {
  /// Os únicos lugares que podem conhecer um backend concreto. Cada modo de
  /// build (ver `lib/core/config/app_mode.dart`) tem o seu.
  const adapterDirectories = [
    'lib/core/backend/supabase/',
    'lib/core/backend/local/',
  ];

  /// Quem pode escolher a implementação ativa: o bootstrap e o provider.
  /// Qualquer outro arquivo alcançando um adaptador significa que a troca de
  /// backend deixou de ser um ponto só.
  const allowedAdapterConsumers = {
    'lib/main.dart',
    'lib/core/backend/backend_provider.dart',
  };

  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  String normalize(String path) => path.replaceAll(r'\', '/');

  bool isInsideAdapter(String path) => adapterDirectories.any(path.startsWith);

  /// Os alvos de `import`/`export` do arquivo.
  ///
  /// Ler só as diretivas, e não o texto inteiro, é o que evita um comentário
  /// que *fala* sobre a fronteira ser confundido com uma violação dela.
  final importPattern = RegExp(
    '''^\\s*(?:import|export)\\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  List<String> importsOf(File file) => importPattern
      .allMatches(file.readAsStringSync())
      .map((match) => match.group(1)!)
      .toList();

  test('lib/ tem arquivos para inspecionar', () {
    // Guarda contra o teste passar por não ter lido nada.
    expect(dartFiles.length, greaterThan(50));
  });

  test('somente o adaptador importa o SDK do Supabase', () {
    final offenders = <String>[];

    for (final file in dartFiles) {
      final path = normalize(file.path);
      if (isInsideAdapter(path)) {
        continue;
      }
      if (importsOf(
        file,
      ).any((target) => target.contains('supabase_flutter'))) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Estes arquivos importam supabase_flutter fora de '
          '${adapterDirectories.first}:\n  ${offenders.join('\n  ')}\n\n'
          'Telas, widgets e repositories de feature devem depender dos '
          'contratos em lib/core/backend/contracts/. Ver AGENTS.md, regra 10.',
    );
  });

  test('somente o bootstrap e o provider alcançam os adaptadores', () {
    final offenders = <String>[];

    for (final file in dartFiles) {
      final path = normalize(file.path);
      if (isInsideAdapter(path) || allowedAdapterConsumers.contains(path)) {
        continue;
      }

      final importsAdapter = importsOf(file).any(
        (target) =>
            target.contains('backend/supabase/') ||
            target.contains('backend/local/') ||
            target.startsWith('supabase/') ||
            target.startsWith('local/'),
      );

      if (importsAdapter) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Estes arquivos importam uma implementação de backend diretamente:\n'
          '  ${offenders.join('\n  ')}\n\n'
          'A escolha da implementação ativa é de backendClientProvider. '
          'Qualquer outro ponto de acoplamento transforma a migração de '
          'backend em refactor.',
    );
  });

  test('os contratos não conhecem nenhuma infraestrutura remota', () {
    final contractFiles = dartFiles.where(
      (file) => normalize(file.path).startsWith('lib/core/backend/contracts/'),
    );

    expect(contractFiles, isNotEmpty);

    for (final file in contractFiles) {
      final source = file.readAsStringSync().toLowerCase();
      for (final vendor in const ['supabase', 'deepseek']) {
        expect(
          source.contains(vendor),
          isFalse,
          reason:
              '${normalize(file.path)} menciona $vendor. Contratos são '
              'neutros: é o que permite escrever um CustomBackendClient sem '
              'tocar em feature nenhuma.',
        );
      }
    }
  });

  test('core não depende de features', () {
    // `core/` é importado pelos dois adaptadores e por toda feature. Se ele
    // puder importar `features/`, um provider de tela vira dependência de
    // infraestrutura e o grafo passa a ter ciclo.
    final offenders = <String>[];

    for (final file in dartFiles) {
      final path = normalize(file.path);
      if (!path.startsWith('lib/core/')) {
        continue;
      }
      if (importsOf(file).any((target) => target.contains('features/'))) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Estes arquivos de core importam de features:\n'
          '  ${offenders.join('\n  ')}\n\n'
          'Mova o que os dois lados precisam para core/ — foi o que aconteceu '
          'com agent_templates.dart e com o sharedPreferencesProvider.',
    );
  });
}
