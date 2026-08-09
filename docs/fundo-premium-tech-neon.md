# Fundo premium tech-neon no Flutter

Este documento descreve somente o fundo criado para o dashboard do Memora. O
efeito combina um gradiente azul-marinho vertical com halos radiais azuis e
violetas. Os halos ficam atrás do conteúdo e não capturam gestos.

## Resultado visual

O fundo é formado por quatro camadas, nesta ordem:

1. gradiente vertical que começa em azul-marinho profundo;
2. halo azul no canto superior direito;
3. halo violeta parcialmente fora da lateral esquerda;
4. conteúdo real da tela.

O segredo da profundidade está em deixar os halos parcialmente fora da área
visível e fazê-los desaparecer até a transparência. Isso cria reflexos de luz
ambiente sem parecer uma coleção de círculos desenhados sobre a interface.

## Tokens do design system

Adicione as cores em `AppColors`, dentro de `lib/core/theme/app_colors.dart`:

```dart
static const Color neonBlue = Color(0xFF3182FF);
static const Color neonViolet = Color(0xFF7C5CFF);
static const Color dashboardNavy = Color(0xFF08111F);
static const Color dashboardNavySoft = Color(0xFF0D1A2C);
```

Adicione o tamanho do halo em `AppDimensions`, dentro de
`lib/core/theme/app_dimensions.dart`:

```dart
static const double ambientGlowSize = 280.0;
```

Esses valores ficam no design system para evitar cores e medidas soltas dentro
dos widgets.

## Widget do fundo

Crie `dashboard_backdrop.dart` na pasta de widgets do dashboard:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({
    super.key,
    required this.child,
    required this.isDark,
  });

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        AppColors.dashboardNavy,
                        AppColors.dashboardNavySoft,
                        AppColors.backgroundDark,
                      ]
                    : const [
                        AppColors.background,
                        AppColors.primaryLight,
                        AppColors.background,
                      ],
              ),
            ),
          ),
        ),
        const Positioned(
          top: -AppDimensions.huge,
          right: -AppDimensions.huge,
          child: _AmbientGlow(color: AppColors.neonBlue),
        ),
        const Positioned(
          top: AppDimensions.ambientGlowSize,
          left: -AppDimensions.ambientGlowSize / 2,
          child: _AmbientGlow(color: AppColors.neonViolet),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: AppDimensions.ambientGlowSize,
        height: AppDimensions.ambientGlowSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Aplicação no dashboard

Envolva o conteúdo rolável com `DashboardBackdrop`. O `SingleChildScrollView`
deve ficar dentro do fundo para que os halos permaneçam parados enquanto o
conteúdo rola:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return DashboardBackdrop(
    isDark: Theme.of(context).brightness == Brightness.dark,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Responsive.constrainedContent(
        child: Padding(
          padding: Responsive.contentPadding(context),
          child: const DashboardContent(),
        ),
      ),
    ),
  );
}
```

Se o fundo precisar rolar junto com o conteúdo, coloque o
`DashboardBackdrop` dentro do `SingleChildScrollView`. Para o Memora, mantê-lo
fora da rolagem produz uma sensação mais estável e premium.

## Por que a implementação funciona

- `Positioned.fill` garante que o gradiente ocupe toda a área disponível.
- `Stack` permite posicionar as luzes sem afetar o layout do conteúdo.
- `RadialGradient` elimina bordas duras nos halos.
- `IgnorePointer` impede que uma camada decorativa bloqueie botões ou gestos.
- Posições negativas cortam parte dos halos e simulam uma fonte de luz externa.
- A última camada do `Stack` é o conteúdo, portanto textos e controles continuam
  nítidos e acessíveis.

## Ajustes seguros

Para um efeito mais discreto, reduza apenas a opacidade inicial do
`RadialGradient`. Para aumentar a presença, prefira aumentar
`ambientGlowSize`; aumentar demais a opacidade tende a reduzir o contraste dos
textos.

Em telas maiores, é possível calcular um halo maior com base no breakpoint, mas
o conteúdo deve continuar limitado por `Responsive.constrainedContent` e
`kContentMaxWidth`. Evite aplicar `BackdropFilter` no fundo inteiro: o gradiente
já é suave, e o blur em tela cheia aumenta o custo de renderização sem benefício
visual relevante.

## Checklist de validação

- conferir os temas claro e escuro;
- testar larguras mobile, tablet e desktop;
- verificar que o scroll continua fluido;
- confirmar que os halos não recebem eventos de toque;
- rodar `flutter analyze` e `flutter test`.

