# Ícones do app

Coloque aqui, antes de publicar:

- `icon.png` — 1024×1024, sem transparência, é o que vai para a App Store e
  para as densidades do Android.
- `icon_foreground.png` — 1024×1024 **com transparência** e com margem
  generosa: é a camada da frente do ícone adaptativo do Android, e o sistema a
  recorta em círculo, quadrado ou gota dependendo do launcher. Arte encostada
  na borda é cortada em algum desses formatos.

Depois:

    dart run flutter_launcher_icons

O comando reescreve `android/app/src/main/res/mipmap-*` e o
`AppIcon.appiconset` do iOS. Enquanto estes arquivos não existirem, o app
continua com o ícone padrão do Flutter — que é motivo de reprovação na revisão
das lojas.
