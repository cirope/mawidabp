---
title: Opción 2 Objectivos de control -> Editar
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


![]({% asset execution/reviews/18.png @path %}){: class="img-responsive"}

Luego seleccionamos **Editar** en el objetivo de control con el cual necesitamos trabajar (en este caso 5.2 Inventario tecnológico).

A partir de este momento nos muestra las mismas pantallas de trabajo que la **opción 1**.

![]({% asset execution/reviews/19.png @path %}){: class="img-responsive"}

Esta pantalla es el "**escritorio"** de trabajo del auditor, el cual le permite analizar y evaluar el control interno del objetivo de control por medio de las pruebas previstas (en este caso pruebas de cumplimiento).

Las pruebas nos permiten revisar si se cumplen los controles previstos y obtener la efectividad de control para el objetivo de control que estamos revisando.

En este caso vemos que los **controles** no se están cumpliendo según lo previsto, según la prueba de cumplimiento realizada, por tal motivo la Calificación de la prueba de cumplimiento es Medio (5), logrando una efectividad de 50%.

![]({% asset execution/reviews/20.png @path %}){: class="img-responsive"}

Por tal motivo vamos agregar una observación, para lo cual tenemos que seleccionar la opción **Agregar nueva observación**.

![]({% asset execution/reviews/21.png @path %}){: class="img-responsive"}

Al seleccionar **Agregar nueva observación**, muestra la siguiente pantalla.

![]({% asset execution/reviews/22.png @path %}){: class="img-responsive"}
![]({% asset execution/reviews/23.png @path %}){: class="img-responsive"}

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

![]({% asset execution/reviews/24.png @path %}){: class="img-responsive"}

Al completar los datos faltantes, y seleccionar **Crear Observación**, nos muestra el siguiente mensaje.

![]({% asset execution/reviews/25.png @path %}){: class="img-responsive"}

El resto de los campos faltantes (respuesta/acción correctiva, fecha de implementación/acción correctiva, fecha de solución, comentario de auditoría), se completan cuando tenga la respuesta de los usuarios auditados y a medida que avance en el proceso de trabajo.

Cuando necesitemos generar el informe borrador y definitivo (en la etapa de conclusión) el sistema realiza una serie de controles en forma automática, por ejemplo controla que todos los campos se encuentren completos, caso contrario nos informa los aspectos faltantes.

Para ver las observaciones generadas, seleccionar **Ejecución -> Observaciones**, nos muestra lo siguiente.

![]({% asset execution/reviews/26.png @path %}){: class="img-responsive"}

Podemos observar en primer lugar la observación generada recientemente (Estado Notificar), en caso de necesitar ver los detalles o seguir trabajando con la misma, seleccionó **Editar (Lápiz)**.

A las 20 hs. (o en el horario definido por la organización) el sistema envía un correo a los integrantes (notificación de hallazgos) de esta observación que se ha generado (debido a que se encuentra en estado **Notificar**).

![]({% asset execution/reviews/27.png @path %}){: class="img-responsive"}

A continuación mostramos otro ejemplo de notificación de hallazgos.

![]({% asset execution/reviews/28.png @path %}){: class="img-responsive"}

El usuario auditado puede seleccionar **Confirmar notificación**, al hacerlo pasa al estado **"Confirmada"**, siempre que ingrese un comentario en “Comentarios de seguimiento”.

A continuación mostramos los pasos luego que el usuario auditado selecciona **Confirmar notificación**.

Aparece la pantalla de ingreso al sistema (ingresa usuario y contraseña), selecciona Ingresar.

![]({% asset execution/reviews/29.png @path %}){: class="img-responsive"}

Muestra la pantalla con la observación en estado **No confirmada**, al seleccionar **Editar**, muestra la siguiente pantalla:

![]({% asset execution/reviews/30.png @path %}){: class="img-responsive"}

El usuario auditado ingresa:  un comentario, la fecha de compromiso y puede dejar el tilde en enviar notificación (si lo saca no envía la notificación a los integrantes). También tiene que ingresar el tiempo dedicado (por defecto esta en minutos), y una descripción de las actividades realizadas (es opcional).

Seleccionamos **Actualizar observación**, aparece la siguiente pantalla (con el cambio de estado a confirmada):

![]({% asset execution/reviews/31.png @path %}){: class="img-responsive"}

Además envía un correo a los integrantes de la observación, ya que dejamos con el tilde Enviar notificación.

![]({% asset execution/reviews/32.png @path %}){: class="img-responsive"}

Luego de esto el usuario auditor, puede ingresar al sistema o por medio de **Ver hallazgo**, y seguir con el proceso de trabajo en la observación.

Luego podemos ver en el listado de observaciones, como cambio al estado Confirmada, y resta una observación en estado No confirmada:

![]({% asset execution/reviews/33.png @path %}){: class="img-responsive"}

En el caso de la observación que quedó en estado No confirmada, el sistema envía un correo a las 20 hs. (notificaciones pendientes) a modo de recordatorio a los involucrados en la observación, a continuación mostramos el correo:

![]({% asset execution/reviews/34.png @path %}){: class="img-responsive"}

El usuario auditado también puede seleccionar **Ver Hallazgo**, al hacerlo pasa al estado Confirmada, siempre que ingrese un comentario en "Comentarios de seguimiento".

A continuación mostramos los pasos luego que el usuario auditado selecciona **Ver hallazgo**.

Aparece la pantalla de ingreso al sistema (ingresa usuario y contraseña), selecciona Ingresar.

![]({% asset execution/reviews/35.png @path %}){: class="img-responsive"}

Luego de ingresar muestra la siguiente pantalla:

Podemos observar que la observación sigue en estado No confirmada (hasta que el usuario auditado no ingrese un comentario en "Comentarios de seguimiento", la observación no cambia al estado Confirmada.

![]({% asset execution/reviews/36.png @path %}){: class="img-responsive"}

Seleccionamos el lápiz (editar), el sistema nos muestra todos los datos de la observación, para que podamos ingresar un comentario.

Además nos informa las Fechas a considerar:

* Fue notificada por primera vez el día * 8 de Diciembre de 2015*

* Pasará al estado "Sin Respuesta" el día 14 de Diciembre de 2015 si ningún auditado proporciona una respuesta

![]({% asset execution/reviews/37.png @path %}){: class="img-responsive"}

En este caso ingresamos comentario, fecha de compromiso, dejamos tildado enviar notificación, tiempo dedicado y descripción de las actividades realizadas (estos 2 últimos datos son opcionales):

![]({% asset execution/reviews/38.png @path %}){: class="img-responsive"}

Seleccionamos Actualizar observación, aparece la siguiente pantalla, donde muestra el mensaje: Respuesta a hallazgo actualizada correctamente, y el estado pasa a **Confirmada**.

![]({% asset execution/reviews/39.png @path %}){: class="img-responsive"}

Además notifica al resto de los integrantes de la observación por correo, informando del comentario realizado.

![]({% asset execution/reviews/40.png @path %}){: class="img-responsive"}

Luego de esto el usuario auditor, puede ingresar al sistema o por medio de **Ver hallazgo**, y seguir con el proceso de trabajo en la observación.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad "Hallazgos pendientes".

**Ejecución -> Informes**

Seleccionamos "Editar" en un informe.

![]({% asset execution/reviews/41.png @path %}){: class="img-responsive"}

**"Agregar hallazgo pendiente"**, se ingresan caracteres, muestra un listado de observaciones, seleccionamos una. Luego podemos seguir agregando observaciones realizando los mismos pasos. Para cambiar el estado de la observación, seleccionamos la "Lupa", luego podemos editar la misma.

**"Sugerir hallazgos pendientes"**, muestra las observaciones pendientes para la unidad de negocio que corresponde el proyecto (informe) en el que estamos trabajando. Tenemos la posibilidad de dejar todas o eliminar las que no nos interesan para el informe. Para cambiar el estado de la observación, seleccionamos la "Lupa", luego podemos editar la misma.

**"Sugerir hallazgos solucionados recientes"**, busca observaciones normalizadas generadas en los últimos tres años para la unidad de negocio seleccionada. Solo busca en informes definitivos (consistente con "Sugerir hallazgos pendientes").

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad de **"Recodificación de observaciones"**.

**Ejecución -> Informes**

El objetivo es evitar saltos en la numeración cuando hay anulación de observaciones.

Editar un informe desde ejecución, al final dentro del menú "Acciones" van a encontrar "Recodificar hallazgos".

Básicamente lo que se hace ahí es a todas las observaciones anuladas prefijarlas con una "A" delante del código y reutilizar este código. Antes de recodificar las ordena por código, así la O002 será la O001, la O003 será la O002 y la O004 será la O003.

Las observaciones anuladas son un estado final que no se puede revertir. Ninguna observación anulada sale en los PDFs de los informes. Tampoco se tienen en cuenta para los reportes. Es decir, se comportan bastante similar a una eliminación, con la diferencia que queda la evidencia que se consideró. Se puede "reutilizar" su número, por ejemplo, si tuvieran O001, O002 y O003 y anulan la O002 podrían ir a editar en informe desde ejecución (y luego Acciones -> Recodificar hallazgos) para que queden O001 y O002 (anteriormente O003).

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad marcar como **"Responsables"** a usuarios en informes.

**Ejecución -> Informes**

Seleccionamos "Editar"

Los usuarios de un informe se pueden marcar como **"Responsable"**.

Si tiene responsables se muestran bajo el título "Responsables" al final en la carátula (primera hoja del informe), si no se marcan responsables el informe se muestra sin estos datos

![]({% asset execution/reviews/42.png @path %}){: class="img-responsive"}

![]({% asset execution/reviews/43.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos el rol **"Veedor"** para usuarios ¨Auditados¨.

**Ejecución -> Informes**

El rol veedor se agregó para participar a usuarios de perfil "auditado" en informes que lo ameriten, sin que estos tengan más que una figura de "observador", por ejemplo usuarios que forman parte del comité de auditoría.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad **¨Recodificar hallazgos por riesgo¨**.

**Ejecución -> Informes**

Hay una nueva opción para recodificar hallazgos desde los informes: "Recodificar hallazgos por riesgo".

Seleccionamos "Editar" en un informe, al final de la pantalla seleccionamos “Acciones”.

![]({% asset execution/reviews/44.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad que permite ordenar los informes de una manera más simple y luego alternativas de buscar.

**Ejecución -> Informes**

El orden de los informes en ejecución muestra primero los sin definitivo, luego los que tienen definitivo, ordenados por identificación en cada caso.

![]({% asset execution/reviews/45.png @path %}){: class="img-responsive"}

Luego podemos seleccionar "Buscar", para que les permita ordenar tanto de forma ascendente como descendente.

Seleccionamos "Buscar", muestra “Ordenar por”, seleccionamos esta opción y muestra: Identificación Ascendente, Identificación descendente, Período Ascendente, Período Descendente”, seleccionamos “Identificación Ascendente”, luego  “Buscar”.

![]({% asset execution/reviews/46.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad que permite separar por roles **¨Auditoría** ((auditores) y **¨Usuarios¨** ( auditados) los integrantes de un informe.

**Ejecución -> Informes**

En los informes en ejecución ahora se separa el equipo de auditoría del resto de los roles "Auditoría" y “Usuarios”. Además, cuando se selecciona un usuario, el “Rol” que se despliega es solo posible para la persona elegida.

![]({% asset execution/reviews/47.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora  funcionalidad**

Incorporamos la siguientes mejoras referidas a Papeles de trabajo **¨Conforme auditor¨**, **¨Revisado supervisor¨** y **¨Nuevo reporte¨**.

**Ejecución -> Informes**

Incorporamos la funcionalidad que permite que un auditor informe cuando finalizó la carga de papeles de trabajo, el conforme del supervisor y un reporte ¨Informes cerrados sin conformidad auditor (lista los "informes cerrados sin conformidad auditor" e “informes cerrados sin revisión supervisor”).

**Ejecución -> Informes -> "Papeles de trabajo - Conforme auditor"**

Agregamos dentro de las "Acciones" de los informes en ejecución la opción **"Papeles de trabajo - Conforme auditor"**.

Esto "marca" al informe para indicar que se finalizó la carga de los papeles de trabajo (sería previo a la fecha de cierre).

Es opcional su uso, pero en caso que lo hagan se muestra un icono "clip"en la primera columna del listado indicando que el informe tiene dicha marca.

![]({% asset execution/reviews/48.png @path %}){: class="img-responsive"}

Si seleccionamos "Papeles de trabajo - Conforme Auditor", nos muestra la siguiente pantalla

![]({% asset execution/reviews/49.png @path %}){: class="img-responsive"}

Si seleccionamos OK, muestra la siguiente pantalla

![]({% asset execution/reviews/50.png @path %}){: class="img-responsive"}

Una vez realizada, en el listado de informes figura un icono "clip", pasando sobre el mismo está la leyenda "Papeles de trabajo marcados como conforme auditor".

![]({% asset execution/reviews/51.png @path %}){: class="img-responsive"}

Lo mismo cuando se edita o visualiza desde la lupa el informe, la leyenda se muestra al final de la página en un recuadro celeste.

![]({% asset execution/reviews/52.png @path %}){: class="img-responsive"}

**Ejecución -> Informes -> "Papeles de trabajo - Revisado auditor"**

En conjunto con la anterior se agregó una opción en los informes en ejecución dentro de "Acciones", "Papeles de trabajo - Revisado supervisor" (**solo visible para los usuarios supervisores cuando está marcado con la opción anterior**).

![]({% asset execution/reviews/53.png @path %}){: class="img-responsive"}

En caso que agreguemos o modifiquemos un papel de trabajo existente, se "desmarca" el conforme auditor (incluso si estaba supervisado).

**Ejecución -> Reportes -> "Informes cerrados sin conformidad auditor"**

También en conjunto con lo anterior, se agregó un nuevo reporte en "Ejecución" -> "Reportes" -> "Informes cerrados sin conformidad auditor" (lista los "informes cerrados sin conformidad auditor" e “informes cerrados sin revisión supervisor”).

![]({% asset execution/reviews/54.png @path %}){: class="img-responsive"}

Si seleccionamos "Informes cerrados sin conformidad auditor", se pueden listar los "informes cerrados sin conformidad auditor" e “informes cerrados sin revisión supervisor”.

![]({% asset execution/reviews/55.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad que permite tener en cuenta el estado **¨Riesgo asumido¨** en las búsquedas de observaciones pendientes.

**Ejecución -> Informes**

Para la sugerencia de observaciones pendientes dentro de  "Ejecución" -> "Informes" ahora se tienen en cuenta el estado "Riesgo asumido".

![]({% asset execution/reviews/56.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Para mostrar datos, agregamos el campo **"Auditoría"**, el cual nos muestra a los auditores (con un icono para cada uno), se permite utilizar la columna para las búsquedas utilizando el apellido. Si posicionamos el mouse sobre una de los iconos nos muestra el Apellido y nombre del auditor.

**Ejecución -> Informes**

Seleccionamos "Informes" nos muestra los informes.

![]({% asset execution/reviews/57.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Muestra los informes que tienen **¨informe definitivos tachados¨**.

**Ejecución -> Informes**

Los informes que se encuentran tachados tienen informe definitivo.

![]({% asset execution/reviews/58.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Se agregó la opción "Sugerir hallazgos relacionados recientes" en los informes de ejecución.

**Ejecución -> Informes**

Se agregó la opción "Sugerir hallazgos relacionados recientes" en los informes de ejecución. Esta opción busca los hallazgos en estado "Implementada/Auditada" de los últimos tres años.

![]({% asset execution/reviews/59.png @path %}){: class="img-responsive"}

En caso que no existan hallazgos muestra la siguiente pantalla:

![]({% asset execution/reviews/60.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Se agregó la opción **"Recodificar hallazgos por riesgo"**.

**Ejecución -> Informes**

Se agregó la opción "Recodificar hallazgos por riesgo" dentro de "Acciones" de los informes en ejecución. Básicamente ordena las hallazgos de mayor a menor por riesgo y como segundo campo el código del hallazgo.

Las observaciones se pueden recodificar por riesgo dentro de la edición en "Acciones".

Seleccionamos "Editar" en un informe, al final de la pantalla seleccionamos “Acciones”. “Recodificar hallazgos por riesgo”.

![]({% asset execution/reviews/61.png @path %}){: class="img-responsive"}

El tema de recodificar por riesgo funciona ordenando todas las observaciones por riesgo (y como segundo campo el código de la observación) de mayor a menor.

Después toma cada una y comienza a numerarlas de nuevo, sería por ejemplo:

>O001 - Riesgo medio<br>
>O002 - Riesgo bajo<br>
>O003 - Riesgo medio<br>
>O004 - Riesgo alto

Quedaría:

>O001 - Riesgo alto (ex O004)<br>
>O002 - Riesgo medio (ex O001)<br>
>O003 - Riesgo medio (ex O003)<br>
>O004 - Riesgo bajo (ex O002)

La otra recodificación sirve para eliminar los huecos en caso de anulaciones. En este caso ignora el campo riesgo, solo tiene en cuenta el código anterior, por ejemplo:

>O001 - Riesgo medio<br>
>O002 - Riesgo bajo<br>
>O003 - Riesgo medio (anulada)<br>
>O004 - Riesgo alto<br>

Quedaría:

>O001 - Riesgo medio (sin cambios)<br>
>O002 - Riesgo bajo (sin cambios)<br>
>O003 - Riesgo medio (prefijo A)<br>
>O003 - Riesgo alto (ex O004)<br>

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Agregar una **¨buena práctica¨** en la creación de un informe

**Ejecución -> Informes**

En los informes ahora se pueden agregar todos los objetivos de control de una buena práctica a la vez.

Si seleccionamos "buena práctica" nos muestra la siguiente pantalla:

![]({% asset execution/reviews/62.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos **¨mostrar los objetivos de control de una buena práctica no incluidos en el informe¨**.

**Ejecución -> Informes**

Dentro de la edición de un informe, a la derecha del título "Objetivos de control" hay un icono representando una "tijera", al hacer clic muestra los objetivos de control que están en la buena práctica pero no incluidos en el informe (sería los que se "quedaron afuera" o no fueron seleccionados para incorporar en el alcance del trabajo).

Seleccionamos "Ejecución" -> "Informes".

![]({% asset execution/reviews/63.png @path %}){: class="img-responsive"}

Luego "Editar" por ejemplo “Ejercicio 2017” “2017 TI 01 5”.

![]({% asset execution/reviews/64.png @path %}){: class="img-responsive"}

Seleccionamos la **"Tijera"** (en la parte superior de la pantalla a la derecha) nos muestra los objetivos de control por proceso en color celeste que no fueron incorporados en el informe (los cuales se encuentran cargados en la buena práctica).

![]({% asset execution/reviews/65.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad **¨Recodificar observaciones por reiteración y riesgo¨**

**Ejecución -> Informes**

Hay una nueva opción para recodificar observaciones desde los informes: "Recodificar observaciones por reiteración y riesgo".

Permite reasignar los códigos de observaciones por reiteración y riesgo. Toma primero las reiteradas (ordenadas por riesgo alto, medio, bajo) y luego las nuevas (ordenadas por riesgo alto, medio, bajo).

Seleccionamos "Editar" en un informe, al final de la pantalla seleccionamos “Acciones”.

![]({% asset execution/reviews/66.png @path %}){: class="img-responsive"}

Seleccionamos "Recodificar observaciones por reiteración y riesgo"

![]({% asset execution/reviews/67.png @path %}){: class="img-responsive"}

Seleccionamos "Aceptar", nos muestra el mensaje “Hallazgos recodificados correctamente” y las observaciones ordenadas primero por reiterada teniendo en cuenta el riesgo (alto, medio, bajo) y luego las observaciones nuevas teniendo en cuenta el riesgo (alto, medio, bajo).

![]({% asset execution/reviews/68.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad **¨Recodificar observaciones por orden objetivos de control¨**.

**Ejecución -> Informes**

Hay una nueva opción para recodificar observaciones desde los informes: "Recodificar observaciones por orden objetivos de control".

Toma el orden en el que están definidos los objetivos de control dentro del informe y recodifica las observaciones en el mismo. Si hubiera más de una observación dentro del objetivo las ordena por riesgo (alto, medio, bajo).

Seleccionamos "Editar" en un informe, al final de la pantalla seleccionamos “Acciones”.

![]({% asset execution/reviews/69.png @path %}){: class="img-responsive"}

Seleccionamos "Recodificar observaciones por orden objetivos de control"

![]({% asset execution/reviews/70.png @path %}){: class="img-responsive"}

Seleccionamos "Aceptar", nos muestra el mensaje “Hallazgos recodificados correctamente”  y las observaciones ordenadas por objetivos de control como están en el informe y por riesgo (alto, medio, bajo).

![]({% asset execution/reviews/71.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos la funcionalidad **¨Notificaciones por modificación de integrantes¨**.

**Ejecución -> Informes**

En el caso que existan cambios en los integrantes de un informe, a partir de ahora no se va notificar de los cambios realizados a los integrantes.

Solo se notifica del cambio de integrantes en el siguiente caso puntual:

En las notificaciones por modificación de integrantes del informe quedó solo una que nos pareció "útil".

Se da en un caso super puntual: tienen que editar el nombre de un integrante (sería, seleccionar el nombre, borrarlo y buscar uno nuevo en el mismo campo de texto) y el informe tiene que tener observaciones en estado **"No confirmada"**.

En este caso se reasignan todas las observaciones del informe al nuevo miembro y se desafecta al anterior, por lo que notifica que eso se hizo para cada observación en este estado. Como para las observaciones no confirmadas ya se envió la notificación, si no es así el nuevo usuario no se daría por enterado hasta que llegue la notificación de paso a "Sin respuesta".

A continuación mostramos un ejemplo:

Este es el informe (tiene una observación en estado "No confirmada" con los integrantes:

![]({% asset execution/reviews/72.png @path %}){: class="img-responsive"}

Esta es la observación correspondiente al informe en estado "No Confirmada".

![]({% asset execution/reviews/73.png @path %}){: class="img-responsive"}

Vamos a cambiar el integrante: Moralejo Raúl (Auditor) por Martinez Jose (Auditor). En este caso va generar una notificación a ambos auditores:

![]({% asset execution/reviews/74.png @path %}){: class="img-responsive"}

Seleccionamos "Actualizar informe"

![]({% asset execution/reviews/75.png @path %}){: class="img-responsive"}

Luego nos llega un correo, con la reasignación de las observaciones del informe al nuevo miembro y se desafecta al anterior.

![]({% asset execution/reviews/76.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos un nuevo reporte **"Resumen de costos planificados"**.

**Ejecución -> Reportes -> Resumen de costos planificados**

Seleccionamos **"Resumen de costos planificados"**.

![]({% asset execution/reviews/77.png @path %}){: class="img-responsive"}

Muestra las unidades estimadas por recurso y período (según el rango de fecha ingresado en el filtro).

Toma la cantidad de días del intervalo, ve proporcionalmente cuanto corresponde a cada mes y reparte las horas. Por ejemplo: 3 horas entre el 1/3  y el 7/4, sería 2,46 (0,82\*3\) en marzo y 0,54 (0,18\*3\) en abril.

La fecha que se utiliza en el filtro es la de inicio de proyecto (la que se carga en el plan, en la columna "Inicio").

![]({% asset execution/reviews/78.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Nuevas vista de reportes.

Incorporamos una nueva funcionalidad para los reportes de informes.

Para verlo tienen que ir a la ¨Lupa¨ de cualquier informe dentro de "Ejecución" y al final van a tener una nueva opción "Descargar".

Muestra los datos del informe: identificación, periodo, proyecto, unidad de negocio, tipo de auditoría, relevamiento, integrantes, y luego para cada objetivo de control seleccionado para el alcance los datos completos de la buena práctica y los resultados obtenidos en la auditoría.

Es un reporte completo para poder ver de una manera rápida todo lo realizado para esa auditoría.

Seleccionamos **Ejecución -> Informes**

![]({% asset execution/reviews/79.png @path %}){: class="img-responsive"}

Seleccionamos la  **"Lupa"** del informe que necesitamos los datos.

![]({% asset execution/reviews/80.png @path %}){: class="img-responsive"}

Luego van al final de la pantalla tenemos la opción ¨Descargar¨ para verlo en formato PDF.

![]({% asset execution/reviews/81.png @path %}){: class="img-responsive"}

Si seleccionamos ¨Descargar¨

En la primera página nos muestra la identificación y proyecto.

![]({% asset execution/reviews/82.png @path %}){: class="img-responsive"}

Y a partir de la segunda el detalle de los datos de cada uno de los campos

![]({% asset execution/reviews/83.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos para Identificar cambios en el nombre de un objetivo de control cargado en una buena práctica.

Poder diferenciar cuando el nombre de un objetivo de control mantiene el texto original de la buena práctica en la edición de un informe en ¨Ejecución¨.

Cuando hay un cambio se muestra una advertencia, el mismo icono es un enlace, si hacemos click (previo a una pregunta) nos trae el texto original del objetivo tal cual está definido en la buena práctica.

Seleccionamos **Ejecución -> Informes**

Seleccionamos ¨Editar¨ de un informe, en aquellos objetivos de control que hay un cambio nos muestra una advertencia (el triángulo).

![]({% asset execution/reviews/84.png @path %}){: class="img-responsive"}

Si posicionamos el mouse encima del triángulo (para el objetivo de control 3.1.1 - Dependencia del Responsable de área) informa el siguiente mensaje **¨El nombre del objetivo de control ha cambiado respecto el definido en la buena práctica, haga click para restaurarlo¨**.

Si hacemos click en el triángulo nos muestra el siguiente mensaje:

![]({% asset execution/reviews/85.png @path %}){: class="img-responsive"}

Si seleccionamos ¨Aceptar¨ nos trae el texto original del objetivo tal cual está definido en la buena práctica.

En este caso lo hicimos para el objetivo de control 3.1.1 - Dependencia del Responsable del área.

![]({% asset execution/reviews/86.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos **¨Controles opcionales para crear una observación¨**..

Cuando no se ha seleccionado a nadie como responsable y/o referente van a ver un mensaje "No ha seleccionado auditores referentes ni responsables ¿Desea continuar?". En caso que acepten se crea la observación, en caso que cancelen vuelven a la pantalla de edición. Solo se habilita cuando crean una observación.

**Ejecución -> Informes**

Seleccionamos "Informes", luego ¨Editar¨ en un informe, seleccionamos un objetivo de control, luego  agregar una observación.

![]({% asset execution/reviews/87.png @path %}){: class="img-responsive"}

Seleccionamos ¨Crear observación¨.

![]({% asset execution/reviews/88.png @path %}){: class="img-responsive"}

Seleccionamos cancelar, agregamos el auditor referente y el auditado responsable.

![]({% asset execution/reviews/89.png @path %}){: class="img-responsive"}

Seleccionamos ¨Crear observación¨.

![]({% asset execution/reviews/90.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la opción para los supervisores y gerentes de auditoría para la **¨Firma del informe¨**.

**Ejecución -> Informes**

Seleccionamos "Informes", luego ¨Nuevo¨.

En la actualidad se toma el rol que figura cuando agregan un usuario dentro de ¨Integrantes¨ cuando crean un informe en ¨Ejecución¨ -> ¨Informes¨.

Ahora, muestra un desplegable con la opción ¨Responsable máximo de auditoría¨ tanto para supervisores como para gerentes.

![]({% asset execution/reviews/91.png @path %}){: class="img-responsive"}
