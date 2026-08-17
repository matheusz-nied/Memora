# Memora — o que falta para lançar

> Validado em 8/ago/2026 contra a CI e o manifest de release mesclado.
> **O código está pronto.** Tudo abaixo é conta, arte, aparelho ou decisão.
> Ordem de execução.

---

## 0. Limpeza imediata (1 min)

Existe um `.aab` de 62 MB assinado com a **chave de debug**, gerado antes da
trava no `bundleRelease`. É exatamente o arquivo que se sobe por engano:

```bash
rm build/app/outputs/bundle/release/app-release.aab
```

---

## 1. Instalar num aparelho e usar — maior risco do projeto

Os 164 testes rodam na VM do Dart, com fakes no lugar do backend. **Nenhuma
linha jamais executou num celular.**

```bash
flutter build apk --release   # assina com a chave de debug, serve para testar
```

- [ ] Cadastrar chave da DeepSeek e gerar cards a partir de texto
- [ ] Gerar cards de um PDF grande (~100 págs / 20 MB). Travou? Baixe
      `kMaxPdfSizeMb` / `kMaxPdfPages` para 10 / 50 em `app_constants.dart`
- [ ] Exportar backup e achar onde o arquivo foi parar
- [ ] Importar esse mesmo backup (permissão de armazenamento no Android 13+)
- [ ] Ouvir um card com o TTS real do sistema
- [ ] Chave da DeepSeek **inválida** e **sem saldo** — as mensagens existem,
      mas nunca foram vistas por um usuário
- [ ] Tocar no link da política (onboarding e perfil) e no "Reportar conteúdo"
- [ ] Ícone no launcher e splash, em tema claro e escuro

---

## 2. Keystore

Sem ele não existe artefato publicável. O `bundleRelease` falha com instrução.

- [ ] `keytool -genkey -v -keystore ~/memora-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] Copiar `android/key.properties.example` → `android/key.properties` e preencher
- [ ] **Guardar o `.jks` e as senhas fora desta máquina, no mesmo dia.**
      Perder = nunca mais atualizar o app publicado

---

## 3. Corrigir a política de privacidade

A URL já está no ar (HTTP 200 confirmado). Falta o conteúdo estar correto.

- [ ] **Nome do controlador** (seções 1 e 16 de `docs/politica-de-privacidade.md`).
      Está "Matheus Nied", derivado do handle do GitHub — identificação errada
      do controlador é falha formal de LGPD
- [ ] **E-mail de contato.** A política usa `matheusz.nied@gmail.com`; a conta
      é `matheustae@hotmail.com`. Decida qual vale — a Play cobra contato válido

---

## 4. Conta Google Play — US$ 25, pagamento único

- [ ] Criar conta e concluir a **verificação de identidade**
- [ ] ⚠️ **Teste fechado: 12 testers por 14 dias corridos.** Contas pessoais
      criadas depois de nov/2023 precisam disso *antes* de liberar produção.
      **Some ~2 semanas ao cronograma.** Confirme a regra no Console assim que
      a conta existir — depende do tipo e da data da conta

---

## 5. Ficha da loja

- [ ] **Feature graphic 1024×500** — obrigatório. Não existe ainda; as imagens
      em `docs/screenshots/` são da landing page, fora das dimensões da Play
- [ ] Screenshots de telefone **e** tablet, a partir de telas reais
- [ ] Descrição curta, descrição longa, categoria
- [ ] Questionário de **classificação indicativa**
- [ ] **Data Safety**: declaração curta e verdadeira — não coleta nada, sem
      analytics, sem SDK de terceiro que fale com rede. Único destino é a
      DeepSeek, com a chave do próprio usuário, sob ação dele
- [ ] **Notas de revisão**: o revisor não tem chave da DeepSeek, então geração,
      chat e insight ficam inertes. Forneça uma chave de teste ou explique —
      senão vira "funcionalidade quebrada"

Não são necessários: conta de teste (o app não tem login) e termos de uso
próprios (a Play exige só a política).

---

## 6. Envio

- [ ] `flutter build appbundle --release`
- [ ] Subir em **teste interno**, instalar pela loja e repetir os caminhos do
      item 1 — o artefato da loja é reassinado e otimizado, não é byte a byte
      o que você testou
- [ ] Teste fechado (item 4)
- [ ] Promover para produção

---

## Decisão pendente: crash reporting

Sem servidor, um crash no aparelho do usuário é invisível — você descobre por
avaliação de uma estrela.

Não foi instalado de propósito: o SDK muda a postura de privacidade. Hoje a
seção 3.4 da política afirma que a DeepSeek é o **único** destino de rede, e
que sem chave cadastrada o app não faz uma requisição sequer. Isso é verdade
agora e é um argumento forte na ficha da loja. Ligar o Sentry obriga a
reescrever a seção, declarar o SDK no Data Safety e decidir entre envio
automático ou opt-in. O caminho coerente com o app seria **opt-in**.

Não bloqueia o lançamento.

---

## Depois do v1

- **Notificações locais.** Um app de repetição espaçada sem lembrete é
  instalado, usado uma vez e esquecido. Maior retorno da lista
- **Fallback de IA.** DeepSeek fora do ar derruba geração, chat e insight juntos
- Analytics de produto · termos de uso próprios

---

## Já verificado — não refazer

| Item | Estado |
|---|---|
| `format` · `analyze --fatal-infos` · `test` | Verde, 164 testes |
| `targetSdk` 36 · `minSdk` 24 | Atende a Play (≥35) |
| Alinhamento 16 KB nas `.so` | Todas ≥16 KB — atende a regra de nov/2025 |
| Manifest de release | Só `INTERNET` + `ACCESS_NETWORK_STATE`, `allowBackup="false"`, sem `debuggable` |
| Bundle ID · versão | `app.memora.mobile` · `1.0.0+1` |
| Política no ar | HTTP 200 na URL do `legal_text.dart` |
| Aviso de IA + report | Ligado em insight, chat e revisão de cards |
| Ícone e splash | Gerados, Android e iOS, claro e escuro |
| Licenças | Nada a registrar — extrator de PDF é próprio, deps de runtime livres |
| `<queries>` do `url_launcher` | **Não é necessário**: o código chama `launchUrl` direto, sem `canLaunchUrl`. Se alguém adicionar um `canLaunchUrl`, passa a ser |
| R8/minify desligado | APK 73 MB, `.aab` 62 MB. Longe do teto da Play. Não bloqueia |

---

## Comandos

```bash
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test

flutter build apk --release        # teste em aparelho
flutter build appbundle --release  # publicação (exige android/key.properties)
```
