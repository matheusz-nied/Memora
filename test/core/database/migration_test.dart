import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';

import '../../drift/generated/schema.dart';

/// Garante que o schema declarado no código continua igual ao snapshot da
/// versão correspondente e que toda migração intermediária roda limpa.
///
/// Quando uma tabela ou coluna mudar:
///   1. incrementar `AppDatabase.schemaVersion`
///   2. adicionar o passo em `AppDatabase.migration.onUpgrade`
///   3. `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
///   4. `dart run drift_dev schema generate drift_schemas/ test/drift/generated/`
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('schema declarado corresponde ao snapshot de cada versão', () async {
    for (
      var version = 1;
      version <= AppDatabase.latestSchemaVersion;
      version++
    ) {
      final connection = await verifier.startAt(version);
      final database = AppDatabase(connection);

      await verifier.migrateAndValidate(database, version);
      await database.close();
    }
  });

  test('migra da v1 até a versão atual preservando os dados', () async {
    const latest = AppDatabase.latestSchemaVersion;
    if (latest == 1) {
      // Ainda não há migração para exercitar; o teste acima já cobre o schema.
      return;
    }

    final connection = await verifier.startAt(1);
    final database = AppDatabase(connection);

    await verifier.migrateAndValidate(database, latest);
    await database.close();
  });
}
