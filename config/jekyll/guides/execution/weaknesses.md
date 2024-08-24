---
title: Observaciones
layout: articles
category: execution
guide_order: 3
article_order: 5
---
# Ejecución

## Observaciones

Tenemos las observaciones ordenados por informe, permite encontrar en forma rápida con la opción **Buscar** por Informe, Proyecto, Código, Título y Etiqueta, y además ¨Ordenar por¨.

Seleccionando ¨Editar¨ nos permite realizar las tareas previstas en este módulo (completar los aspectos faltantes de la observación y realizar el seguimiento del trabajo).

**Seleccionamos Ejecución -> Observaciones**

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/1.png){: class="img-responsive"}

Nos muestra las observaciones generadas ordenados por Informe.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/2.png){: class="img-responsive"}

Si necesitamos encontrar en forma rápida tenemos la opción de **Buscar** por Informe, Proyecto, Código, Título y Etiqueta, y además ¨Ordenar por¨.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/3.png){: class="img-responsive"}

En el caso de las búsquedas se pueden "desactivar" las columnas por las que no se quiere buscar.

Si hacen clic sobre el nombre de la columna, van a ver que cambia a un tono más claro (se torna gris), eso quiere decir que no se va a tener en cuenta (lo mismo que las tachadas).

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Agregamos el campo **"Título"** en observaciones/oportunidades de mejora.

Permite agregar un título para luego poder buscar de manera simple y rápida.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/4.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Reconocimiento de **¨enlaces en papeles de trabajo¨** (http y ftp), permite agregar enlaces http y ftp en la descripción.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/5.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad **"Relacionar observaciones"**.

**Ejecución -> Observaciones**

Seleccionamos "Editar" en una observación.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/6.png){: class="img-responsive"}

Luego "Agregar relación" y para guardar seleccionamos  “Actualizar observación”

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/7.png){: class="img-responsive"}

Podemos relacionar observaciones cuando estamos generando la nueva observación, existe la opción "Relacionada con".

Ingresamos en "Hallazgo relacionado" caracteres, muestra un listado de observaciones, seleccionamos una, y luego permite que carguemos una "Descripción". Luego podemos seguir agregando observaciones relacionadas haciendo los mismos pasos.

El "Relacionada con" se utiliza cuando la relación es más un apuntador, una ayuda memoria para tener en cuenta una observación si hay un cambio importante en otra.

Es más una nota al estilo de "si esta observación pasa a Implementada / Auditada probablemente esta otra esté también solucionada". Acá el sistema no hace más que llevar la traza.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad **¨Reiterar observaciones¨**.

**Ejecución -> Observaciones**

Seleccionamos "Editar" de un informe

Primero hay que agregar las observaciones que potencialmente se puedan reiterar en el informe (desde la edición, dentro de "Ejecución"  -> Informes).

Tienen que estar dentro de "Hallazgos pendientes". Después, cuando creen una observación dentro de ese informe, en el combo "Reiterada de" van a poder seleccionar una de las pendientes.

Cuando hacemos eso, el sistema va a traer todos los datos de la observación a reiterar (incluida la fecha de origen).

Luego al guardar la nueva observación, la seleccionada dentro del combo pasa a tener el estado "Reiterada", la nueva queda en el estado que hayan indicado y queda establecida una relación en la que pueden navegar la historia.

Por ejemplo:

* O003 - Informe 2016 X (Reiterada - Fecha de origen 12/05/2016)

* O007 - Informe 2017 X (En proceso de implementación - Fecha de origen 12/05/2016)

Pueden reiterar tantas veces como quieran, el año que viene la O007 podrá reiterarse, y la observación nueva tendría la misma fecha de origen y la referencia a la O007 (y está a su vez a la O003).

Resumen de los pasos:

1) Dentro de "Ejecución"  -> Informes, seleccionar "editar", agregar dentro de “Agregar hallazgo pendiente” las observaciones que van a reiterar, luego seleccionar actualizar informe.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/8.png){: class="img-responsive"}
![image]({{ site.baseurl }}/assets/images/execution/weaknesses/9.png){: class="img-responsive"}
![image]({{ site.baseurl }}/assets/images/execution/weaknesses/10.png){: class="img-responsive"}
![image]({{ site.baseurl }}/assets/images/execution/weaknesses/11.png){: class="img-responsive"}

2) Luego crear una observación nueva en el informe y dentro de las opciones seleccionar "Reiterada de", en el desplegable se muestran las incluidas en el punto anterior.

Editamos un objetivo de control, seleccionamos agregar una observación, seleccionar "Reiterada de", en el desplegable muestra la observación, la seleccionamos, luego seleccionamos “Crear observación”.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/12.png){: class="img-responsive"}
![image]({{ site.baseurl }}/assets/images/execution/weaknesses/13.png){: class="img-responsive"}

3) Luego de esto la observación anterior queda enlazada a la nueva y por lo tanto la marca como "reiterada".

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos un nuevo estado de observaciones **"Difiere criterio"**.

**Ejecución -> Observaciones**

Es un estado definitivo, se usa para aquellas casos que la organización no está de acuerdo con una observación realizada por algún organismo externo, por ejemplo B.C.R.A. y/o Auditoría Externa.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad para mejorar los **¨papeles de trabajo¨**.

Ahora no es obligatorio el campo **"Cantidad de páginas"** en los papeles de trabajo.

Respecto de los papeles y la fecha de cierre del informe, los PTO se pueden editar y reemplazar hasta la ¨fecha de cierre¨ desde ejecución o seguimiento. Una vez cumplida la fecha de cierre solo se pueden editar los archivos PTSO desde seguimiento.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad **¨Descargar CSV¨** para observaciones.

**Ejecución -> Observaciones**

Seleccionamos "Observaciones", luego “Descargar CSV”

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/14.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos **¨Nuevo estado Desestimada / No aplica¨**, para una observación.

**Ejecución -> Observaciones**

Hay un nuevo estado "Desestimada / No aplica" para las observaciones, se comporta exactamente igual a "Difiere criterio". Se utilizaría en observaciones que se "solucionaron" porque dejó de existir el objeto que observaban, por ejemplo, cuando dan de baja un sistema.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad de **¨Agregar tareas¨** a observaciones.

Se agregan las tareas en ¨Ejecución¨, justo arriba de los comentarios. Los datos que tienen que completar son la descripción, el estado y la fecha.

Sobre el estado definimos 3, "Pendiente", "En proceso" o "Finalizada". De momento no hay restricciones sobre las transiciones, preferimos mantenerlo flexible hasta que con el uso veamos qué es lo más conveniente.

Sobre la fecha, cuando se agrega una tarea se "bloquea" la edición del campo "Fecha de implementación" de la observación. Esto es porque se entiende que ahora está definido por las tareas, donde siempre se toma la mayor como la nueva fecha de implementación.

Se envían recordatorios similares a los de las observaciones, siempre que estén en estado "Pendiente" o "En proceso".

También se mantiene registro de las reprogramaciones, si es la primera fecha y está vigente van a ver un tilde verde, en caso de reprogramación vigente van a ver un círculo con una flecha de color amarillo y en caso que esté vencida se muestra un reloj en rojo.

Cuando cambian el estado de una observación a uno de los "finales" (sería "Implementada / Auditada", "Riesgo asumido", "Difiere criterio", "Anulada" y "Desestimada / No aplica"), todas las tareas se pasan a "Finalizada".

**Ejecución -> Observaciones**

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/15.png){: class="img-responsive"}

Luego seleccionamos ¨Editar¨ en la observación donde vamos agregar tareas. Nos muestra la siguiente pantalla (para que podamos agregar tareas).

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/16.png){: class="img-responsive"}

Seleccionamos ¨Agregar tarea¨

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/17.png){: class="img-responsive"}

Seleccionamos ¨Actualizar Observación¨ para guardar los cambios.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/18.png){: class="img-responsive"}

Al agregar la tarea con esta fecha se bloquea la edición del campo ¨Fecha de implementación¨ de la observación. Esto es porque se entiende que ahora está definido por las tareas, donde se toma la mayor como la nueva fecha de implementación.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/19.png){: class="img-responsive"}

Se envían recordatorios similares a los de las observaciones, siempre que estén en estado ¨Pendiente¨ o ¨En Proceso¨ (Por ejemplo: Notificación de tareas cercanas al vencimiento, Notificación de tareas vencidas).

**Notificación de tareas cercanas al vencimiento**

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/20.png){: class="img-responsive"}

**Notificación de tareas vencidas**

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/21.png){: class="img-responsive"}

**Reprogramaciones**

Se mantiene registro de las reprogramaciones.

A tiempo sin reprogramación: muestra un icono **¨tilde verde¨**.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/22.png){: class="img-responsive"}

A tiempo reprogramada: muestra un icono **¨círculo con una flecha de color amarillo¨.**

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/23.png){: class="img-responsive"}

Vencida: fuera de tiempo, muestra un icono **¨reloj en rojo¨**.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/24.png){: class="img-responsive"}

Cuando cambian el estado de una observación a uno de los "finales" (sería "Implementada / Auditada", "Riesgo asumido", "Difiere criterio", "Anulada" y "Desestimada / No aplica"), todas las tareas se pasan a "Finalizada".

Si pasamos la observación al estado "Implementada / Auditada".

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/25.png){: class="img-responsive"}

La tarea pasa a estado ¨Finalizada¨ en forma automática.

![image]({{ site.baseurl }}/assets/images/execution/weaknesses/26.png){: class="img-responsive"}
