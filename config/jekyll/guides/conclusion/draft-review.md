---
title: Informes borradores
layout: articles
category: conclusion
guide_order: 4
article_order: 2
---
# Conclusión

## Informes borradores

Para cada Informe creado en **Ejecución**, tenemos que generar un informe borrador, esto permite al auditor revisar todos los datos para luego crear el informe definitivo.

Seleccionamos **Conclusión**** -> Informes Borradores**

![]({% asset conclusion/draft-1.png @path %}){: class="img-responsive"}

![]({% asset conclusion/draft-2.png @path %}){: class="img-responsive"}

Seleccionamos **Nuevo**

![]({% asset conclusion/draft-3.png @path %}){: class="img-responsive"}

Seleccionamos de Informe (la lista desplegable) el proyecto que necesitamos generar el informe borrador.

Luego se completan en forma automática los campos Unidad de negocio y Proyecto, y Calificación (100%, debido a que todavía no se ha realizado ninguna prueba), este valor podría venir con una calificación diferente si hubiera iniciado el trabajo en la etapa de ejecución (es decir la evaluación del objetivo de control por medio de las pruebas previstas).

Muestra la siguiente pantalla.

![]({% asset conclusion/draft-4.png @path %}){: class="img-responsive"}

Completamos el campo Procedimientos aplicados.

Seleccionamos **Crear informe borrador**, muestra la siguiente pantalla.

![]({% asset conclusion/draft-5.png @path %}){: class="img-responsive"}

Si queremos ver las tareas faltantes, seleccionamos **Comprobar ahora**, luego **Ver detalles.**

![]({% asset conclusion/draft-6.png @path %}){: class="img-responsive"}

Para poder pasar a tener un informe definitivo, tenemos que lograr tener **Aprobado** el informe borrador, (para lo cual tenemos que realizar las tareas faltantes, las mismas se completan en la etapa de Ejecución, editando el informe o también podemos ir a las opciones Observaciones y/o Objetivos de control usando editar).

Seleccionamos **Actualizar informe borrador**, para que se almacenen los datos actualizados.

Vemos que el informe borrador no se encuentra aprobado

![]({% asset conclusion/draft-7.png @path %}){: class="img-responsive"}

Realizamos las tareas falantes, verificamos nuevamente con **Comprobar ahora**, **Ver Detalles**, muestra la siguiente pantalla (informando que está aprobado).

![]({% asset conclusion/draft-8.png @path %}){: class="img-responsive"}

Seleccionamos **Actualizar informe borrador.**

Ahora estamos en condiciones de generar el informe definitivo para este proyecto.

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos nuevos formatos de informes, **¨Sin calificación¨** y **¨Resumido¨**.

Seleccionamos **Conclusión ****-> Informes borradores**

![]({% asset conclusion/draft-9.png @path %}){: class="img-responsive"}

Luego seleccionamos ¨Editar¨ del informe que necesitamos descargar un informe.

![]({% asset conclusion/draft-10.png @path %}){: class="img-responsive"}

Seleccionar **"Descargar sin calificación" **y  **“Descargar resumido”**

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos la funcionalidad de "Cuestionarios" cuando enviamos un ¨Informe definitivo¨ o un ¨Informe borrador¨.

Seleccionamos **Conclusión -> Informes borradores**

Desde la **"edición de informes"** en conclusión, se puede asignar un usuario "auditor" a la encuesta (o elegir "Todos"). Esto es para obtener la opinión de un auditado respecto de una auditoría y además de una persona en particular.

Cuando envían el informe por correo agregamos un selector que sugiere a los auditores (o "Todos" como opción por defecto).

En caso que quieran enviar la misma encuesta sin distinguir el auditor y otra para un auditor en particular, tienen que agregar dos veces a la misma persona y en una fila seleccionar "Todos" y en la otra el nombre del auditor que quieren relacionar.

En ese caso le llegarán al auditado tantos correos con encuestas como filas tenga (cada una independiente e indicando en caso de ser para un auditor en particular de quien se trata). El informe llega solo una vez, independiente de la cantidad de veces que se lo haya agregado.

![]({% asset conclusion/draft-11.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos la funcionalidad de "Reportes", permitimos la emisión de informe borrador sin una buena práctica asociada (objetivo de control y proceso de negocio).

Seleccionamos **Conclusión -> Informes borradores**

Posibilidad de emitir informe borrador sin una buena práctica asociada (objetivo de control y proceso de negocio).

![]({% asset conclusion/draft-12.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos la funcionalidad para realizar controles en la emisión del informe borrador.

Seleccionamos **Conclusión -> Informes borradores**

Agregamos control de "Fecha de auditoría" (la misma no puede ser mayor a la fecha de emisión del informe) en los objetivos de control en el momento de la aprobación del informe borrador.

Seleccionamos "Comprobar ahora" para ver si está o no aprobado.

Luego seleccionamos "Ver detalles", vamos a ver el mensaje “la fecha de auditoría es mayor a la fecha de emisión del informe” identificando el objetivo de control.

![]({% asset conclusion/draft-13.png @path %}){: class="img-responsive"}

Luego seleccionamos "Ver detalles", vamos a ver el mensaje “la fecha de auditoría es mayor a la fecha de emisión del informe” identificando el objetivo de control.

![]({% asset conclusion/draft-14.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos la funcionalidad, ordenamos la firma de izquierda a derecha por el rol del usuario, primero los auditados, auditor, supervisor y gerente de auditoría, si han sido seleccionados con la opción ¨incluir firma¨ en Ejecución -> Informes.

Seleccionamos **Conclusión -> Informes borradores**

Ahora permite ordenar la firma que se muestra al final del documento pdf de los informes por "Rol" de izquierda a derecha primero Auditados [si los incluyen], Auditor, Supervisor, Gerente de auditoría).

![]({% asset conclusion/draft-15.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos  la funcionalidad de papeles de trabajo (informe borrador y definitivo). Agregamos en la portada de cada papel de trabajo la ruta a la que corresponde el mismo para una mejor identificación: buena práctica, proceso, objetivo de control, en el caso de las observaciones además está el título de la misma.

Seleccionamos **Conclusión -> Informes borradores**

Seleccionamos ¨Editar¨ de un informe (en este caso seleccionamos el primer informe de la lista 2018 PC 12 1).

![]({% asset conclusion/draft-16.png @path %}){: class="img-responsive"}

Luego seleccionamos ¨Descargar¨, ¨Descargar papeles de trabajo¨

Genera un documento con la extensión .zip, el cual si lo abrimos en observaciones por ejemplo, nos muestra lo siguiente:

![]({% asset conclusion/draft-17.png @path %}){: class="img-responsive"}

También podemos seleccionar ¨Generar Legajo¨ (esta opción es para aquellas organizaciones que emiten la documentación en papel), nos muestra la siguiente pantalla, donde podemos ingresar los datos que necesitamos para los títulos de las carátulas:

![]({% asset conclusion/draft-18.png @path %}){: class="img-responsive"}

Si seleccionamos ¨Generar¨, nos genera un documento .zip con los papeles de trabajo para el informe seleccionado.
