---
title: Objetivos de control
layout: articles
category: execution
guide_order: 3
article_order: 4
---
# Ejecución

## Objetivos de control

Muestra los objetivos de control ordenados por informe, permite encontrar en forma rápida con la opción **Buscar** por Informe, Proceso y Objetivo de control, ingresando alguna letra, palabra o número.

Permite realizar las siguientes actividades para cada uno de los objetivos de control que se encuentran en el listado:

* Analizar y evaluar el control interno.

* Efectuar pruebas (evaluación de diseño, pruebas de cumplimiento, pruebas sustantivas).

**Seleccionamos Ejecución -> Objetivos de control**

![]({% asset execution/ctrol_objectives/1.png @path %}){: class="img-responsive"}

Nos muestra los objetivos de control.

![]({% asset execution/ctrol_objectives/2.png @path %}){: class="img-responsive"}

Si necesitamos encontrar en forma rápida tenemos la opción de **Buscar** por Informe, Proceso y Objetivo de control, ingresando alguna letra, palabra o número.

![]({% asset execution/ctrol_objectives/3.png @path %}){: class="img-responsive"}

Podemos iniciar las siguientes actividades para cada uno de los objetivos de control que se encuentran en el listado, por ejemplo para el **¨objetivo de control: 5.2 Inventario tecnológico¨**:

* Analizar y evaluar el control interno.

* Efectuar pruebas (evaluación de diseño, pruebas de cumplimiento, pruebas sustantivas).

Para iniciar y realizar estas actividades seleccionamos **Ejecución -> Objetivos de control**

Luego seleccionamos **Editar** en el objetivo de control con el cual necesitamos trabajar (en este caso 5.2 Inventario tecnológico).

![]({% asset execution/ctrol_objectives/4.png @path %}){: class="img-responsive"}

A partir de este momento nos muestra la pantalla de trabajo:

![]({% asset execution/ctrol_objectives/5.png @path %}){: class="img-responsive"}

Esta pantalla es el "**escritorio"** de trabajo del auditor, el cual le permite analizar y evaluar el control interno del objetivo de control por medio de las pruebas previstas (en este caso pruebas de cumplimiento).

Las pruebas nos permiten revisar si se cumplen los controles previstos y obtener la efectividad de control para el objetivo de control que estamos revisando.

En este caso vemos que los **controles** no se están cumpliendo según lo previsto, según la prueba de cumplimiento realizada, por tal motivo la Calificación de la prueba de cumplimiento es Medio (5), logrando una efectividad de 50%.

![]({% asset execution/ctrol_objectives/6.png @path %}){: class="img-responsive"}

Por tal motivo vamos agregar una observación, para lo cual tenemos que seleccionar la opción **Agregar nueva observación**.

![]({% asset execution/ctrol_objectives/7.png @path %}){: class="img-responsive"}

Al seleccionar **Agregar nueva observación**, muestra la siguiente pantalla.

![]({% asset execution/ctrol_objectives/8.png @path %}){: class="img-responsive"}
![]({% asset execution/ctrol_objectives/9.png @path %}){: class="img-responsive"}

Esta pantalla nos muestra los datos para crear una observación, para guardar los cambios tenemos que seleccionar **Crear Observación**.

Al crear una observación, se genera un código de observación en forma automática por el sistema (**O0001**). "O" significa: observación. “0001”: es la primera observación del informe. Y nos muestra todos los datos cargados en la buena práctica y en el trabajo realizado hasta el momento con el objetivo de control.

Título: es un descripción resumida del tema de la observación.

Reiterada de: podemos seleccionar si la observación es reiterada de otra observación. Si lo hacemos, la **anterior** pasa a reiterada, y la **nueva** toma todos los datos de la anterior.

Observación: se redacta la observación encontrada.

Recomendaciones de auditoría: colocamos los aspectos a tener en cuenta para solucionar la observación o cualquier otro tema que consideremos importante aportar desde una visión proactiva.

Fecha de origen: completamos con la fecha que fue detectada la observación.

Riesgo: seleccionamos el valor (Alto, Medio, Bajo) para esta observación.

Prioridad: seleccionamos el valor (Alta, Media, Baja) para esta observación.

Estado: los valores son Anulada, En proceso de implementación, Implementada, Implementada/auditada, Incompleta, Notificar, Riesgo asumido, Difiere Criterio.

Cuando el auditor inicia el trabajo con la observación, selecciona el estado **Incompleta **(es lo recomendable para seguir un circuito de trabajo ordenado y simple). Al colocarla en este estado, el usuario auditado no pueda ver la observación (se usa durante el tiempo que el auditor está trabajando con la observación). El auditor puede iniciar el trabajo con la observación en cualquiera de los estados previstos, esto depende de la forma de trabajo de la organización. En base al estado seleccionado por el auditor, el sistema solicita mayor cantidad de datos para crearla.

Si la colocamos en estado **Notificar**, el sistema envía un correo en forma automática a todos los responsables a las 20 hs. (o en el horario definido por la organización)

Responsables: nos muestra los usuarios cargados en la etapa de planificación. Podemos agregar y/o cambiar usuarios. Para crear una observación, como mínimo siempre tiene que existir 1 auditor, 1 supervisor y 1 auditado, o 1 auditor, 1 gerente de auditoría y 1 auditado. Podemos seleccionar en forma opcional el Auditor referente (es el encargado de seguir el proceso de trabajo con la observación), y el Responsable por el lado de los auditados (es el encargado de seguir el proceso de trabajo con la observación).

Relacionada con: podemos agregar si la observación está relacionada con otro hallazgo. Al hacerlo puedo colocar la fecha, en caso de no hacerlo coloca la fecha del informe.

Papeles de trabajo: permite agregar evidencias. Nombre, Código (PTO: papel de trabajo observación, 0001: es el primer papel de trabajo), Páginas (es opcional), Descripción, Archivo (adjuntar un documento).

Al finalizar con la carga de datos seleccionamos **Crear Observación** (si no faltan datos se guarda la observación), caso contrario nos muestra un mensaje de error con los aspectos faltantes, a continuación mostramos una pantalla con un mensaje de error.

![]({% asset execution/ctrol_objectives/10.png @path %}){: class="img-responsive"}

Al completar los datos faltantes, y seleccionar **Crear Observación**, nos muestra el siguiente mensaje.

![]({% asset execution/ctrol_objectives/11.png @path %}){: class="img-responsive"}

El resto de los campos faltantes (respuesta/acción correctiva, fecha de implementación/acción correctiva, fecha de solución, comentario de auditoría), se completan cuando tenga la respuesta de los usuarios auditados y a medida que avance en el proceso de trabajo.

Cuando necesitemos generar el informe borrador y definitivo (en la etapa de conclusión) el sistema realiza una serie de controles en forma automática, por ejemplo controla que todos los campos se encuentren completos, caso contrario nos informa los aspectos faltantes.

Para ver las observaciones generadas, seleccionar **Ejecución -> Observaciones**, nos muestra lo siguiente.

![]({% asset execution/ctrol_objectives/12.png @path %}){: class="img-responsive"}

Podemos observar en primer lugar la observación generada recientemente (Estado Notificar), en caso de necesitar ver los detalles o seguir trabajando con la misma, seleccionó **Editar (Lápiz)**.

A las 20 hs. (o en el horario definido por la organización) el sistema envía un correo a los integrantes (notificación de hallazgos) de esta observación que se ha generado (debido a que se encuentra en estado **Notificar**).

![]({% asset execution/ctrol_objectives/13.png @path %}){: class="img-responsive"}

A continuación mostramos otro ejemplo de notificación de hallazgos.

![]({% asset execution/ctrol_objectives/14.png @path %}){: class="img-responsive"}

El usuario auditado puede seleccionar **Confirmar notificación**, al hacerlo pasa al estado **"Confirmada"**, siempre que ingrese un comentario en “Comentarios de seguimiento”.

A continuación mostramos los pasos luego que el usuario auditado selecciona **Confirmar notificación**.

Aparece la pantalla de ingreso al sistema (ingresa usuario y contraseña), selecciona Ingresar.

![]({% asset execution/ctrol_objectives/15.png @path %}){: class="img-responsive"}

Muestra la pantalla con la observación en estado **No confirmada**, al seleccionar **Editar**, muestra la siguiente pantalla:

![]({% asset execution/ctrol_objectives/16.png @path %}){: class="img-responsive"}

El usuario auditado ingresa:  un comentario, la fecha de compromiso y puede dejar el tilde en enviar notificación (si lo saca no envía la notificación a los integrantes). También tiene que ingresar el tiempo dedicado (por defecto esta en minutos), y una descripción de las actividades realizadas (es opcional).

Seleccionamos **Actualizar observación**, aparece la siguiente pantalla (con el cambio de estado a confirmada):

![]({% asset execution/ctrol_objectives/17.png @path %}){: class="img-responsive"}

Además envía un correo a los integrantes de la observación, ya que dejamos con el tilde Enviar notificación.

![]({% asset execution/ctrol_objectives/18.png @path %}){: class="img-responsive"}

Luego de esto el usuario auditor, puede ingresar al sistema o por medio de **Ver hallazgo**, y seguir con el proceso de trabajo en la observación.

Luego podemos ver en el listado de observaciones, como cambio al estado Confirmada, y resta una observación en estado No confirmada:

![]({% asset execution/ctrol_objectives/19.png @path %}){: class="img-responsive"}

En el caso de la observación que quedó en estado No confirmada, el sistema envía un correo a las 20 hs. (notificaciones pendientes) a modo de recordatorio a los involucrados en la observación, a continuación mostramos el correo:

![]({% asset execution/ctrol_objectives/20.png @path %}){: class="img-responsive"}

El usuario auditado también puede seleccionar **Ver Hallazgo**, al hacerlo pasa al estado Confirmada, siempre que ingrese un comentario en "Comentarios de seguimiento".

A continuación mostramos los pasos luego que el usuario auditado selecciona **Ver hallazgo**.

Aparece la pantalla de ingreso al sistema (ingresa usuario y contraseña), selecciona Ingresar.

![]({% asset execution/ctrol_objectives/21.png @path %}){: class="img-responsive"}

Luego de ingresar muestra la siguiente pantalla:

Podemos observar que la observación sigue en estado No confirmada (hasta que el usuario auditado no ingrese un comentario en "Comentarios de seguimiento", la observación no cambia al estado Confirmada.

![]({% asset execution/ctrol_objectives/22.png @path %}){: class="img-responsive"}

Seleccionamos el lápiz (editar), el sistema nos muestra todos los datos de la observación, para que podamos ingresar un comentario.

Además nos informa las Fechas a considerar:

* Fue notificada por primera vez el día * 8 de Diciembre de 2015*

* Pasará al estado "Sin Respuesta" el día 14 de Diciembre de 2015 si ningún auditado proporciona una respuesta

![]({% asset execution/ctrol_objectives/23.png @path %}){: class="img-responsive"}

En este caso ingresamos comentario, fecha de compromiso, dejamos tildado enviar notificación, tiempo dedicado y descripción de las actividades realizadas (estos 2 últimos datos son opcionales):

![]({% asset execution/ctrol_objectives/24.png @path %}){: class="img-responsive"}

Seleccionamos Actualizar observación, aparece la siguiente pantalla, donde muestra el mensaje: Respuesta a hallazgo actualizada correctamente, y el estado pasa a **Confirmada**.

![]({% asset execution/ctrol_objectives/25.png @path %}){: class="img-responsive"}

Además notifica al resto de los integrantes de la observación por correo, informando del comentario realizado.

![]({% asset execution/ctrol_objectives/26.png @path %}){: class="img-responsive"}

Luego de esto el usuario auditor, puede ingresar al sistema o por medio de **Ver hallazgo**, y seguir con el proceso de trabajo en la observación.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad para dar soporte a **"auditorías continuas e integrales"**.

Estamos realizando pruebas a un objetivo de control para una unidad de negocio (Sucursal 1), realizamos la evaluación para la misma (cargando la efectividad de control). Pero nos damos cuenta que en otras Sucursales también existen estos problemas (por ejemplo la Sucursal 3).

También tenemos la posibilidad de Calificar (cargar la efectividad de control) a más de una unidad de negocio (seleccionando por tipo).

**Ejecución -> Objetivos de control**

Seleccionamos "Editar" de un objetivo de control.

![]({% asset execution/ctrol_objectives/27.png @path %}){: class="img-responsive"}

Luego "Agregar calificación de unidad de negocio", permite seleccionar una unidad de negocio (por ejemplo Sucursal 3), y realizar la calificación de “evaluación de diseño”, “Pruebas de cumplimiento” y “Pruebas sustantivas”.

![]({% asset execution/ctrol_objectives/28.png @path %}){: class="img-responsive"}

También podemos seleccionar "Agregar unidad de negocio por tipo", esto permite seleccionar una unidad de negocio completa (por ejemplo Sucursales, muestra todas las Sucursales), y realizar la calificación de “evaluación de diseño”, “Pruebas de cumplimiento” y “Pruebas sustantivas”.

![]({% asset execution/ctrol_objectives/29.png @path %}){: class="img-responsive"}

Luego  seleccionamos "Actualizar objetivo de control", nos muestra la siguiente pantalla:

![]({% asset execution/ctrol_objectives/30.png @path %}){: class="img-responsive"}

Ingresamos las calificaciones correspondientes (por defecto trae el valor óptimo para las pruebas que tenemos cargados procedimientos, en este caso "Pruebas de cumplimiento".

Para guardar seleccionamos "Actualizar objetivo de control".

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad que permite identificar los objetivos de control que no han sido calificados, marcados como **"No calificar"**.

**Ejecución -> Objetivos de control**

Los objetivos de control marcados como "No calificar", ahora se muestra tachado el porcentaje del campo "Efectividad de control" (Ejemplo: último objetivo de control en el listado de la pantalla), y si posamos el mouse nos muestra el siguiente mensaje: “No se tiene en cuenta en la calificación del informe”.

![]({% asset execution/ctrol_objectives/31.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejora en los**¨Enlaces¨** para buscar observaciones y oportunidades de mejora.

**Ejecución -> Objetivos de control**

En la edición de los objetivos de control se reemplazó la tabla "resumen" de las observaciones y oportunidades de mejora, ahora se muestra una lista con enlaces a ver y editar cada una (junto con los estados en el caso de las observaciones).

![]({% asset execution/ctrol_objectives/32.png @path %}){: class="img-responsive"}
