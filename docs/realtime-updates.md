# Actualización del dashboard en tiempo real

La aplicación abre una sola conexión SSE autenticada a
`/api/realtime/stream`. Todas las pantallas visibles comparten esa conexión y se
suscriben únicamente a los tipos de entidad que afectan sus datos.

Flujo:

1. La pantalla hace su carga inicial mediante REST.
2. El backend envía una invalidación SSE después del commit de base de datos.
3. Los avisos cercanos se agrupan durante 450 ms para evitar varias consultas
   por una misma operación.
4. La pantalla vuelve a consultar REST y muestra el estado confirmado.
5. Si la conexión termina, se reconecta con espera exponencial de 1 a 30 s.
6. Se conserva un refresco de seguridad cada 3 minutos y el gesto de recarga
   manual.

Al cerrar sesión se cancela el stream. Los errores transitorios del stream no
reemplazan el contenido actual ni muestran una pantalla de error; el sondeo de
seguridad permite recuperarse si un proxy o una red móvil bloquea SSE.

## Nginx

La ubicación exacta `/api/realtime/stream` desactiva buffering y caché, elimina
el encabezado `Connection` del proxy y usa un timeout de una hora. La ruta REST
general conserva su timeout corto.

## Tipos escuchados

- Resumen: dispositivo, incidente, evento, sede y plantilla.
- Dispositivos: dispositivo, incidente, evento y sede.
- Detalle: solo el dispositivo abierto y sus incidentes/eventos.
- Incidentes: incidente y dispositivo.
- Eventos: evento.
- Administración: usuario, auditoría, login y sesión.
- WhatsApp: destinatario y sede.

Los IDs de eventos que ahora provienen de `bigint` se interpretan como texto;
esto evita pérdida de precisión en Flutter Web.
