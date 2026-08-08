---
layout: default
title: Política de Privacidade
---

# Política de Privacidade — Memora

**Última atualização:** 8 de agosto de 2026
**Versão do app a que se aplica:** 1.0.0 (modo local)

---

## Resumo

O Memora não tem servidor, não tem conta de usuário e não coleta seus dados.
Seus decks, cards e histórico de estudo ficam **apenas no seu aparelho**.

A única exceção é a inteligência artificial: quando você pede para gerar cards,
conversar com o agente ou ver um insight, o texto envolvido nessa operação é
enviado para a **DeepSeek**, usando a chave de API que **você** cadastrou. Nós
não intermediamos, não recebemos cópia e não vemos o conteúdo.

O resto deste documento detalha exatamente o que sai do aparelho, quando e para
onde.

---

## 1. Quem é o controlador dos dados

**Matheus Nied** — pessoa física, desenvolvedor independente
GitHub: [@matheusz-nied](https://github.com/matheusz-nied)
Contato para assuntos de privacidade: **matheusz.nied@gmail.com**

Para os fins da Lei Geral de Proteção de Dados (Lei 13.709/2018), este é o
controlador. Como o aplicativo não possui servidores nem banco de dados
remoto, o tratamento realizado pelo controlador é mínimo — está descrito na
seção 4.

O Memora é um projeto de código aberto. O código-fonte completo está em
<https://github.com/matheusz-nied/Memora> e pode ser auditado por qualquer
pessoa: tudo o que esta política afirma sobre o que o aplicativo faz ou deixa
de fazer é verificável linha a linha, sem depender da nossa palavra.

---

## 2. O que fica só no seu aparelho

Tudo isto é gravado no armazenamento privado do aplicativo e **nunca é
transmitido para nós**:

- Seus decks, cards, frentes, versos e insights salvos
- Todo o seu histórico de estudo: cada revisão, a nota que você deu, os
  intervalos calculados pela repetição espaçada
- As configurações do agente de IA de cada deck
- O histórico das conversas com o agente
- A chave de API da DeepSeek que você cadastrou
- Um identificador aleatório gerado no primeiro uso, que serve apenas para
  organizar os dados dentro do próprio aparelho. Ele não é enviado a lugar
  nenhum e não permite identificar você.

Não há login, não há cadastro, não há e-mail, não há telemetria, não há
analytics e não há publicidade. Nós não temos como saber que você instalou o
aplicativo, quantas vezes o abriu ou o que estudou.

O backup automático do sistema operacional está **desativado** no Android
(`allowBackup="false"`), justamente para que esses dados — inclusive a sua
chave de API — não sejam copiados para a nuvem do fabricante sem você pedir.

---

## 3. O que sai do seu aparelho

### 3.1 Conteúdo enviado à DeepSeek

A geração de cards, o chat com o agente e os insights são processados pela
**DeepSeek** (DeepSeek AI, com servidores na República Popular da China).

O envio acontece **apenas quando você aciona uma dessas funções**, e apenas com
o conteúdo necessário para ela:

| Função | O que é enviado |
|---|---|
| Gerar cards a partir de texto | O texto que você colou, o título/descrição do deck e as configurações do agente |
| Gerar cards a partir de PDF | O **texto extraído** do PDF (o arquivo em si nunca é enviado), mais os mesmos dados de deck acima |
| Conversar com o agente | Sua mensagem, o histórico recente da conversa, os dados do deck e até 20 cards recentes desse deck |
| Insight de um card | A frente e o verso daquele card e os dados do deck |

A requisição vai **direto do seu aparelho para a DeepSeek**, autenticada com a
sua chave. Não passa por nenhum servidor nosso, porque não existe servidor
nosso.

O uso que a DeepSeek faz desse conteúdo é regido pela política de privacidade e
pelos termos **da conta que você criou lá**, não por este documento. Leia-os:
<https://www.deepseek.com/privacy>. Em particular, verifique se o seu plano
permite ou não que o conteúdo enviado seja usado para treinar modelos.

**Não envie ao Memora conteúdo que você não pode enviar à DeepSeek** — dados de
saúde, dados de terceiros, material sigiloso profissional ou qualquer
informação sob obrigação de confidencialidade.

### 3.2 Fontes tipográficas (Google)

Na primeira execução, o aplicativo baixa a fonte *Inter* dos servidores do
Google (`fonts.gstatic.com`) e a guarda em cache no aparelho. Essa requisição
expõe ao Google o seu endereço IP e informações básicas do dispositivo, como
qualquer acesso a um site. Nenhum conteúdo seu é enviado nessa requisição.

> *[REMOVER ESTA SEÇÃO se a fonte for empacotada no aplicativo — ver
> `TODO_IMPORTANTE.md`. Sem a requisição, ela deixa de ser verdadeira.]*

### 3.3 Leitura em voz alta

A função de ouvir o card usa o mecanismo de síntese de voz **do seu próprio
sistema operacional**. O texto do card é entregue a esse mecanismo. O que ele
faz com o texto — processar localmente ou enviar aos servidores do fabricante —
depende do mecanismo que você tem instalado e configurado, e é regido pela
política de privacidade dele (Google, Apple, Samsung ou outro).

### 3.4 Verificação de conectividade

O aplicativo consulta o sistema operacional para saber se há conexão. É uma
consulta local ao aparelho, sem requisição de rede e sem envio de dados.

---

## 4. Dados que nós tratamos

Praticamente nenhum. As únicas hipóteses:

- **Se você nos escrever** (suporte, dúvida, exercício de direitos), passamos a
  tratar o seu e-mail e o conteúdo da mensagem, pelo tempo necessário para
  responder e cumprir prazos legais.
- **Dados agregados das lojas.** Google Play e App Store nos fornecem números
  agregados de instalação, avaliações e relatórios de falha. Esses dados vêm
  das lojas, seguem as políticas delas e não identificam você individualmente.

---

## 5. Sua chave de API da DeepSeek

A chave é armazenada no armazenamento privado do aplicativo, em texto simples.
Isso significa que ela está protegida do acesso de outros aplicativos pelo
isolamento do sistema operacional, mas **não está criptografada**: alguém com
acesso físico e privilégio de root/jailbreak no aparelho poderia lê-la.

A chave nunca é enviada a nós. Ela viaja apenas do seu aparelho para a
DeepSeek, por HTTPS, para autenticar as suas próprias requisições. Todo o
consumo é cobrado na sua conta DeepSeek, e você pode revogar a chave a qualquer
momento no painel deles.

Você pode remover a chave do aplicativo em **Perfil → Chave da IA → Remover**.

---

## 6. Arquivos PDF

O PDF que você seleciona é lido **no próprio aparelho** para extrair o texto. O
arquivo não é enviado a nós nem à DeepSeek, e não é copiado para dentro do
aplicativo — apenas o texto extraído é usado, e só ele segue para a geração de
cards conforme a seção 3.1.

---

## 7. Backup e portabilidade

A tela de **Backup** exporta todo o seu conteúdo em um arquivo `.json` que
**você** escolhe onde salvar. O arquivo não é criptografado e não é enviado a
lugar nenhum: o destino é você quem define. Guarde-o com o mesmo cuidado que
daria ao conteúdo original, especialmente se salvá-lo em um serviço de nuvem.

Esse mesmo arquivo atende ao seu direito de portabilidade (LGPD, art. 18, V):
ele contém seus dados em formato aberto e legível por máquina, sem que você
precise pedir nada a ninguém.

---

## 8. Base legal do tratamento

| Tratamento | Base legal (LGPD, art. 7º) |
|---|---|
| Armazenamento local dos seus dados no aparelho | Execução do próprio aplicativo a seu pedido (inciso V) |
| Envio de conteúdo à DeepSeek | Sua ação deliberada ao acionar a função, informada por esta política (incisos V e IX) |
| Resposta a contatos de suporte | Legítimo interesse e cumprimento de obrigação legal (incisos IX e II) |

---

## 9. Transferência internacional

Ao usar as funções de IA, o conteúdo descrito na seção 3.1 é transferido para
servidores da DeepSeek **fora do Brasil e fora da União Europeia**, na China,
país que não consta da lista de países com grau de proteção adequado reconhecido
pela ANPD.

Essa transferência ocorre porque é **indispensável para executar a função que
você solicitou** (LGPD, art. 33, inciso VIII) e acontece sob a conta e a chave
que você mesmo criou junto à DeepSeek. As funções de IA são opcionais: o
aplicativo funciona integralmente sem elas — você pode criar cards à mão e
estudar sem que nada saia do aparelho.

Se você está na União Europeia, o mesmo raciocínio se aplica sob o art. 49(1)(b)
do GDPR (transferência necessária à execução de contrato a seu pedido).

---

## 10. Seus direitos

A LGPD (art. 18) garante a você confirmação de tratamento, acesso, correção,
anonimização, portabilidade, eliminação, informação sobre compartilhamento e
revogação de consentimento. O GDPR garante direitos equivalentes.

No Memora, a maior parte deles você exerce sozinho, sem pedir autorização a
ninguém, porque os dados estão com você:

- **Acesso e portabilidade:** Perfil → Backup → Exportar
- **Correção:** edite o deck ou o card diretamente
- **Eliminação:** apague decks e cards no aplicativo, ou desinstale-o — remover
  o aplicativo apaga todo o banco de dados local, de forma irreversível
- **Revogação do envio à IA:** Perfil → Chave da IA → Remover

Para os dados da seção 4, ou para qualquer dúvida sobre esta política, escreva
para **matheusz.nied@gmail.com**. Respondemos em até 15 dias.

Para dados que já estejam com a DeepSeek, o pedido precisa ser feito
diretamente a eles — nós não temos acesso nem controle sobre esses registros.

Você também pode reclamar à **Autoridade Nacional de Proteção de Dados (ANPD)**:
<https://www.gov.br/anpd>.

---

## 11. Retenção

Seus dados permanecem no aparelho pelo tempo que você quiser, e são apagados
quando você os apaga ou desinstala o aplicativo. Não há retenção do nosso lado
porque não há cópia do nosso lado.

Mensagens de suporte são mantidas pelo tempo necessário para responder e para
cumprir prazos legais aplicáveis.

---

## 12. Crianças e adolescentes

O Memora não é direcionado a menores de 13 anos. Como não coletamos dados, não
realizamos verificação de idade. Se você é responsável por um adolescente que
usa o aplicativo, atente-se especialmente à seção 3.1: o conteúdo que ele
enviar à IA sai do aparelho.

---

## 13. Segurança

O aplicativo se apoia no isolamento de armazenamento do sistema operacional,
usa HTTPS em todas as requisições e mantém desativado o backup automático da
plataforma. Não podemos, contudo, proteger dados contra alguém com acesso
físico e privilegiado ao seu aparelho — mantenha a tela bloqueada e o sistema
atualizado.

---

## 14. Conteúdo gerado por inteligência artificial

Os cards, insights e respostas do agente são **gerados automaticamente por um
modelo de linguagem e podem conter erros**. Não são conselho médico, jurídico,
financeiro nem profissional de qualquer natureza. Confira o conteúdo antes de
estudá-lo como verdade — especialmente material técnico, clínico ou legal.

---

## 15. Alterações nesta política

Se esta política mudar de forma relevante — por exemplo, se o aplicativo passar
a ter contas, sincronização em nuvem ou relatório de falhas — a nova versão
será publicada nesta mesma URL com a data de atualização alterada, e o
aplicativo avisará você antes que a mudança entre em vigor.

---

## 16. Contato

**Matheus Nied** — **matheusz.nied@gmail.com**

Dúvidas técnicas, relatos de erro e sugestões também são bem-vindos como
issues públicas em <https://github.com/matheusz-nied/Memora/issues>.
