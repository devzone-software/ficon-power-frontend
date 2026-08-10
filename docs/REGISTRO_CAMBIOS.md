# Registro de cambios — Sistema FICON Power

## Estado vigente

- El envío de WhatsApp usa únicamente plantillas aprobadas de Meta.
- El dashboard no edita mensajes de WhatsApp; solo muestra plantilla, idioma y variables configuradas por evento.
- Las variables se muestran con nombres legibles, como “Nombre del dispositivo”, “Fecha del corte” y “Fecha de retorno”.
- Los cambios operativos se registran en la auditoría del backend.
- Los inicios de sesión se registran con usuario, IP, navegador, resultado y motivo.
- Las credenciales locales de ejemplo viven en el backend, en `.local/credentials.local.md`, ruta ignorada por Git.

## Verificación esperada

- Backend: `mvn clean test`.
- Frontend: `docker compose build frontend`.

No se deben publicar credenciales reales ni archivos dentro de `.local/`.
