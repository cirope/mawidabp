---
title: Informes finales
layout: articles
category: conclusion
guide_order: 4
article_order: 3
---
# Conclusión

## Informes definitivos

Para cada Informe borrador, se genera un Informe definitivo.

Seleccionamos **Conclusión -> Informes Definitivos**

![]({% asset conclusion/final-1.png @path %}){: class="img-responsive"}

Muestra todos los informes generados.

![]({% asset conclusion/final-2.png @path %}){: class="img-responsive"}

Seleccionamos **Nuevo**

![]({% asset conclusion/final-3.png @path %}){: class="img-responsive"}

Seleccionamos de Informe (la lista desplegable) el informe borrador que necesitamos generar el informe definitivo.

Luego se completan en forma automática los campos Unidad de negocio, Proyecto, y Calificación (en este caso 50%, ya que hemos realizado algunas pruebas) y procedimientos aplicados.

Muestra la siguiente pantalla.

![]({% asset conclusion/final-4.png @path %}){: class="img-responsive"}

Completamos el campo Conclusión, Fecha de emisión (puedo colocar cualquier fecha) y Fecha de cierre (puede ser igual o mayor a la fecha de emisión) , el campo Acta es opcional y se puede cargar luego de emitido el definitivo.

![]({% asset conclusion/final-5.png @path %}){: class="img-responsive"}

Seleccionamos **Crear informe definitivo**, muestra la siguiente pantalla.

![]({% asset conclusion/final-6.png @path %}){: class="img-responsive"}

Una vez creado el informe definitivo no se pueden editar los campos del informe (solo se puede agregar el número de acta y cargar papeles de trabajo hasta la fecha de cierre).

Se puede enviar por correo electrónico a los usuarios que necesitemos, seleccionamos **Editar** en el informe correspondiente.

![]({% asset conclusion/final-7.png @path %}){: class="img-responsive"}

Seleccionamos **Enviar por correo electrónico.**

![]({% asset conclusion/final-8.png @path %}){: class="img-responsive"}

Podemos seleccionar: Informe completo, Informe resumido, Informe sin calificación.

Podemos tildar: Incluir planilla de calificación, Incluir planilla de calificación detallada, Ocultar objetivos de control no calificados.

Tenemos la posibilidad de agregar:  Nota a incluir en el correo.

Podemos sacar o agregar usuarios para enviar el informe.

Luego de completar los campos muestra la siguiente pantalla.

![]({% asset conclusion/final-9.png @path %}){: class="img-responsive"}

Luego seleccionamos **Enviar,** aparece la siguiente pantalla.

![]({% asset conclusion/final-10.png @path %}){: class="img-responsive"}

Luego llega a los usuarios seleccionados el correo electrónico enviado por el sistema, a continuación mostramos el correo recibido por un usuario auditado.

![]({% asset conclusion/final-11.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos un campo "número de acta" en los informes definitivos.

Seleccionamos **Conclusión -> Informe definitivo**

Podemos cargar el número de acta del comité de auditoría (en el caso de un Banco) o el número de acta que defina por procedimiento la organización (es opcional el uso).

Es el único dato que puede agregarse luego de haber emitido el informe definitivo.

![]({% asset conclusion/final-12.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos nuevos formatos de informes, **¨Sin calificación¨** y **¨Resumido¨**.

Seleccionamos **Conclusión -> Informe definitivo**

![]({% asset conclusion/final-13.png @path %}){: class="img-responsive"}

Luego seleccionamos ¨Editar¨ del informe que necesitamos descargar un informe.

![]({% asset conclusion/final-14.png @path %}){: class="img-responsive"}

Seleccionar **"Descargar sin calificación"** y  **“Descargar resumido”**

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos la funcionalidad de "Cuestionarios" cuando enviamos un ¨Informe definitivo¨ o un ¨Informe borrador¨.

Seleccionamos **Conclusión -> Informe definitivo**

Desde la **"edición de informes"** en conclusión, se puede asignar un usuario "auditor" a la encuesta (o elegir "Todos"). Esto es para obtener la opinión de un auditado respecto de una auditoría y además de una persona en particular.

Cuando envían el informe por correo agregamos un selector que sugiere a los auditores (o "Todos" como opción por defecto).

En caso que quieran enviar la misma encuesta sin distinguir el auditor y otra para un auditor en particular, tienen que agregar dos veces a la misma persona y en una fila seleccionar "Todos" y en la otra el nombre del auditor que quieren relacionar.

En ese caso le llegarán al auditado tantos correos con encuestas como filas tenga (cada una independiente e indicando en caso de ser para un auditor en particular de quien se trata). El informe llega solo una vez, independiente de la cantidad de veces que se lo haya agregado.

![]({% asset conclusion/final-15.png @path %}){: class="img-responsive"}

Seleccionamos **Administración -> Cuestionarios -> Reportes**

Por el lado de los reportes pusimos unas opciones al lado del usuario que funcionan así **(seleccionar en "Ver"):**

> **"Asignadas"** muestra las encuestas directamente asignadas al usuario (siempre que haya un usuario seleccionado).

> **"Solo a todos"** muestra las encuestas enviadas con la opción "Todos" (no tiene en cuenta el usuario seleccionado).

> **"Asignadas y por informe"** muestra las encuestas directamente asignadas al usuario y en las que participó como integrante en el informe (siempre que haya un usuario seleccionado).

![]({% asset conclusion/final-16.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos la funcionalidad de "Reportes", permitimos la emisión de informe definitivo sin una buena práctica asociada (objetivo de control y proceso de negocio).

Seleccionamos **Conclusión -> Informe definitivo**

Posibilidad de emitir informe definitivo sin una buena práctica asociada (objetivo de control y proceso de negocio).

![]({% asset conclusion/final-17.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos la funcionalidad, ordenamos la firma de izquierda a derecha por el rol del usuario, primero los auditados, auditor, supervisor y gerente de auditoría, si han sido seleccionados con la opción ¨incluir firma¨ en Ejecución -> Informes.

Seleccionamos **Conclusión -> Informes definitivos**

Ahora permite ordenar la firma que se muestra al final del documento pdf de los informes por "Rol" de izquierda a derecha (Auditados [], Auditor, Supervisor, Gerente de auditoría).

![]({% asset conclusion/final-18.png @path %}){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Mejoramos  la funcionalidad de papeles de trabajo (informe borrador y definitivo). Agregamos en la portada de cada papel de trabajo la ruta a la que corresponde el mismo para una mejor identificación: buena práctica, proceso, objetivo de control, en el caso de las observaciones además está el título de la misma.

Seleccionamos **Conclusión -> Informes definitivos**

Seleccionamos ¨Editar¨ de un informe (en este caso seleccionamos el primer informe de la lista 2018 PC 003).

![]({% asset conclusion/final-19.png @path %}){: class="img-responsive"}

Luego seleccionamos ¨Descargar¨, ¨Descargar papeles de trabajo¨

Genera un documento con la extensión .zip, el cual si lo abrimos nos muestra la carátula con la identificación de buena práctica, proceso y objetivo de control.


