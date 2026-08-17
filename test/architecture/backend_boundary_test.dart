import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Trava as regras de dependência do AGENTS.md.
///
/// Regra escrita apodrece: um import acidental numa tela passa despercebido até
/// o dia em que trocar de provedor de IA deixa de ser trocar um provider. Este
/// teste roda no `flutter test`, então vale localmente e na CI sem configuração
/// extra.
void main() {
  /// O único lugar que pode conhecer um serviço externo concreto.
  const adapterDirectory = 'lib/core/backend/local/';

  /// Quem pode escolher a implementação ativa. Qualquer outro arquivo
  /// alcançando um adaptador significa que a troca deixou de ser um ponto só.
  const allowedAdapterConsumers = {'lib/core/backend/gateway_providers.dart'};

  /// SDKs de nuvem que o app não usa mais e não deve voltar a usar sem uma
  /// decisão explícita. O app é local: sem contas, sem sync, sem servidor.
  const forbiddenPackages = [
    'supabase_flutter',
    'supabase',
    'flutter_dotenv',
    'firebase',
    'cloud_firestore',
  ];

  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  String normalize(String path) => path.replaceAll(r'\', '/');

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

  test('nenhum SDK de nuvem voltou para o projeto', () {
    final offenders = <String>[];

    for (final file in dartFiles) {
      final imports = importsOf(file);
      for (final package in forbiddenPackages) {
        if (imports.any((target) => target.startsWith('package:$package/'))) {
          offenders.add('${normalize(file.path)} -> $package');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Estes arquivos importam um SDK de nuvem:\n  '
          '${offenders.join('\n  ')}\n\n'
          'O Memora é local: decks, cards e histórico ficam no aparelho, e a '
          'única chamada que sai é para a DeepSeek, com a chave do usuário. '
          'Voltar a depender de um backend é decisão de produto, não '
          'consequência de um import.',
    );
  });

  test('somente o provider alcança os adaptadores', () {
    final offenders = <String>[];

    for (final file in dartFiles) {
      final path = normalize(file.path);
      if (path.startsWith(adapterDirectory) ||
          allowedAdapterConsumers.contains(path)) {
        continue;
      }

      if (importsOf(file).any((target) => target.contains('backend/local/'))) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Estes arquivos importam uma implementação diretamente:\n'
          '  ${offenders.join('\n  ')}\n\n'
          'A escolha da implementação ativa é de gateway_providers.dart. '
          'Telas e repositories dependem dos contratos em '
          'lib/core/backend/contracts/.',
    );
  });

  test('os contratos não conhecem nenhum fornecedor', () {
    final contractFiles = dartFiles.where(
      (file) => normalize(file.path).startsWith('lib/core/backend/contracts/'),
    );

    expect(contractFiles, isNotEmpty);

    for (final file in contractFiles) {
      final source = file.readAsStringSync().toLowerCase();
      for (final vendor in const ['supabase', 'deepseek', 'syncfusion']) {
        expect(
          source.contains(vendor),
          isFalse,
          reason:
              '${normalize(file.path)} menciona $vendor. Contratos são '
              'neutros: é o que permite trocar o provedor de IA — ou o '
              'extrator de PDF — sem tocar em feature nenhuma.',
        );
      }
    }
  });

  test('core não depende de features', () {
    // `core/` é importado por toda feature. Se ele puder importar `features/`,
    // um provider de tela vira dependência de infraestrutura e o grafo passa a
    // ter ciclo.
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
