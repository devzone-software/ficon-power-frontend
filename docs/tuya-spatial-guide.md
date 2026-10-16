# Guía móvil de Smart Industry (Tuya Spatial)

La guía **Dispositivos > Cómo agregar un medidor** sigue el procedimiento del
informe técnico `Acta_e_Informe_Tecnico_Tuya_Spatial_Usuarios_y_Medidores.pdf`.

## Flujo presentado

Antes de iniciar se verifica que exista una cuenta autorizada sobre el activo,
que el `WIFI Energy Meter` esté energizado y en modo de emparejamiento, y que se
disponga de una red Wi-Fi y su contraseña correcta.

1. Descargar [Smart Industry 1.23.0 internacional](https://images.tuyacn.com/smart/app/package/1283285297/1785838705-tyindustry1.23.0r46_huawei_international.apk)
   desde el servidor de Tuya. Es un APK único; Android puede solicitar permiso
   para instalar desde el navegador. La guía ya no dirige a Google Play.
2. Abrir Smart Industry y tocar `SCAN` para escanear el QR actualizado de
   Timax-Energy-Detector, proporcionado el 16 de octubre de 2026. La guía presenta
   solamente el código limpio para facilitar su lectura, sin repetir la captura
   de la figura 5. Este QR vincula la aplicación con el proyecto cloud; cuando
   se manejen tenants debe usarse el QR del tenant correcto.
3. Copiar la cuenta y la contraseña creadas por el administrador e iniciar
   sesión como muestra la figura 6. El usuario solo accede a los activos que le
   fueron asignados. La contraseña se representa únicamente con puntos y no
   dispone de una acción para revelarla.
4. Crear o seleccionar el espacio de la sede siguiendo la secuencia completa de
   la figura 7 y el formato `nombre_ubicación`.
5. Abrir `Devices` y tocar el botón azul `+` mostrado en la figura 8.
6. Poner el equipo en modo de emparejamiento y seleccionar `Agregar` cuando
   aparezca `WIFI Energy Meter`, como muestra la figura 9.
7. Seleccionar Wi-Fi, escribir su contraseña y pulsar `Siguiente` según los
   indicadores 3, 4 y 5 de la figura 10.
8. Mantener energizado el equipo durante el progreso de la figura 11.
9. Esperar `Added successfully` y pulsar `Finalizado`, indicador 7 de la figura
   12.
10. Comprobar el medidor en la lista final de la figura 13 y actualizar FICON.

El registro en Tuya Spatial no inserta directamente el dispositivo en la base de
datos de FICON. El backend lo incorpora al consultar el catálogo de Tuya durante
su arranque o al recibir el primer evento de conectividad del nuevo medidor. Por
eso la aparición puede no ser inmediata si el backend ya estaba ejecutándose y
el dispositivo todavía no generó un evento.

Las figuras 6 a 13 se extrajeron del informe, se optimizaron como WebP y se
incluyen en `assets/guides/tuya_spatial/`. Dentro de la guía pueden tocarse para
abrir una vista ampliable.

## Configuración privada

La cuenta y contraseña reales no se guardan en Git. Se configuran en
`.env.mobile`, archivo ignorado por el repositorio. El QR actualizado del
proyecto se incluye como valor predeterminado en `AppConfig`; un valor no vacío
de `TUYA_SPATIAL_PROJECT_QR_DATA` lo reemplaza para usar otro proyecto. Un valor
vacío conserva el QR predeterminado:

```env
TUYA_SPATIAL_PROJECT_QR_DATA='URL_O_CONTENIDO_DEL_QR'
TUYA_SPATIAL_ACCOUNT='CUENTA_AUTORIZADA'
TUYA_SPATIAL_PASSWORD='CONTRASEÑA_AUTORIZADA'
```

Si la configuración local todavía contiene el QR antiguo, reemplazarlo por el
nuevo o dejar vacía `TUYA_SPATIAL_PROJECT_QR_DATA`. Reconstruir la APK y la web
para que los cambios lleguen a los usuarios. El QR configura el proyecto; no
reemplaza el usuario, contraseña ni la autorización sobre los activos.

Las capturas históricas de los demás pasos pueden mostrar el nombre Tuya
Spatial; la descarga actual utiliza Smart Industry. El APK internacional se
descargó y verificó el 14 de octubre de 2026. El acceso al proyecto debe
comprobarse con una cuenta autorizada.

El archivo versionado `.env.mobile.example` conserva estas variables vacías.
Antes de compilar se carga la configuración:

```bash
set -a
source .env.mobile
set +a
bash scripts/build-mobile-apk.sh
```

El script las inyecta mediante `--dart-define`. Que el texto no aparezca en la
interfaz ni en Git no convierte a la APK en un almacén seguro: una persona con
el archivo instalable podría analizarlo. Si la distribución deja de estar
restringida, las credenciales deben migrarse a un endpoint autenticado y
autorizado del backend.
