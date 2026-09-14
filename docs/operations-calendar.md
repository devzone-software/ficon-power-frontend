# Calendario operativo

La ruta `/calendario` muestra en una misma vista mensual:

- incidentes de corte durante todos los días que abarcan;
- vencimientos de planes Tuya;
- renovaciones ya registradas;
- estado próximo o vencido y días restantes de cada plan.

El calendario solo solicita las seis semanas visibles. Los eventos `incident`
y `calendar` recibidos por el canal en tiempo real disparan una recarga acotada
de ese rango.

Todos los usuarios autenticados pueden consultar el calendario. Los roles con
acceso administrativo pueden crear, editar, desactivar, renovar o eliminar un
seguimiento Tuya. Al registrar una renovación se conserva el historial y el
backend calcula el próximo vencimiento según el ciclo configurado.

Los planes e historiales usan IDs numéricos; los UUID de la respuesta pertenecen
únicamente a dispositivos, sedes e incidentes existentes.
