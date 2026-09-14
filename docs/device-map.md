# Mapa de dispositivos de Puno

La sección **Dispositivos** permite alternar entre la lista y un mapa. El mapa
usa las coordenadas de la sede asociada a cada dispositivo; no realiza una
consulta adicional, porque latitud y longitud forman parte de la respuesta
normal de `GET /api/devices`.

## Alcance actual

Solo se muestran dispositivos pertenecientes a la región Puno. Actualmente se
reconocen Puno, Putina y Lampa mediante la sede, distrito, provincia o
departamento. La comparación ignora mayúsculas y espacios. Los filtros activos
de la pantalla también se aplican al mapa.

Cuando una sede reconocida todavía no tiene coordenadas, se utiliza
temporalmente el centro urbano de Puno, Putina o Lampa. Un dispositivo se omite
si no pertenece a la región o no es posible reconocer su ciudad. La cabecera
informa cuántos registros quedaron fuera; la vista de lista continúa
mostrándolos.

La cámara inicia mostrando todos los marcadores disponibles, permite alejarse
lo suficiente para ver las tres ciudades y mantiene su centro dentro de los
límites referenciales del departamento de Puno.

## Estados

- Cian: conectado.
- Cian suave: sin conexión y sin incidente activo.
- Azul del logotipo: incidente activo.
- Azul profundo: dispositivo inactivo.

Los marcadores cercanos se agrupan automáticamente. Al pulsar un marcador se
muestra un resumen con acceso a la ficha detallada. Los cambios de dispositivo,
sede, evento o incidente actualizan la pantalla mediante el stream SSE.

## Proveedor cartográfico

La capa base utiliza OpenStreetMap y muestra su atribución dentro del mapa. La
APK ya declara permiso de Internet. Para que un dispositivo aparezca, los campos
`sites.latitude` y `sites.longitude` deben contener coordenadas válidas.
