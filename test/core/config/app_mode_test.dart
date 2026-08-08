import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/config/app_mode.dart';

/// Guarda contra um erro que compila e passa no analisador: os dois atalhos
/// apontando para o mesmo modo.
///
/// Acontece ao trocar o modo com um "localizar e substituir" sobre
/// `AppMode.cloud`, que casa tanto com [kAppMode] quanto com a definição de
/// [kIsCloudMode]. O resultado é um build que se diz local e de nuvem ao mesmo
/// tempo — mostra a UI errada sem nenhum erro.
void main() {
  test('os atalhos de modo são mutuamente exclusivos', () {
    expect(
      kIsCloudMode && kIsLocalMode,
      isFalse,
      reason: 'kIsCloudMode e kIsLocalMode não podem ser verdadeiros juntos.',
    );
    expect(
      kIsCloudMode || kIsLocalMode,
      isTrue,
      reason: 'Um dos dois precisa ser verdadeiro.',
    );
  });

  test('os atalhos concordam com o modo ativo', () {
    expect(kIsCloudMode, kAppMode == AppMode.cloud);
    expect(kIsLocalMode, kAppMode == AppMode.local);
  });
}
