/// Em qual modo este binário foi compilado.
enum AppMode {
  /// Backend Supabase: contas, sync entre dispositivos, quota de IA e a chave
  /// da DeepSeek guardada no servidor.
  cloud,

  /// Sem nuvem nenhuma. Identidade local, dados só no Drift do aparelho e a
  /// chave da DeepSeek cadastrada pelo próprio usuário.
  local,
}

/// Modo ativo. **Troque esta linha e recompile.**
///
/// É `const` de propósito: as comparações somem em tempo de compilação, então
/// o build local não carrega o SDK do Supabase e o build de nuvem não carrega
/// o adaptador local. Uma flag de runtime deixaria os dois no binário.
///
/// Edite **apenas esta linha**. Um `sed` sobre `AppMode.cloud` casa também com
/// a definição de [kIsCloudMode] logo abaixo e deixa os dois atalhos com o
/// mesmo valor — um estado que compila, passa no analisador e mostra a UI
/// errada em silêncio.
const AppMode kAppMode = AppMode.local;

/// Atalhos para quem só precisa perguntar pelo modo.
const bool kIsCloudMode = kAppMode == AppMode.cloud;
const bool kIsLocalMode = kAppMode == AppMode.local;
