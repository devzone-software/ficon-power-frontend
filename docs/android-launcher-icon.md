# Icono Android de FICON Power

Se sustituyó el icono Flutter por una F con la paleta existente:
fondo `#001020`, letra `#1080C0` y acento `#20E0F0`.

Fuente vectorial: `resources/mobile/icon/ficon-f.svg`.
Los PNG de `mipmap-mdpi` a `mipmap-xxxhdpi` tienen 48, 72, 96, 144 y 192 px.
Android 8+ usa icono adaptativo; Android 13+ incluye una capa monocroma para
iconos temáticos. El manifiesto mantiene `@mipmap/ic_launcher`.

Para regenerar cada PNG, usar ImageMagick con el tamaño correspondiente:

```bash
magick -background none resources/mobile/icon/ficon-f.svg -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

Es necesario reconstruir e instalar la APK para ver el cambio. La versión de
Windows conserva su icono propio. Esta modificación no cambia el icono pequeño
de notificaciones Android.
