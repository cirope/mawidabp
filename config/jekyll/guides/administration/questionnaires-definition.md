---
title: Definición
layout: articles
category: administration
article_order: 13.1
parent: Cuestionarios
---
## Cuestionarios

### Definición

Seleccionamos **Administración -> Cuestionarios**

Nos muestra la opción de Definición, con los encuestas generadas al momento.

![]({% asset administration/questionnaires/1.png @path %}){: class="img-responsive"}

Esta parte permite crear un cuestionario. Debe definir un conjunto de preguntas y el tipo de respuestas (Respuesta escrita, Múltiple opción, Opción Si o No). También debemos definir el texto que va a ser incluído en el correo que va a ser enviado para que el destinatario pueda ingresar a contestar la encuesta.

Si es necesario puede incluir una asociación a una ¨Clase encuestable¨ para seleccionar el envío de este cuestionario cuando se notifica un informe definitivo. En caso que no seleccionemos (clase encuestable) nos permite enviar la encuesta en cualquier momento seleccionando la opción ¨Encuesta¨, luego ¨Nuevo¨ (ingresamos el usuario y seleccionamos el cuestionario), y luego seleccionamos ¨Crear encuesta¨.

Seleccionamos **Nuevo**, muestra la siguiente pantalla.

![]({% asset administration/questionnaires/2.png @path %}){: class="img-responsive"}

Ingresamos los datos obligatorios *.

Para este caso, seleccionamos:

¨Clase encuestable¨ Informe, por tal motivo vamos a poder enviar la encuesta asociado con un Informe Definitivo.

Y en tipo de respuesta seleccionamos ¨Múltiple opción¨. Podemos seleccionar cualquiera de los tipos que tenemos (Respuesta escrita, Múltiple opción, Opción Si o No) para cada una de las preguntas.

![]({% asset administration/questionnaires/3.png @path %}){: class="img-responsive"}

Luego seleccionamos **Crear Cuestionario**, muestra la siguiente pantalla.

![]({% asset administration/questionnaires/4.png @path %}){: class="img-responsive"}

Informando que el cuestionario se ha generado correctamente.

A partir de este momento podemos enviar el cuestionario generado a los usuarios auditados (seleccionando **Acerca de**, pueden ser ¨Todos¨ o seleccionar un usuario auditor en particular), cuando enviamos el informe definitivo (debido a que seleccionamos en ¨Clase encuestable¨ Informe).

Para concretar esta tarea, tenemos que hacer lo siguiente:

Vamos a **Conclusión -> Informe Definitivo**, seleccionamos el informe que necesitamos enviar, luego **editar**, luego seleccionamos la opción **Enviar por correo electrónico**, aparece la opción **¿Contestar encuesta? **(por defecto esta no), seleccionamos la encuesta generada **"Comité", **luego aparece la opción **Acerca de** (por defecto muestra ¨Todos¨, y tenemos la posibilidad de seleccionar a un usuario auditor de los que han participado en el informe, luego hacemos clic en **Enviar.**

![]({% asset administration/questionnaires/5.png @path %}){: class="img-responsive"}
![]({% asset administration/questionnaires/6.png @path %}){: class="img-responsive"}


La opción **Acerca de** fue agregada posteriormente. El objetivo es que podamos seleccionar a Todo el equipo de trabajo de auditores o solo a un auditor para que el usuario auditado pueda contestar la encuesta. Si seleccionamos ¨Todos¨ el auditado va contestar las preguntas para todo los auditores que participaron en el informe. Si seleccionamos un auditor, el auditado va contestar las preguntas teniendo en cuenta a ese auditor. Luego en la parte de reportes el sistema tiene la opción de filtros para obtener estos datos.

![]({% asset administration/questionnaires/7.png @path %}){: class="img-responsive"}

Seleccionamos **Enviar**.

![]({% asset administration/questionnaires/8.png @path %}){: class="img-responsive"}

Luego le llega un correo (en este caso al auditado) con el informe definitivo y el link para contestar la encuesta.

![]({% asset administration/questionnaires/9.png @path %}){: class="img-responsive"}

Luego el auditado ingresa al link **encuesta auditoría interna**, y carga los datos de la encuesta.

![]({% asset administration/questionnaires/10.png @path %}){: class="img-responsive"}

Selecciona **Actualizar Encuesta**, muestra la siguiente pantalla

![]({% asset administration/questionnaires/11.png @path %}){: class="img-responsive"}

Ejemplo de creación de un cuestionario (Cuestionario de prueba) donde no seleccionamos nada para la **¨Clase encuestable¨**. Esto permite que luego podamos enviar la encuesta en cualquier momento seleccionando la opción ¨Encuesta¨, luego ¨Nuevo¨ (ingresamos el usuario y seleccionamos el cuestionario), y luego seleccionamos ¨Crear encuesta¨ para enviar la encuesta al usuario seleccionado.

![]({% asset administration/questionnaires/12.png @path %}){: class="img-responsive"}
