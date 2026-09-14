# Destinatarios de WhatsApp en el dashboard

Los roles `ADMIN` y `SUPERADMIN` pueden abrir **Administración > WhatsApp**
para agregar responsables de alertas.

Cada registro define:

- nombre descriptivo y celular peruano;
- todas las sedes o una sede específica;
- recepción de cortes, reconexiones o ambas;
- estado activo o inactivo.

La acción **Enviar prueba** utiliza la plantilla de corte aprobada en Meta y
actualiza el último resultado mostrado. Desactivar un destinatario conserva su
configuración, mientras que eliminarlo la retira definitivamente.

El dashboard no permite modificar el token, la URL, el número emisor ni el
texto de las plantillas de Meta.

El formulario muestra `+51` como prefijo fijo. Se puede escribir
`987654321`, usar espacios o pegar `+51 987-654-321`; la vista lo presenta como
`+51 987 654 321` y la API siempre recibe el valor canónico `51987654321`.
