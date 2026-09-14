# Calendario operativo

La ruta `/calendario` muestra en una misma vista mensual:

- incidentes de corte durante todos los días que abarcan;
- vencimientos de planes Tuya;
- renovaciones ya registradas;
- estado próximo o vencido y días restantes de cada plan.

El calendario solo solicita las semanas visibles y dibuja cinco o seis según
lo que realmente necesite el mes. Los eventos `incident` y `calendar` recibidos
por el canal en tiempo real disparan una recarga acotada de ese rango.

El selector de mes reserva un ancho estable para el título y las flechas, por
lo que no cambia de posición entre nombres cortos y largos. En móvil usa una
tipografía menor y ocupa una fila propia.

Todos los usuarios autenticados pueden consultar el calendario. Los incidentes
y las fechas Tuya siempre permanecen visibles, sin filtros de contenido. Los
roles con acceso administrativo pueden editar los metadatos, renovar o eliminar
un seguimiento Tuya, pero no agregarlo desde esta pantalla ni alterar fechas ya
confirmadas por Tuya Developer. Al registrar una renovación se conserva el
historial y el backend calcula el próximo vencimiento con el ciclo fijo de seis
meses.

La primera fecha existente de cada suscripción se presenta como hito completado.
Las sedes Puno, Putina y Lampa utilizan temporalmente sus centros urbanos como
coordenadas referenciales para el mapa.

Los planes e historiales usan IDs numéricos; los UUID de la respuesta pertenecen
únicamente a dispositivos, sedes e incidentes existentes.
