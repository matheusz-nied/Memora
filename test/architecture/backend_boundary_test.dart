import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Trava a regra 10 do AGENTS.md: só o adaptador conhece o Supabase.
///
/// A regra existia apenas escrita, e regra escrita apodrece — um import
/// acidental numa tela passa despercebido até o dia em que trocar de backend
/// deixa de ser trocar um provider. Este teste roda no `flutter test`, então
/// vale localmente e na CI sem configuração extra.
void main() {
  /// Único lugar que pode falar com o SDK do Supabase.
  const adapterDirectory = 'lib/core/backend/supabase/';

  /// Quem pode escolher a implementação ativa: o bootstrap e o provider.
  /// Qualquer outro arquivo alcançando o adaptador significa que a troca de
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

  test('lib/ tem arquivos para inspecionar', () {
    // Guarda contra o teste passar por não ter lido nada.
    expect(dartFiles.length, greaterThan(50));
  });

  test('somente o adaptador importa o SDK do Supabase', () {
    final offenders = <String>[];

    for (final file in dartFiles) {
      final path = normalize(file.path);
      if (path.startsWith(adapterDirectory)) {
        continue;
      }
      if (file.readAsStringSync().contains('package:supabase_flutter')) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Estes arquivos importam supabase_flutter fora de '
          '$adapterDirectory:\n  ${offenders.join('\n  ')}\n\n'
          'Telas, widgets e repositories de feature devem depender dos '
          'contratos em lib/core/backend/contracts/. Ver AGENTS.md, regra 10.',
    );
  });

  test('somente o bootstrap e o provider alcançam o adaptador', () {
    final offenders = <String>[];

    for (final file in dartFiles) {
      final path = normalize(file.path);
      if (path.startsWith(adapterDirectory) ||
          allowedAdapterConsumers.contains(path)) {
        continue;
      }

      final source = file.readAsStringSync();
      final importsAdapter =
          source.contains('backend/supabase/') ||
          source.contains("import 'supabase/");

      if (importsAdapter) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Estes arquivos importam a implementação Supabase diretamente:\n'
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
      final source = file.readAsStringSync();
      expect(
        source.contains('supabase'),
        isFalse,
        reason:
            '${normalize(file.path)} menciona supabase. Contratos são '
            'neutros: é o que permite escrever um CustomBackendClient sem '
            'tocar em feature nenhuma.',
      );
    }
  });
}
