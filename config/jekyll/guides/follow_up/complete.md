---
title: Hallazgos solucionados
layout: articles
category: follow_up
guide_order: 5
article_order: 3
---
# Seguimiento

## Hallazgos solucionados

Seleccionamos **Seguimiento -> Hallazgos solucionados**, muestra la siguiente pantalla.

![image]({{ site.baseurl }}/assets/images/follow_up/complete-1.png){: class="img-responsive"}

Podemos ¨**Descargar CSV**¨ y ¨**Resumen en PDF**¨ todos los hallazgos solucionados.

Tenemos las opciones de ¨**Ver**¨ y ¨**Editar**¨ para cada uno de los hallazgos.

Luego la forma de operar es igual a la opción explicada para las observaciones pendientes.

Un hallazgo que se encuentre en un informe definitivo se considera solucionado si se encuentra en alguno de los siguientes estados: Implementada/Auditada, Riesgo asumido y Difiere criterio.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Agregamos filtros para búsquedas más eficientes.

Seleccionamos **Seguimiento -> Hallazgos solucionados**

Se agregó en "Ordenar por".

![image]({{ site.baseurl }}/assets/images/follow_up/complete-2.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos el ordenamiento por default.

Seleccionamos **Seguimiento -> Hallazgos solucionados**

Para la vista de **"Hallazgos Solucionados"** (por default): se ordenan los hallazgos desde la fecha de solución más reciente a la más antigua

![image]({{ site.baseurl }}/assets/images/follow_up/complete-3.png){: class="img-responsive"}

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

Seleccionamos **Seguimiento -> Hallazgos solucionados**

En el caso de las búsquedas se pueden "desactivar" las columnas por las que no se quiere buscar.

Si hacen clic sobre el nombre de la columna que no necesitan buscar (por ejemplo ¨Informe¨),  van a ver que cambia a un tono más claro (**se torna de un color gris**), eso quiere decir que no se va a tener en cuenta para la búsqueda.

Las columnas que se encuentran tachadas, tampoco se tienen en cuenta para la búsqueda.

![image]({{ site.baseurl }}/assets/images/follow_up/complete-4.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos al CSV una columna con el número de observación interno, a la derecha del código, bajo el título "Id".

Seleccionamos **Seguimiento -> Hallazgos solucionados**

Seleccionar **"Descargar CSV"**

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos al CSV el número de acta.

Seleccionamos **Seguimiento -> Hallazgos solucionados**

En el CSV de seguimiento de observaciones se incluye el número de acta, también en el listado si posan el puntero sobre el número de informe.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos nuevas columnas en el CSV.

Seleccionamos **Seguimiento -> Hallazgos solucionados**

Agregamos nuevas columnas al CSV: unidad organizativa, unidad de negocio, recomendaciones de auditoría y Reprogramada.

Seleccionamos ¨**Descargar CSV**¨.

![image]({{ site.baseurl }}/assets/images/follow_up/complete-5.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos una nueva funcionalidad que permite ordenar en forma descendente los comentarios no leídos.

Seleccionamos **Seguimiento -> Hallazgos solucionados**

![image]({{ site.baseurl }}/assets/images/follow_up/complete-6.png){: class="img-responsive"}

Luego seleccionamos "Buscar"

![image]({{ site.baseurl }}/assets/images/follow_up/complete-7.png){: class="img-responsive"}

Luego seleccionamos en "Ordenar por" la opción “Comentarios sin leer (Descendente)

![image]({{ site.baseurl }}/assets/images/follow_up/complete-8.png){: class="img-responsive"}

Luego nuevamente "Buscar", nos muestra los comentarios sin leer ordenados en forma descendente (posicionando el mouse en el triángulo nos muestra la cantidad de comentarios sin leer):

![image]({{ site.baseurl }}/assets/images/follow_up/complete-9.png){: class="img-responsive"}



Al final de la pantalla, tenemos las opciones "Descargar CSV" y “Resumen en PDF” del filtro que hemos realizado.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos una nueva funcionalidad de buscar para obtener la última actualización realizada.

Funciona como las demás búsquedas en seguimiento, se agregó en la primera columna un icono **¨Calendario¨** que puede usarse para habilitar o no la búsqueda por la fecha de última actualización.

Para ejemplificar su uso, si escriben en el campo búsqueda ¨desde 1/2/2018 y hasta 15/2/2018¨ y dejan activa únicamente la columna con el calendario van a obtener las observaciones que se modificaron en ese periodo.

La fecha de última modificación se actualiza por cualquier cambio en los campos de texto, las fechas, comentarios y papeles de trabajo.



Seleccionamos **Seguimiento -> Hallazgos solucionados**

Luego **¨Buscar¨**, ingresamos ¨desde 1/5/2018 y hasta 4/5/2018¨, dejamos activa solo la columna con el icono **¨Calendario¨** y desactivamos el resto de las columnas ¨Informe¨, ¨Proyecto¨, ¨Código¨, ¨Título¨, ¨Etiqueta¨.

Seleccionamos **¨Buscar¨**, nos muestra las observaciones que se modificaron en ese periodo.

![image]({{ site.baseurl }}/assets/images/follow_up/complete-10.png){: class="img-responsive"}

Si seleccionamos **¨Resumen en PDF¨** nos muestra las mismas observaciones, informando al final del listado como fue elaborado el filtrado (filtrado con la consulta 'desde 1/5/2018 y hasta 4/5/2018' en la columna Última actualización).

![image]({{ site.baseurl }}/assets/images/follow_up/complete-11.png){: class="img-responsive"}

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

1. Si la observación reiterada en el informe mantiene la fecha 30/06/2018 cuando emitimos el CSV debería decir Reprogramada "NO"
2. Si la observación reiterada en el informe modifica su fecha y la extiende por ejemplo para el 30/09/2018 cuando emitimos el CSV debería decir Reprogramada "SI" porque la fecha original de resolución era 30/06/2018 y se reprogramó para el 30/09/2018.

b) En caso de reiteración y cambio de fecha (adelanto de la fecha de solución) se considera reprogramada al momento, independientemente de la emisión del informe definitivo (es decir, sería el único caso donde no hace falta el informe definitivo).

> EJEMPLO:<br>
> Observación de Fecha de origen 14/06/2018 y fecha de regularización 31/03/2019. Si piden adelantar la fecha al 31/12/2018 cuando saco el CSV debería decir reprogramación "NO", a pesar de haberle cambiado la fecha.
