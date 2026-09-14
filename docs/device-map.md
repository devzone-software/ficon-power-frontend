# Mapa de dispositivos de Puno

La sección **Dispositivos** permite alternar entre la lista y un mapa. El mapa
usa las coordenadas de la sede asociada a cada dispositivo; no realiza una
consulta adicional, porque latitud y longitud forman parte de la respuesta
normal de `GET /api/devices`.

## Alcance actual

Solo se muestran dispositivos cuyo distrito, provincia o departamento sea
`Puno`. La comparación ignora mayúsculas y espacios. Los filtros activos de la
pantalla también se aplican al mapa.

Un dispositivo se omite del mapa si no pertenece a Puno o si su sede no tiene
ambas coordenadas. La cabecera informa cuántos registros quedaron fuera por
cada motivo; la vista de lista continúa mostrándolos.

## Estados

- Verde: conectado.
- Naranja: sin conexión y sin incidente activo.
- Rojo: incidente activo.
- Gris: dispositivo inactivo.

Los marcadores cercanos se agrupan automáticamente. Al pulsar un marcador se
muestra un resumen con acceso a la ficha detallada. Los cambios de dispositivo,
sede, evento o incidente actualizan la pantalla mediante el stream SSE.

## Proveedor cartográfico

La capa base utiliza OpenStreetMap y muestra su atribución dentro del mapa. La
APK ya declara permiso de Internet. Para que un dispositivo aparezca, los campos
`sites.latitude` y `sites.longitude` deben contener coordenadas válidas.
