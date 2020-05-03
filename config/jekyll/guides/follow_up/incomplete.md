---
title: Hallazgos pendientes
layout: articles
category: follow_up
guide_order: 5
article_order: 2
---
# Seguimiento

## Hallazgos pendientes

Seleccionamos **Seguimiento -> Hallazgos pendientes**, nos muestra la siguiente pantalla.

![]({% asset follow_up/incomplete-1.png @path %}){: class="img-responsive"}

Podemos ¨**Descargar CSV**¨ y ¨**Resumen en PDF**¨ todos los hallazgos pendientes.

Tenemos las opciones de ¨**Ver**¨ y ¨**Editar**¨ para cada uno de los hallazgos.

Seleccionamos ¨**Ver**¨ del hallazgo que se encuentra en la segunda fila ¨**2018 TI 01 2**¨ nos permite ver los datos del hallazgo.

![]({% asset follow_up/incomplete-2.png @path %}){: class="img-responsive"}

![]({% asset follow_up/incomplete-3.png @path %}){: class="img-responsive"}

Tenemos las opciones de ¨**Editar**¨, ¨**Descargas**¨ y seleccionando ¨**Listado**¨ nos lleva a la pantalla principal de hallazgos pendientes.

Seleccionamos¨**Descargas**¨ nos muestra

![]({% asset follow_up/incomplete-4.png @path %}){: class="img-responsive"}

Si seleccionamos ¨**Descargar Seguimiento**¨, nos permite descargar un documento pdf con los datos más importantes del seguimiento del hallazgo realizado a la fecha (no tiene los apartados de Historial de cambios y comentarios de seguimiento, y agregamos la columna ¨Etiquetas¨).

![]({% asset follow_up/incomplete-5.png @path %}){: class="img-responsive"}

Si seleccionamos ¨**Descargar Seguimiento completo**¨, nos permite descargar un documento pdf con todos los datos del hallazgo a la fecha.

![]({% asset follow_up/incomplete-6.png @path %}){: class="img-responsive"}

![]({% asset follow_up/incomplete-7.png @path %}){: class="img-responsive"}

Seleccionamos ¨**Listado**¨ nos muestra la pantalla principal

![]({% asset follow_up/incomplete-8.png @path %}){: class="img-responsive"}

Seleccionamos ¨**Editar**¨ del hallazgo que se encuentra en la segunda fila ¨**2018 TI 01 2**¨ nos permite ver el detalle del hallazgo

Esta parte es el escritorio de trabajo del auditor y auditado.  Permite por medio de comentarios interactuar entre auditor y auditado. Aumenta la comunicación entre los responsables del seguimiento y los responsables de la solución. En todo momento se puede conocer el grado de avance, fecha probable de regularización, papeles de trabajo adjuntos, tareas y otros datos pertinentes. Además, el sistema provee un indicador de tiempo dedicado por parte de los usuarios relacionados a cada hallazgo (esta parte es de uso opcional).

El usuario auditor puede agregar un comentario, luego selecciona **Actualizar observación**, luego el sistema pasa un correo electrónico en forma inmediata a los auditores y auditados que están incorporados en la observación (al que agrego el comentario no le llega el correo).

De esta manera podemos observar que el sistema brinda la posibilidad que exista un diálogo permanente por medio de comentarios entre los participantes de la observación (auditor y auditados). En estos comentarios se pueden adjuntar documentos como evidencia para la solución de la observación.

El auditado no puede modificar los datos de la observación.

El auditor si puede ir modificando los datos de la observación (estado, respuestas, fechas, etc.) hasta llegar a la solución de la misma.

En caso que no llegue a solucionarse la observación, queda todo el registro con la trazabilidad de las tareas realizadas, al igual que si se soluciona.

![]({% asset follow_up/incomplete-9.png @path %}){: class="img-responsive"}

![]({% asset follow_up/incomplete-10.png @path %}){: class="img-responsive"}

![]({% asset follow_up/incomplete-11.png @path %}){: class="img-responsive"}

Podemos ¨**Ver**¨, ¨**Descargas**¨ y seleccionar ¨**Listado**¨ para volver a la pantalla principal hallazgos pendientes.

Si seleccionamos ¨Descargas¨, podemos descargar el seguimiento.

![]({% asset follow_up/incomplete-12.png @path %}){: class="img-responsive"}

Si seleccionamos ¨**Descargar Seguimiento**¨, nos permite descargar un documento pdf con los datos más importantes del seguimiento del hallazgo realizado a la fecha (no tiene los apartados de Historial de cambios y comentarios de seguimiento, y agregamos la columna ¨Etiquetas¨).

Si seleccionamos ¨**Descargar Seguimiento completo**¨, nos permite descargar un documento pdf con todos los datos del hallazgo a la fecha.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Agregamos filtros para búsquedas más eficientes.

Seleccionamos **Seguimiento -> Hallazgos pendientes**

Se agregó en "Ordenar por"

![]({% asset follow_up/incomplete-13.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos el ordenamiento por default.

**Seguimiento -> Hallazgos pendientes**

Para la vista de **"Hallazgos Pendientes"** (por default): se ordenan los hallazgos desde la fecha de implementación más antigua a la más reciente

![]({% asset follow_up/incomplete-14.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la carga de datos **"Tiempo dedicado"** para la solución de una observación y/o oportunidad de mejora en el seguimiento, no es obligatorio cargarlo (es opcional).

Seleccionamos **Seguimiento -> Hallazgos pendientes**

![]({% asset follow_up/incomplete-15.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporación de búsqueda por Etiqueta, exportar a CSV y emitir listado PDF

Desde "Seguimiento" se pueden consultar las observaciones por "Etiqueta", se pueden exportar a CSV y emitir un listado PDF.

Por ejemplo, utilizar para identificar aquellas observaciones que se han reprogramado y que luego hay que transcribir al acta de comité de auditoría. Se las puede identificar (filtrar en la búsqueda e identificarlas en el CSV).

Quedó implementada en el listado de "Seguimiento" (tanto pendientes como solucionados).

En el caso del CSV se exportan, quedan separadas por coma, excepto la última que se une con una "y". Por ejemplo, si tiene la etiqueta A, la etiqueta B y la etiqueta C, quedaría así: A, B y C.

En el caso "Resumen PDF", se genera un reporte que contiene las observaciones que están en el filtro y que contiene sólo aquellos campos que no varían en el tiempo, como por ejemplo: Informe, Codigo, Buena práctica, Proceso, Título (en el listado muestra el filtro aplicado para emitir el listado). Además agregamos el título, dependiendo de donde se baja por "Hallazgos pendientes" y "Hallazgos solucionados"

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejora en los filtros para búsquedas más eficientes.

Seleccionamos **Seguimiento -> Hallazgos pendientes**

En el caso de las búsquedas se pueden "desactivar" las columnas por las que no se quiere buscar.

Si hacen clic sobre el nombre de la columna que no necesitan buscar (por ejemplo ¨Proyecto¨),  van a ver que cambia a un tono más claro (**se torna de un color gris**), eso quiere decir que no se va a tener en cuenta para la búsqueda.

Las columnas que se encuentran tachadas, tampoco se tienen en cuenta para la búsqueda.

![]({% asset follow_up/incomplete-16.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos al CSV una columna con el número de observación interno, a la derecha del código, bajo el título "Id".

Seleccionamos **Seguimiento -> Hallazgos pendientes**

Seleccionar **"Descargar CSV"**

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos al CSV el número de acta.

Seleccionamos **Seguimiento -> Hallazgos pendientes"**

En el CSV de seguimiento de observaciones se incluye el número de acta, también en el listado si posan el puntero sobre el número de informe.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos como se muestra la columna ¨Fecha de implementación¨.

Seleccionamos **Seguimiento -> Hallazgos pendientes**

Ahora en el listado se muestra resaltada la columna "Fecha de implementación", para observaciones "En proceso de implementación". Cuando las observaciones tienen esta fecha en el pasado, además del tachado ahora se muestran resaltadas en rojo.

![]({% asset follow_up/incomplete-17.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos nuevas columnas en el CSV.

Seleccionamos **Seguimiento -> Hallazgos pendientes**

Agregamos nuevas columnas al CSV: unidad organizativa, unidad de negocio, recomendaciones de auditoría y Reprogramada.

Seleccionamos ¨**Descargar CSV**¨.

![]({% asset follow_up/incomplete-18.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Realizamos mejoras con el objetivo que el auditado no tenga confusiones al momento de responder un comentario para el auditor.

Seleccionamos **Seguimiento -> Hallazgos pendientes**

La columna de la derecha quedó para ingresar la fecha de compromiso.

A continuación mostramos un ejemplo con la pantalla que ve el auditado (Carrizo Juan) al recibir una notificación del auditor (Cuenca Francisco).

![]({% asset follow_up/incomplete-19.png @path %}){: class="img-responsive"}

El auditado (Carrizo Juan) ingresa un comentario y la fecha de compromiso.

![]({% asset follow_up/incomplete-20.png @path %}){: class="img-responsive"}

Luego debe seleccionar **"Actualizar observación"**, para que lleguen los correos a los usuarios auditores y auditados involucrados en la observación con el comentario ingresado.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la posibilidad de consultar las observaciones **¨Pendientes¨** de múltiples usuarios seleccionados previamente

Primero deben ir al listado de usuarios en "Administración" -> "Seguridad"  -> "Usuarios". Van a ver un nuevo icono que representa un gráfico de barras, es un enlace más directo al "Estado" de cada usuario.

![]({% asset follow_up/incomplete-21.png @path %}){: class="img-responsive"}

Seleccionamos el icono "gráfico de barras", dentro del estado a la derecha del nombre del usuario van a ver un icono con un "+". La idea aquí sería agregarlo a una especie de "Carrito" (icono lista) similar al que se utiliza cuando uno realiza una compra online.

![]({% asset follow_up/incomplete-22.png @path %}){: class="img-responsive"}

Seleccionamos "+", una vez agregado van a ver que el icono cambia por un "-", que funciona para eliminarlo del carrito, a su vez aparece un nuevo icono que representa una lista.

![]({% asset follow_up/incomplete-23.png @path %}){: class="img-responsive"}

Pueden repetir la operación con los usuarios que crean necesario, el carrito va manteniendo la lista con las observaciones pendientes de los usuarios que vamos seleccionando (a la lista se van sumando las observaciones de los usuarios seleccionados).

![]({% asset follow_up/incomplete-24.png @path %}){: class="img-responsive"}

Para este ejemplo llevamos 2 usuarios seleccionados.

Una vez que tenemos todos los usuarios seleccionados que necesitamos listar, recién ahí hacemos clic en el icono de la lista (desde cualquiera de ellos, cuando nos posicionamos en la lista con el mouse muestra el mensaje "Ver lista de observaciones pendientes de los usuarios seleccionados").

Luego de esto vemos el listado de observaciones pendientes de los mismos.

![]({% asset follow_up/incomplete-25.png @path %}){: class="img-responsive"}

Lo importante a tener en cuenta es que en el momento que hagan clic en la lista, la misma se "vacía" (una vez utilizado el enlace el carrito se "limpia")

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos mejora en los comentarios para las observaciones **¨Pendientes¨** dentro de la columna ¨Respuestas¨.

En el listado de seguimiento, dentro de la columna **"Respuestas"** donde figura la cantidad de comentarios de una observación van a ver un icono de advertencia amarillo si hay alguno que no hayan marcado como leído. Si pasan el puntero por encima les indica cuántos de los mensajes están sin la marca de leído.

Marcar un comentario como leído es manual, no automático, justamente para marcarlo únicamente luego de una respuesta.

Si ingresan a **¨Editar¨** una observación, donde figuran los comentarios van a ver un icono azul con un sobre, si hacen clic se marca ese comentario como leído (cambia a un icono negro, con la forma de un tilde).

Los comentarios propios, al momento de crearlos, se marcan automáticamente como leídos.

Seleccionamos **Seguimiento -> Hallazgos pendientes**

En la columna **"Respuestas"** donde figura la cantidad de comentarios de una observación van a ver un icono de advertencia amarillo si hay alguno que no hayan marcado como leído. Si pasan el puntero por encima indica cuántos de los mensajes están sin la marca de leído.

Por ejemplo para la primera observación del listado, hay 2 comentarios sin leer.

2/1 triangulo amarillo, significa lo siguiente:

* 2: cantidad de comentarios totales.

* 1: cantidad de comentarios propios.

* Triángulo: si pasan el puntero por encima indica la cantidad de comentarios sin leer por parte del usuario que se encuentra logueado.

Para este ejemplo, hay 2 comentarios sin leer (esto lo indica al pasar el puntero por encima del triángulo).

![]({% asset follow_up/incomplete-26.png @path %}){: class="img-responsive"}

Para marcar un comentario como leído, seleccionamos **"Editar"** en una observación (para este caso seleccionamos la observación que figura primero en el listado, la cual tiene 2 comentarios sin leer).

Nos muestra la siguiente pantalla, donde figuran los comentarios sin leer van a ver un icono azul con un sobre.

![]({% asset follow_up/incomplete-27.png @path %}){: class="img-responsive"}

Si hacemos clic (en el icono azul con el sobre) se marca ese comentario como leído (cambia a un icono negro, con la forma de un tilde).

Para este caso, marcamos el primero de los comentarios.

![]({% asset follow_up/incomplete-28.png @path %}){: class="img-responsive"}

Luego de leer el comentario, podemos ver que se actualizó la primera observación del listado, al pasar el puntero por encima del triángulo nos indica que tiene "1 comentario sin leer".

Marcar un comentario como leído es manual, no automático, justamente para marcarlo únicamente luego de una respuesta.

Los comentarios propios, al momento de crearlos, se marcan automáticamente como leídos.

Luego podemos seleccionar **"Editar"** en la misma observación (primera en el listado), para agregar un comentario.

![]({% asset follow_up/incomplete-29.png @path %}){: class="img-responsive"}

En este ejemplo, el usuario auditor (Cuenca, Francisco) agrega un comentario.

![]({% asset follow_up/incomplete-30.png @path %}){: class="img-responsive"}

Luego seleccionamos **"Actualizar observación"**.

Nos muestra el siguiente mensaje

![]({% asset follow_up/incomplete-31.png @path %}){: class="img-responsive"}

Y muestra marcado como leído el "Comentario" (debido a que los comentarios propios, al momento de crearlos, se marcan automáticamente como leídos)

![]({% asset follow_up/incomplete-32.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos una nueva funcionalidad que permite ordenar en forma descendente los comentarios no leídos.

Seleccionamos **Seguimiento -> Hallazgos pendientes**

![]({% asset follow_up/incomplete-33.png @path %}){: class="img-responsive"}

Luego seleccionamos "Buscar"

![]({% asset follow_up/incomplete-34.png @path %}){: class="img-responsive"}

Luego seleccionamos en "Ordenar por" la opción “Comentarios sin leer (Descendente)

![]({% asset follow_up/incomplete-35.png @path %}){: class="img-responsive"}

Luego nuevamente "Buscar", nos muestra los comentarios sin leer ordenados en forma descendente (posicionando el mouse en el triángulo nos muestra la cantidad de comentarios sin leer):

![]({% asset follow_up/incomplete-36.png @path %}){: class="img-responsive"}

Al final de la pantalla, tenemos las opciones "Descargar CSV" y “Resumen en PDF” del filtro que hemos realizado.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos una nueva funcionalidad de buscar para obtener la última actualización realizada.

Funciona como las demás búsquedas en seguimiento, se agregó en la primera columna un icono **¨Calendario¨** que puede usarse para habilitar o no la búsqueda por la fecha de última actualización.

Para ejemplificar su uso, si escriben en el campo búsqueda ¨desde 1/2/2018 y hasta 15/2/2018¨ y dejan activa únicamente la columna con el calendario van a obtener las observaciones que se modificaron en ese periodo.

La fecha de última modificación se actualiza por cualquier cambio en los campos de texto, las fechas, comentarios y papeles de trabajo.



Seleccionamos **Seguimiento -> Hallazgos pendientes**

Luego **¨Buscar¨**, ingresamos ¨desde 1/2/2018 y hasta 15/2/2018¨, dejamos activa solo la columna con el icono **¨Calendario¨** y desactivamos el resto de las columnas ¨Informe¨, ¨Proyecto¨, ¨Código¨, ¨Título¨, ¨Etiqueta¨.

Seleccionamos **¨Buscar¨**, nos muestra las observaciones que se modificaron en ese periodo (1/2/2018 y hasta 15/2/2018).

![]({% asset follow_up/incomplete-37.png @path %}){: class="img-responsive"}

Si seleccionamos **¨Resumen en PDF¨** nos muestra las mismas observaciones, informando al final del listado como fue elaborado el filtrado (filtrado con la consulta 'desde 1/2/2018 y hasta 15/2/2018' en la columna Última actualización).

![]({% asset follow_up/incomplete-38.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos una nueva funcionalidad de ¨**Agregar tareas a observaciones**¨.

Se agregan las tareas en ¨Seguimiento¨, justo arriba de los comentarios. Los datos que tienen que completar son la descripción, el estado y la fecha. Agregamos un código a las tareas, así pueden hacer referencia desde los comentarios sin ambigüedades.

Sobre el estado definimos 3: "Pendiente", "En proceso" o "Finalizada". De momento no hay restricciones sobre las transiciones, preferimos mantenerlo flexible hasta que con el uso veamos qué es lo más conveniente.

Sobre la fecha, cuando se agrega una tarea se "bloquea" la edición del campo "Fecha de implementación" de la observación. Esto es porque se entiende que ahora está definido por las tareas, donde siempre se toma la mayor como la nueva fecha de implementación.

Se envían recordatorios similares a los de las observaciones, siempre que estén en estado "Pendiente" o "En proceso".

También se mantiene registro de las reprogramaciones, si es la primera fecha y está vigente van a ver un tilde verde, en caso de reprogramación vigente van a ver un círculo con una flecha de color amarillo y en caso que esté vencida se muestra un reloj en rojo.

Cuando cambian el estado de una observación a uno de los "finales" (sería "Implementada / Auditada", "Riesgo asumido", "Difiere criterio", "Anulada" y "Desestimada / No aplica"), todas las tareas se pasan a "Finalizada".

Dentro del CSV agregamos la columna con la fecha más temprana pendiente de una tarea en la descarga del CSV (luego puedo sacar las vencidas).

Seleccionamos **Seguimiento -> Hallazgos pendientes**

Luego seleccionamos ¨Editar¨ en la observación donde vamos agregar tareas.

Para este ejemplo agregamos 2 tareas con fecha de finalización 1 y 2/08/2018.

![]({% asset follow_up/incomplete-39.png @path %}){: class="img-responsive"}

Al agregar las tareas con esta fecha se bloquea la edición del campo ¨Fecha de implementación¨ de la observación. Esto es porque se entiende que ahora está definido por las tareas, donde se toma la mayor como la nueva fecha de implementación.

![]({% asset follow_up/incomplete-40.png @path %}){: class="img-responsive"}

Se envían recordatorios similares a los de las observaciones, siempre que estén en estado ¨Pendiente¨ o ¨En Proceso¨ (Por ejemplo: Notificación de tareas cercanas al vencimiento, Notificación de tareas vencidas).

**¨Notificación de tareas cercanas al vencimiento¨**

![]({% asset follow_up/incomplete-41.png @path %}){: class="img-responsive"}

**¨Notificación de tareas vencidas¨**

![]({% asset follow_up/incomplete-42.png @path %}){: class="img-responsive"}

**Reprogramaciones**

Se mantiene registro de las reprogramaciones:

A tiempo sin reprogramación: muestra un icono **¨tilde verde¨** (código 02).

A tiempo reprogramada: muestra un icono **¨círculo con una flecha de color amarillo¨** (código 01).

![]({% asset follow_up/incomplete-43.png @path %}){: class="img-responsive"}

Vencida: fuera de tiempo, muestra un icono **¨reloj en rojo¨** (código 01 y 02).

![]({% asset follow_up/incomplete-44.png @path %}){: class="img-responsive"}

Dentro del CSV agregamos la columna con la fecha más temprana pendiente de una tarea en la descarga del CSV (luego puedo sacar las vencidas).

Al final de la pantalla (a la izquierda) seleccionamos ¨Descargar CSV¨.

![]({% asset follow_up/incomplete-45.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Reprogramación de observaciones reiteradas, incorporamos una funcionalidad que permite que las reiteradas que fueron reprogramadas tengan ¨SI¨ en la columna ¨Reprogramación¨ al seleccionar ¨Descargar CSV¨.

Hay dos cambios dentro de lo que se considera "reprogramada".

a) Ahora si o si debe tener un definitivo para comenzar a contar las reprogramaciones (hasta tanto se consideran parte de la edición), esto es para que sea consistente con las tareas (que ya se consideraban reprogramadas de esa manera).

> EJEMPLO<br>
> Año 2017 emitimos un informe definitivo con 1 observación Fecha de Origen 14/12/2017 y fecha de regularización 30/06/2018. Hasta ahí no se reprogramó.<br>
> En Junio vamos a hacer la auditoría y emitimos nuevamente el informe definitivo con fecha 10/06/2018. Reiteramos esa observación que estaba pendiente y ahí tenemos 2 alternativas:

1. Si la observación reiterada en el informe mantiene la fecha 30/06/2018 cuando emitimos el CSV debería decir Reprogramada "NO"<br>
2. Si la observación reiterada en el informe modifica su fecha y la extiende por ejemplo para el 30/09/2018 cuando emitimos el CSV debería decir Reprogramada "SI" porque la fecha original de resolución era 30/06/2018 y se reprogramó para el 30/09/2018.

b) En caso de reiteración y cambio de fecha (adelanto de la fecha de solución) se considera reprogramada al momento, independientemente de la emisión del informe definitivo (es decir, sería el único caso donde no hace falta el informe definitivo).

> EJEMPLO:<br>
> Observación de Fecha de origen 14/06/2018 y fecha de regularización 31/03/2019. Si piden adelantar la fecha al 31/12/2018 cuando saco el CSV debería decir reprogramación "NO", a pesar de haberle cambiado la fecha.


