---
title: Opción 2 Objetivos de control -> Editar
layout: articles
category: execution
guide_order: 3
article_order: 2.3
parent: Informes
---
# Ejecución

## Opción 2 - Ejecución -> Objetivos de control -> Editar

Ahora vamos a realizar las actividades de control para el **objetivo de control 5.2**, por otro camino.

Seleccionamos **Ejecución -> Objetivos de control**. Muestra la siguiente pantallas con los objetivos de control:


![image]({{ site.baseurl }}/assets/images/execution/reviews/18.png){: class="img-responsive"}

Luego seleccionamos **Editar** en el objetivo de control con el cual necesitamos trabajar (en este caso 5.2 Inventario tecnológico).

A partir de este momento nos muestra las mismas pantallas de trabajo que la **opción 1**.

![image]({{ site.baseurl }}/assets/images/execution/reviews/19.png){: class="img-responsive"}

Esta pantalla es el "**escritorio"** de trabajo del auditor, el cual le permite analizar y evaluar el control interno del objetivo de control por medio de las pruebas previstas (en este caso pruebas de cumplimiento).

Las pruebas nos permiten revisar si se cumplen los controles previstos y obtener la efectividad de control para el objetivo de control que estamos revisando.

En este caso vemos que los **controles** no se están cumpliendo según lo previsto, según la prueba de cumplimiento realizada, por tal motivo la Calificación de la prueba de cumplimiento es Medio (5), logrando una efectividad de 50%.

![image]({{ site.baseurl }}/assets/images/execution/reviews/20.png){: class="img-responsive"}

Por tal motivo vamos agregar una observación, para lo cual tenemos que seleccionar la opción **Agregar nueva observación**.

![image]({{ site.baseurl }}/assets/images/execution/reviews/21.png){: class="img-responsive"}

Al seleccionar **Agregar nueva observación**, muestra la siguiente pantalla.

![image]({{ site.baseurl }}/assets/images/execution/reviews/22.png){: class="img-responsive"}
![image]({{ site.baseurl }}/assets/images/execution/reviews/23.png){: class="img-responsive"}

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

Relacionda con: podemos agregar si la observación está relacionada con otro hallazgo. Al hacerlo puedo colocar la fecha, en caso de no hacerlo coloca la fecha del informe.

Papeles de trabajo: permite agregar evidencias. Nombre, Código (PTO: papel de trabajo observación, 0001: es el primer papel de trabajo), Páginas (es opcional), Descripción, Archivo (adjuntar un documento).

Al finalizar con la carga de datos seleccionamos **Crear Observación** (si no faltan datos se guarda la observación), caso contrario nos muestra un mensaje de error con los aspectos faltantes, a continuación mostramos una pantalla con un mensaje de error.

![image]({{ site.baseurl }}/assets/images/execution/reviews/24.png){: class="img-responsive"}

Al completar los datos faltantes, y seleccionar **Crear Observación**, nos muestra el siguiente mensaje.

![image]({{ site.baseurl }}/assets/images/execution/reviews/25.png){: class="img-responsive"}

El resto de los campos faltantes (respuesta/acción correctiva, fecha de implementación/acción correctiva, fecha de solución, comentario de auditoría), se completan cuando tenga la respuesta de los usuarios auditados y a medida que avance en el proceso de trabajo.

Cuando necesitemos generar el informe borrador y definitivo (en la etapa de conclusión) el sistema realiza una serie de controles en forma automática, por ejemplo controla que todos los campos se encuentren completos, caso contrario nos informa los aspectos faltantes.

Para ver las observaciones generadas, seleccionar **Ejecución -> Observaciones**, nos muestra lo siguiente.

![image]({{ site.baseurl }}/assets/images/execution/reviews/26.png){: class="img-responsive"}

Podemos observar en primer lugar la observación generada recientemente (Estado Notificar), en caso de necesitar ver los detalles o seguir trabajando con la misma, seleccionó **Editar (Lápiz)**.

A las 20 hs. (o en el horario definido por la organización) el sistema envía un correo a los integrantes (notificación de hallazgos) de esta observación que se ha generado (debido a que se encuentra en estado **Notificar**).

![image]({{ site.baseurl }}/assets/images/execution/reviews/27.png){: class="img-responsive"}

A continuación mostramos otro ejemplo de notificación de hallazgos.

![image]({{ site.baseurl }}/assets/images/execution/reviews/28.png){: class="img-responsive"}

El usuario auditado puede seleccionar **Confirmar notificación**, al hacerlo pasa al estado **"Confirmada"**, siempre que ingrese un comentario en “Comentarios de seguimiento”.

A continuación mostramos los pasos luego que el usuario auditado selecciona **Confirmar notificación**.

Aparece la pantalla de ingreso al sistema (ingresa usuario y contraseña), selecciona Ingresar.

![image]({{ site.baseurl }}/assets/images/execution/reviews/29.png){: class="img-responsive"}

Muestra la pantalla con la observación en estado **No confirmada**, al seleccionar **Editar**, muestra la siguiente pantalla:

![image]({{ site.baseurl }}/assets/images/execution/reviews/30.png){: class="img-responsive"}

El usuario auditado ingresa:  un comentario, la fecha de compromiso y puede dejar el tilde en enviar notificación (si lo saca no envía la notificación a los integrantes). También tiene que ingresar el tiempo dedicado (por defecto esta en minutos), y una descripción de las actividades realizadas (es opcional).

Seleccionamos **Actualizar observación**, aparece la siguiente pantalla (con el cambio de estado a confirmada):

![image]({{ site.baseurl }}/assets/images/execution/reviews/31.png){: class="img-responsive"}

Además envía un correo a los integrantes de la observación, ya que dejamos con el tilde Enviar notificación.

![image]({{ site.baseurl }}/assets/images/execution/reviews/32.png){: class="img-responsive"}

Luego de esto el usuario auditor, puede ingresar al sistema o por medio de **Ver hallazgo**, y seguir con el proceso de trabajo en la observación.

Luego podemos ver en el listado de observaciones, como cambio al estado Confirmada, y resta una observación en estado No confirmada:

![image]({{ site.baseurl }}/assets/images/execution/reviews/33.png){: class="img-responsive"}

En el caso de la observación que quedó en estado No confirmada, el sistema envía un correo a las 20 hs. (notificaciones pendientes) a modo de recordatorio a los involucrados en la observación, a continuación mostramos el correo:

![image]({{ site.baseurl }}/assets/images/execution/reviews/34.png){: class="img-responsive"}

El usuario auditado también puede seleccionar **Ver Hallazgo**, al hacerlo pasa al estado Confirmada, siempre que ingrese un comentario en "Comentarios de seguimiento".

A continuación mostramos los pasos luego que el usuario auditado selecciona **Ver hallazgo**.

Aparece la pantalla de ingreso al sistema (ingresa usuario y contraseña), selecciona Ingresar.

![image]({{ site.baseurl }}/assets/images/execution/reviews/35.png){: class="img-responsive"}

Luego de ingresar muestra la siguiente pantalla:

Podemos observar que la observación sigue en estado No confirmada (hasta que el usuario auditado no ingrese un comentario en "Comentarios de seguimiento", la observación no cambia al estado Confirmada.

![image]({{ site.baseurl }}/assets/images/execution/reviews/36.png){: class="img-responsive"}

Seleccionamos el lápiz (editar), el sistema nos muestra todos los datos de la observación, para que podamos ingresar un comentario.

Además nos informa las Fechas a considerar:

* Fue notificada por primera vez el día * 8 de Diciembre de 2015*

* Pasará al estado "Sin Respuesta" el día 14 de Diciembre de 2015 si ningún auditado proporciona una respuesta

![image]({{ site.baseurl }}/assets/images/execution/reviews/37.png){: class="img-responsive"}

En este caso ingresamos comentario, fecha de compromiso, dejamos tildado enviar notificación, tiempo dedicado y descripción de las actividades realizadas (estos 2 últimos datos son opcionales):

![image]({{ site.baseurl }}/assets/images/execution/reviews/38.png){: class="img-responsive"}

Seleccionamos Actualizar observación, aparece la siguiente pantalla, donde muestra el mensaje: Respuesta a hallazgo actualizada correctamente, y el estado pasa a **Confirmada**.

![image]({{ site.baseurl }}/assets/images/execution/reviews/39.png){: class="img-responsive"}

Además notifica al resto de los integrantes de la observación por correo, informando del comentario realizado.

![image]({{ site.baseurl }}/assets/images/execution/reviews/40.png){: class="img-responsive"}

Luego de esto el usuario auditor, puede ingresar al sistema o por medio de **Ver hallazgo**, y seguir con el proceso de trabajo en la observación.

