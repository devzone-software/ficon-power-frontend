# Errores visibles en web y APK

La interfaz nunca debe mostrar directamente `Exception.toString()`, URLs
internas, trazas, clases Java/Dart ni respuestas completas del servidor.

## Flujo

1. `FiconApiClient` convierte una respuesta no exitosa en `ApiException`.
2. `ExceptionHandler` interpreta `message`, `fieldErrors`, `code` y `traceId`.
3. `UserErrorMessage` produce el texto seguro que consumen vistas, diálogos y
   barras de aviso.
4. Si el backend entrega un `traceId`, la vista lo muestra como referencia para
   correlacionarlo con los logs del servidor.

Las cargas de resumen, dispositivos, incidentes, eventos, administración,
sedes e historial de notificaciones ofrecen una acción para reintentar. Las
operaciones de escritura presentan el motivo mediante el mismo traductor.

## Contrato esperado

```json
{
  "code": "validation_error",
  "message": "Revisa los datos indicados.",
  "fieldErrors": [
    {
      "field": "displayName",
      "message": "El nombre visible es obligatorio."
    }
  ],
  "traceId": "7be36b9d-87c7-4b54-a617-c45295fa60e6"
}
```

Los errores conocidos conservan el mensaje controlado por el backend. Los
fallos de red y timeout tienen textos específicos. Cualquier excepción no
reconocida se reemplaza por un mensaje genérico.
