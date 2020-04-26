---
title: Configuraciones
layout: articles
category: administration
guide_order: 1
article_order: 5
---
## Configuraciones

Seleccionamos **Administración -> Configuración**.

![]({% asset administration/configuration/1.png @path %}){: class="img-responsive"}

![]({% asset administration/configuration/2.png @path %}){: class="img-responsive"}

Podemos **Ver** **(Lupa)** y **Editar (Lápiz)** una configuración.

**A continuación mostramos ejemplos de algunas configuraciones**

**Recordatorio del stock de observaciones pendientes**

Incorporamos una funcionalidad para informar por correo un recordatorio del stock de observaciones pendientes con una frecuencia semanal (el uso es opcional, si colocamos 0 en la configuración no envía el correo con el recordatorio, si colocamos 1, va enviar el correo con el recordatorio una vez a la semana todos los lunes).

La configuración por tiempo está en semanas, por ejemplo 4 semanas, el correo va llegar cada 4 lunes, 2 semanas, el correo va llegar cada 2 lunes.

Datos incluidos en el correo:

* Asunto del correo: [nombre de la organización] Resumen de hallazgos pendientes.

* Cuerpo del correo:<br>
**Nombre de la organización**<br>
**Resumen de hallazgos pendientes**<br>
Tabla con los siguientes campos: Informe, Código observación, Título, Fecha de origen de la observación, Fecha de implementación, Auditados y un enlace (Ver) para verla en el sistema.

El correo se envía a todos los usuarios vinculados a la observación.

![]({% asset administration/configuration/3.png @path %}){: class="img-responsive"}

**Administración -> Configuraciones**.

Seleccionamos ¨Administración¨ -> ¨Configuraciones¨

El nombre del parámetro que deben modificar es Período de notificación ¨Resumen de hallazgos¨ en semanas (por defecto en 0, lo cual significa desactivado).

![]({% asset administration/configuration/4.png @path %}){: class="img-responsive"}

Seleccionamos ¨Editar¨.

![]({% asset administration/configuration/5.png @path %}){: class="img-responsive"}

La configuración por tiempo está en semanas, por ejemplo 4 semanas, el correo va llegar cada 4 lunes.

![]({% asset administration/configuration/6.png @path %}){: class="img-responsive"}

Seleccionamos ¨Actualizar Configuración¨.

![]({% asset administration/configuration/7.png @path %}){: class="img-responsive"}

**Mostrar marcas de tiempo en seguimiento**

Al colocar el parámetro en 0 (cero) el sistema muestra menos campos en las observaciones solucionadas y pendientes. Las restricciones son las siguientes:

* La opción descargar CSV, descarga una versión reducida (muestra menos campos).

* En la pantalla de cada observación, no muestra: fechas de implementaciones anteriores, listado de actividades anteriores relacionadas a la observación, fecha del comentario en los comentarios de seguimiento, solo queda disponible la opción ¨Descargar seguimiento¨ (no muestra la opción ¨Descargar seguimiento completo¨).

Seleccionamos ¨Configuración¨, muestra las configuraciones del sistema.

![]({% asset administration/configuration/8.png @path %}){: class="img-responsive"}

Seleccionamos ¨Editar¨ en ¨Mostrar marcas de tiempo en seguimiento¨

![]({% asset administration/configuration/9.png @path %}){: class="img-responsive"}

Si cambiamos el valor a ¨0¨ nos muestra las siguientes pantalla:

![]({% asset administration/configuration/10.png @path %}){: class="img-responsive"}

Si cambiamos el valor a ¨1¨ nos muestra las siguientes pantalla:

![]({% asset administration/configuration/11.png @path %}){: class="img-responsive"}

**R****equerir gerente de auditoría en hallazgos**

Primero deben habilitar el parámetro ¨Requerir gerente de auditoría en hallazgos¨ dentro de ¨Administración¨ ->  ¨Configuraciones¨, por defecto está en 0.

![]({% asset administration/configuration/12.png @path %}){: class="img-responsive"}

Si cambiamos el valor a ¨1¨ nos muestra las siguientes pantalla:

De esta forma el Gerente de auditoría va estar siempre asociado a una observación u oportunidad de mejora.

![]({% asset administration/configuration/13.png @path %}){: class="img-responsive"}

**Cantidad de días que deben pasar para que una observación sin responder se considere desatendida (pase a estado "Sin respuesta")**

**Administración -> Configuraciones -> Cantidad de días que deben pasar para que una observación sin responder se considere desatendida (pase a estado "Sin respuesta")**

Para pasar una observación a estado "Sin respuesta" se cuentan los días de la fecha de primera notificación (cuenta la cantidad de días -por ejemplo 3 días- después que pasa el correo de notificación). En algunas organizaciones este horario es a las 20 hs. (depende del tipo de organización)

La cantidad de días se carga en "Administración" -> "Configuraciones" "Cantidad de días que deben pasar para que una observación sin responder se considere desatendida (pase a estado sin respuesta)

Ahora se tiene en cuenta solamente la fecha de primera notificación, independiente de si el auditado confirma o no (esto para pasar a "Sin respuesta").

 ![]({% asset administration/configuration/14.png @path %}){: class="img-responsive"}

Trazabilidad del proceso de cambios de estado desde "Notificar"

<table class="table">
  <thead>
    <th>Estado</th>
    <th>Estado </th>
    <th>Descripción</th>
  </thead>
  <tbody>
    <tr>
      <td>Notificar</td>
      <td>No confirmada</td>
      <td>A las 20 hs (puede ser otro horario, depende de la organización) el sistema toma todos los hallazgos en estado "Notificar"  y pasa un correo a los participantes (auditores y auditados) notificando de los hallazgos. El hallazgo pasa a estado “No confirmada”.

  Durante 3 días hábiles (dependiendo del parámetro cargado por la organización), si el usuario auditado ingresa al link, pero no ingresa un comentario, el hallazgo sigue en estado “No confirmada”.

  En este estado el auditor no puede realizar tareas con el hallazgo.</td>
    </tr>
    <tr>
      <td>No confirmada</td>
      <td>Sin Respuesta</td>
      <td>Luego de 3 días hábiles (dependiendo del parámetro cargado por la organización) pasa a “Sin respuesta”, si el usuario auditado no ingresa un comentario.

  En este estado el auditor puede iniciar tareas con el hallazgo.</td>
    </tr>
    <tr>
      <td>No confirmada</td>
      <td>Confirmada</td>
      <td>Pasa a este estado, si el usuario auditado ingresa un comentario (antes de los 3 días hábiles, dependiendo del parámetro cargado por la organización).

  En este estado el auditor puede iniciar tareas con el hallazgo.</td>
    </tr>
  </tbody>
</table>


**Cierre de sesión por inactividad**

Muestra de una forma simple al usuario que está por finalizar el tiempo asignado por inactividad (parámetro cargado en Administración -> Configuraciones - Desconexión por inactividad).

Cuando faltan 2 minutos se pone negra toda la barra y aparece un icono que parpadea en amarillo (al lado de **"Seguimiento"**), que luego de 2 minutos se pone rojo para indicar que la sesión expiró.

Si pasan el mouse sobre el icono (cuando está en amarillo) muestra el mensaje:

> Advertencia<br>
> Su sesión expira en menos de 2 minutos

![]({% asset administration/configuration/15.png @path %}){: class="img-responsive"}

Si presionan cualquier tecla o hacen clic se vuelve al blanco original y se reinicia el tiempo.

![]({% asset administration/configuration/16.png @path %}){: class="img-responsive"}

Si pasan el mouse sobre el icono (cuando está en rojo) muestra el mensaje:

> Advertencia<br>
> Su sesión ha expirado, debe autenticarse nuevamente

![]({% asset administration/configuration/17.png @path %}){: class="img-responsive"}

Si presionan cualquier tecla o hacen clic vuelve a la pantalla de login.

![]({% asset administration/configuration/18.png @path %}){: class="img-responsive"}
