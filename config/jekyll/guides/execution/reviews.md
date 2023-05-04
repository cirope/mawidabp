---
title: Informes
layout: articles
category: execution
guide_order: 3
article_order: 2
has_children: true
---
# Ejecución

## Informes

Seleccionamos **Ejecución -> Informes**

Muestra los informes generados hasta el momento.

![image]({{ site.baseurl }}/assets/images/execution/reviews/1.png){: class="img-responsive"}

Seleccionamos **Nuevo** para dar el alta un informe, aparece la siguiente pantalla para completar.

![image]({{ site.baseurl }}/assets/images/execution/reviews/2.png){: class="img-responsive"}

Identificación: podemos utilizar la nomenclatura adoptada por la organización (letras, números, guiones, etc.)

Seleccionar período y proyecto: son datos cargados en la etapa anterior (planificación).

Muestra la unidad de negocio y el tipo de auditoría: son los datos cargados en la etapa anterior (planificación).

Integrante

* Son las personas que participan del informe, como mínimo tenemos que tener el rol auditor, supervisor y auditado, o auditor, gerente de auditoría y auditado.

* Rol, muestra el rol del integrante

* Incluir firma, al tildar seleccionamos los integrantes que luego aparecen en la firma del informe borrador y/o definitivo en la última página.

* Responsable, al tillar seleccionamos los integrantes que aparecen en la primera hoja del informe borrador y/o definitivo indicando que son responsables.

Etiqueta

* Agregar etiquetas, se muestran las creadas en la etapa de Administración - Etiquetas, podemos seleccionar la más conveniente para identificar al informe.

Objetivo de control

* Seleccionamos los objetivos de control que necesitamos controlar en este informe (los mismos fueron cargados en la etapa de administración - buenas prácticas).

Proceso

* También podemos seleccionar un proceso o varios procesos, los cuales fueron cargado en la etapa de administración - buenas prácticas.

Buena práctica

* También podemos seleccionar una o varias buenas prácticas, la misma fue cargada en la etapa de administración - buenas prácticas.

<hr>

&nbsp;

&nbsp;

Hallazgos pendientes

Agregar hallazgo pendiente

* Al seleccionar esta opción, nos permite incorporar un texto (letras o números), con los cuales va a buscar en la base de datos del sistema y muestra los hallazgos pendientes que tengan alguna letra o número que coincida con lo que ingresamos, tenemos la posibilidad de seleccionar uno de los propuestos, luego podemos seguir buscando e incorporando de uno los que necesitamos para este informe

Sugerir hallazgos pendientes

* Al seleccionar esta opción nos muestra los hallazgos pendientes de toda la organización para la unidad organizativa que tenemos seleccionada, tenemos la posibilidad de seleccionar cuales nos interesan eliminando los que no necesitamos para este informe.

Sugerir hallazgos solucionados recientes

* Al seleccionar esta opción nos muestra los hallazgos solucionados recientes de toda la organización para la unidad organizativa que tenemos seleccionada, tenemos la posibilidad de seleccionar cuales nos interesan eliminando los que no necesitamos para este informe.

Descripción

El texto incluido en esta parte, formará parte del título del informe borrador y definitivo.

Relevamiento

Opcionalmente podemos completar el campo relevamiento y/o subir algún archivo que consideremos importante como anexo al informe.

A continuación mostramos la pantalla con los datos cargados para un informe.

![image]({{ site.baseurl }}/assets/images/execution/reviews/3.png){: class="img-responsive"}
![image]({{ site.baseurl }}/assets/images/execution/reviews/4.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

* Incluir firma (podemos seleccionar, es opcional, al tildar seleccionamos los integrantes que luego aparecen en la firma del informe borrador y/o definitivo en la última página).

* Responsable (podemos seleccionar, es opcional, al tillar seleccionamos los integrantes que aparecen en la primera hoja del informe borrador y/o definitivo indicando que son responsables)

![image]({{ site.baseurl }}/assets/images/execution/reviews/5.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la posibilidad de seleccionar etiquetas, se pueden agregar etiquetas para identificar alguna característica que nos interese del informe.

![image]({{ site.baseurl }}/assets/images/execution/reviews/6.png){: class="img-responsive"}

Para guardar los datos seleccionamos **¨Crear informe**¨, si todo está bien nos muestra la siguiente pantalla (en caso de inconvenientes nos da un mensaje con los errores encontrados, los cuales podemos ir solucionando hasta que nos permite crear el informe).

![image]({{ site.baseurl }}/assets/images/execution/reviews/7.png){: class="img-responsive"}

Luego podemos ver el informe generado seleccionado **Ejecución -> Informes**, es el primero que aparece en la lista.

![image]({{ site.baseurl }}/assets/images/execution/reviews/8.png){: class="img-responsive"}

Luego de crear el informe, podemos iniciar las siguientes actividades para cada uno de los objetivos de control que se encuentran en el informe creado (en este caso tenemos 2 objetivos de control: 5.2 Inventario tecnológico y 5.1 Responsabilidad del área):

* Analizar y evaluar el control interno.

* Efectuar pruebas (evaluación de diseño, pruebas de cumplimiento, pruebas sustantivas).

Para iniciar y realizar estas actividades el sistema brinda dos alternativas:

* Opción 1 Informes -> Editar

* Opción 2 Objetivos de control -> Editar


<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad "Hallazgos pendientes".

**Ejecución -> Informes**

Seleccionamos "Editar" en un informe.

![image]({{ site.baseurl }}/assets/images/execution/reviews/41.png){: class="img-responsive"}

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

![image]({{ site.baseurl }}/assets/images/execution/reviews/42.png){: class="img-responsive"}

![image]({{ site.baseurl }}/assets/images/execution/reviews/43.png){: class="img-responsive"}

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

![image]({{ site.baseurl }}/assets/images/execution/reviews/44.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad que permite ordenar los informes de una manera más simple y luego alternativas de buscar.

**Ejecución -> Informes**

El orden de los informes en ejecución muestra primero los sin definitivo, luego los que tienen definitivo, ordenados por identificación en cada caso.

![image]({{ site.baseurl }}/assets/images/execution/reviews/45.png){: class="img-responsive"}

Luego podemos seleccionar "Buscar", para que les permita ordenar tanto de forma ascendente como descendente.

Seleccionamos "Buscar", muestra “Ordenar por”, seleccionamos esta opción y muestra: Identificación Ascendente, Identificación descendente, Período Ascendente, Período Descendente”, seleccionamos “Identificación Ascendente”, luego  “Buscar”.

![image]({{ site.baseurl }}/assets/images/execution/reviews/46.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad que permite separar por roles **¨Auditoría** ((auditores) y **¨Usuarios¨** ( auditados) los integrantes de un informe.

**Ejecución -> Informes**

En los informes en ejecución ahora se separa el equipo de auditoría del resto de los roles "Auditoría" y “Usuarios”. Además, cuando se selecciona un usuario, el “Rol” que se despliega es solo posible para la persona elegida.

![image]({{ site.baseurl }}/assets/images/execution/reviews/47.png){: class="img-responsive"}

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

![image]({{ site.baseurl }}/assets/images/execution/reviews/48.png){: class="img-responsive"}

Si seleccionamos "Papeles de trabajo - Conforme Auditor", nos muestra la siguiente pantalla

![image]({{ site.baseurl }}/assets/images/execution/reviews/49.png){: class="img-responsive"}

Si seleccionamos OK, muestra la siguiente pantalla

![image]({{ site.baseurl }}/assets/images/execution/reviews/50.png){: class="img-responsive"}

Una vez realizada, en el listado de informes figura un icono "clip", pasando sobre el mismo está la leyenda "Papeles de trabajo marcados como conforme auditor".

![image]({{ site.baseurl }}/assets/images/execution/reviews/51.png){: class="img-responsive"}

Lo mismo cuando se edita o visualiza desde la lupa el informe, la leyenda se muestra al final de la página en un recuadro celeste.

![image]({{ site.baseurl }}/assets/images/execution/reviews/52.png){: class="img-responsive"}

**Ejecución -> Informes -> "Papeles de trabajo - Revisado auditor"**

En conjunto con la anterior se agregó una opción en los informes en ejecución dentro de "Acciones", "Papeles de trabajo - Revisado supervisor" (**solo visible para los usuarios supervisores cuando está marcado con la opción anterior**).

![image]({{ site.baseurl }}/assets/images/execution/reviews/53.png){: class="img-responsive"}

En caso que agreguemos o modifiquemos un papel de trabajo existente, se "desmarca" el conforme auditor (incluso si estaba supervisado).

**Ejecución -> Reportes -> "Informes cerrados sin conformidad auditor"**

También en conjunto con lo anterior, se agregó un nuevo reporte en "Ejecución" -> "Reportes" -> "Informes cerrados sin conformidad auditor" (lista los "informes cerrados sin conformidad auditor" e “informes cerrados sin revisión supervisor”).

![image]({{ site.baseurl }}/assets/images/execution/reviews/54.png){: class="img-responsive"}

Si seleccionamos "Informes cerrados sin conformidad auditor", se pueden listar los "informes cerrados sin conformidad auditor" e “informes cerrados sin revisión supervisor”.

![image]({{ site.baseurl }}/assets/images/execution/reviews/55.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad que permite tener en cuenta el estado **¨Riesgo asumido¨** en las búsquedas de observaciones pendientes.

**Ejecución -> Informes**

Para la sugerencia de observaciones pendientes dentro de  "Ejecución" -> "Informes" ahora se tienen en cuenta el estado "Riesgo asumido".

![image]({{ site.baseurl }}/assets/images/execution/reviews/56.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Para mostrar datos, agregamos el campo **"Auditoría"**, el cual nos muestra a los auditores (con un icono para cada uno), se permite utilizar la columna para las búsquedas utilizando el apellido. Si posicionamos el mouse sobre una de los iconos nos muestra el Apellido y nombre del auditor.

**Ejecución -> Informes**

Seleccionamos "Informes" nos muestra los informes.

![image]({{ site.baseurl }}/assets/images/execution/reviews/57.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Muestra los informes que tienen **¨informe definitivos tachados¨**.

**Ejecución -> Informes**

Los informes que se encuentran tachados tienen informe definitivo.

![image]({{ site.baseurl }}/assets/images/execution/reviews/58.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Se agregó la opción "Sugerir hallazgos relacionados recientes" en los informes de ejecución.

**Ejecución -> Informes**

Se agregó la opción "Sugerir hallazgos relacionados recientes" en los informes de ejecución. Esta opción busca los hallazgos en estado "Implementada/Auditada" de los últimos tres años.

![image]({{ site.baseurl }}/assets/images/execution/reviews/59.png){: class="img-responsive"}

En caso que no existan hallazgos muestra la siguiente pantalla:

![image]({{ site.baseurl }}/assets/images/execution/reviews/60.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Se agregó la opción **"Recodificar hallazgos por riesgo"**.

**Ejecución -> Informes**

Se agregó la opción "Recodificar hallazgos por riesgo" dentro de "Acciones" de los informes en ejecución. Básicamente ordena las hallazgos de mayor a menor por riesgo y como segundo campo el código del hallazgo.

Las observaciones se pueden recodificar por riesgo dentro de la edición en "Acciones".

Seleccionamos "Editar" en un informe, al final de la pantalla seleccionamos “Acciones”. “Recodificar hallazgos por riesgo”.

![image]({{ site.baseurl }}/assets/images/execution/reviews/61.png){: class="img-responsive"}

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

![image]({{ site.baseurl }}/assets/images/execution/reviews/62.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos **¨mostrar los objetivos de control de una buena práctica no incluidos en el informe¨**.

**Ejecución -> Informes**

Dentro de la edición de un informe, a la derecha del título "Objetivos de control" hay un icono representando una "tijera", al hacer clic muestra los objetivos de control que están en la buena práctica pero no incluidos en el informe (sería los que se "quedaron afuera" o no fueron seleccionados para incorporar en el alcance del trabajo).

Seleccionamos "Ejecución" -> "Informes".

![image]({{ site.baseurl }}/assets/images/execution/reviews/63.png){: class="img-responsive"}

Luego "Editar" por ejemplo “Ejercicio 2017” “2017 TI 01 5”.

![image]({{ site.baseurl }}/assets/images/execution/reviews/64.png){: class="img-responsive"}

Seleccionamos la **"Tijera"** (en la parte superior de la pantalla a la derecha) nos muestra los objetivos de control por proceso en color celeste que no fueron incorporados en el informe (los cuales se encuentran cargados en la buena práctica).

![image]({{ site.baseurl }}/assets/images/execution/reviews/65.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad **¨Recodificar observaciones por reiteración y riesgo¨**

**Ejecución -> Informes**

Hay una nueva opción para recodificar observaciones desde los informes: "Recodificar observaciones por reiteración y riesgo".

Permite reasignar los códigos de observaciones por reiteración y riesgo. Toma primero las reiteradas (ordenadas por riesgo alto, medio, bajo) y luego las nuevas (ordenadas por riesgo alto, medio, bajo).

Seleccionamos "Editar" en un informe, al final de la pantalla seleccionamos “Acciones”.

![image]({{ site.baseurl }}/assets/images/execution/reviews/66.png){: class="img-responsive"}

Seleccionamos "Recodificar observaciones por reiteración y riesgo"

![image]({{ site.baseurl }}/assets/images/execution/reviews/67.png){: class="img-responsive"}

Seleccionamos "Aceptar", nos muestra el mensaje “Hallazgos recodificados correctamente” y las observaciones ordenadas primero por reiterada teniendo en cuenta el riesgo (alto, medio, bajo) y luego las observaciones nuevas teniendo en cuenta el riesgo (alto, medio, bajo).

![image]({{ site.baseurl }}/assets/images/execution/reviews/68.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad **¨Recodificar observaciones por orden objetivos de control¨**.

**Ejecución -> Informes**

Hay una nueva opción para recodificar observaciones desde los informes: "Recodificar observaciones por orden objetivos de control".

Toma el orden en el que están definidos los objetivos de control dentro del informe y recodifica las observaciones en el mismo. Si hubiera más de una observación dentro del objetivo las ordena por riesgo (alto, medio, bajo).

Seleccionamos "Editar" en un informe, al final de la pantalla seleccionamos “Acciones”.

![image]({{ site.baseurl }}/assets/images/execution/reviews/69.png){: class="img-responsive"}

Seleccionamos "Recodificar observaciones por orden objetivos de control"

![image]({{ site.baseurl }}/assets/images/execution/reviews/70.png){: class="img-responsive"}

Seleccionamos "Aceptar", nos muestra el mensaje “Hallazgos recodificados correctamente”  y las observaciones ordenadas por objetivos de control como están en el informe y por riesgo (alto, medio, bajo).

![image]({{ site.baseurl }}/assets/images/execution/reviews/71.png){: class="img-responsive"}

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

![image]({{ site.baseurl }}/assets/images/execution/reviews/72.png){: class="img-responsive"}

Esta es la observación correspondiente al informe en estado "No Confirmada".

![image]({{ site.baseurl }}/assets/images/execution/reviews/73.png){: class="img-responsive"}

Vamos a cambiar el integrante: Moralejo Raúl (Auditor) por Martinez Jose (Auditor). En este caso va generar una notificación a ambos auditores:

![image]({{ site.baseurl }}/assets/images/execution/reviews/74.png){: class="img-responsive"}

Seleccionamos "Actualizar informe"

![image]({{ site.baseurl }}/assets/images/execution/reviews/75.png){: class="img-responsive"}

Luego nos llega un correo, con la reasignación de las observaciones del informe al nuevo miembro y se desafecta al anterior.

![image]({{ site.baseurl }}/assets/images/execution/reviews/76.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos un nuevo reporte **"Resumen de costos planificados"**.

**Ejecución -> Reportes -> Resumen de costos planificados**

Seleccionamos **"Resumen de costos planificados"**.

![image]({{ site.baseurl }}/assets/images/execution/reviews/77.png){: class="img-responsive"}

Muestra las unidades estimadas por recurso y período (según el rango de fecha ingresado en el filtro).

Toma la cantidad de días del intervalo, ve proporcionalmente cuanto corresponde a cada mes y reparte las horas. Por ejemplo: 3 horas entre el 1/3  y el 7/4, sería 2,46 (0,82\*3\) en marzo y 0,54 (0,18\*3\) en abril.

La fecha que se utiliza en el filtro es la de inicio de proyecto (la que se carga en el plan, en la columna "Inicio").

![image]({{ site.baseurl }}/assets/images/execution/reviews/78.png){: class="img-responsive"}

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

![image]({{ site.baseurl }}/assets/images/execution/reviews/79.png){: class="img-responsive"}

Seleccionamos la  **"Lupa"** del informe que necesitamos los datos.

![image]({{ site.baseurl }}/assets/images/execution/reviews/80.png){: class="img-responsive"}

Luego van al final de la pantalla tenemos la opción ¨Descargar¨ para verlo en formato PDF.

![image]({{ site.baseurl }}/assets/images/execution/reviews/81.png){: class="img-responsive"}

Si seleccionamos ¨Descargar¨

En la primera página nos muestra la identificación y proyecto.

![image]({{ site.baseurl }}/assets/images/execution/reviews/82.png){: class="img-responsive"}

Y a partir de la segunda el detalle de los datos de cada uno de los campos

![image]({{ site.baseurl }}/assets/images/execution/reviews/83.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos para Identificar cambios en el nombre de un objetivo de control cargado en una buena práctica.

Poder diferenciar cuando el nombre de un objetivo de control mantiene el texto original de la buena práctica en la edición de un informe en ¨Ejecución¨.

Cuando hay un cambio se muestra una advertencia, el mismo icono es un enlace, si hacemos click (previo a una pregunta) nos trae el texto original del objetivo tal cual está definido en la buena práctica.

Seleccionamos **Ejecución -> Informes**

Seleccionamos ¨Editar¨ de un informe, en aquellos objetivos de control que hay un cambio nos muestra una advertencia (el triángulo).

![image]({{ site.baseurl }}/assets/images/execution/reviews/84.png){: class="img-responsive"}

Si posicionamos el mouse encima del triángulo (para el objetivo de control 3.1.1 - Dependencia del Responsable de área) informa el siguiente mensaje **¨El nombre del objetivo de control ha cambiado respecto el definido en la buena práctica, haga click para restaurarlo¨**.

Si hacemos click en el triángulo nos muestra el siguiente mensaje:

![image]({{ site.baseurl }}/assets/images/execution/reviews/85.png){: class="img-responsive"}

Si seleccionamos ¨Aceptar¨ nos trae el texto original del objetivo tal cual está definido en la buena práctica.

En este caso lo hicimos para el objetivo de control 3.1.1 - Dependencia del Responsable del área.

![image]({{ site.baseurl }}/assets/images/execution/reviews/86.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos **¨Controles opcionales para crear una observación¨**..

Cuando no se ha seleccionado a nadie como responsable y/o referente van a ver un mensaje "No ha seleccionado auditores referentes ni responsables ¿Desea continuar?". En caso que acepten se crea la observación, en caso que cancelen vuelven a la pantalla de edición. Solo se habilita cuando crean una observación.

**Ejecución -> Informes**

Seleccionamos "Informes", luego ¨Editar¨ en un informe, seleccionamos un objetivo de control, luego  agregar una observación.

![image]({{ site.baseurl }}/assets/images/execution/reviews/87.png){: class="img-responsive"}

Seleccionamos ¨Crear observación¨.

![image]({{ site.baseurl }}/assets/images/execution/reviews/88.png){: class="img-responsive"}

Seleccionamos cancelar, agregamos el auditor referente y el auditado responsable.

![image]({{ site.baseurl }}/assets/images/execution/reviews/89.png){: class="img-responsive"}

Seleccionamos ¨Crear observación¨.

![image]({{ site.baseurl }}/assets/images/execution/reviews/90.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la opción para los supervisores y gerentes de auditoría para la **¨Firma del informe¨**.

**Ejecución -> Informes**

Seleccionamos "Informes", luego ¨Nuevo¨.

En la actualidad se toma el rol que figura cuando agregan un usuario dentro de ¨Integrantes¨ cuando crean un informe en ¨Ejecución¨ -> ¨Informes¨.

Ahora, muestra un desplegable con la opción ¨Responsable máximo de auditoría¨ tanto para supervisores como para gerentes.

![image]({{ site.baseurl }}/assets/images/execution/reviews/91.png){: class="img-responsive"}
