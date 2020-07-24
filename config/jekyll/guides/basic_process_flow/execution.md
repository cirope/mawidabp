---
title: Ejecución
layout: articles
category: basic_process_flow
guide_order: 7
article_order: 4
---

## Ejecución

Seleccionamos **Ejecución**, nos muestra la siguiente pantalla

![]({% asset basic_process_flow/execution.png @path %}){: class="img-responsive"}


Tenemos que crear un informe, a partir de los datos generados en los pasos anteriores (etapa planificación)

Y luego agregar observaciones.

#### Informes
Seleccionamos **Ejecución -> Informes**

![]({% asset basic_process_flow/reviews.png @path %}){: class="img-responsive"}


Muestra todos los informes creados para distintos períodos con la identificación, relacionados con la unidad de negocio, proyecto y etiquetas en caso de haber sido creada.


Seleccionamos **Nuevo**

![]({% asset basic_process_flow/new_review.png @path %}){: class="img-responsive"}


**Identificación:** podemos utilizar la nomenclatura adoptada por la organización (letras, números, guiones, etc.)


Seleccionar **período y proyecto:** son datos cargados en la etapa de planificación.


Luego de seleccionado el período y proyecto muestra la unidad de negocio y el tipo de auditoría (son los datos cargados en la etapa de administración).


**Integrante** Son las personas que participan del informe. Como mínimo tenemos que tener el rol auditor, supervisor y auditado, o auditor, gerente de auditoría y auditado.


**Etiqueta** (es opcional)


Agregar etiquetas, se muestran las creadas en la etapa de Administración - Etiquetas, podemos seleccionar la más conveniente para identificar al informe (es opcional).

**Objetivo de control**


Seleccionamos los objetivos de control que necesitamos controlar en este informe (los mismos fueron cargados en la etapa de administración - buenas prácticas).

**Proceso**


También podemos seleccionar un proceso (muestra todos los objetivos de control del proceso), el mismo fue cargado en la etapa de administración - buenas prácticas.


**Hallazgos pendientes**
Agregar hallazgo pendiente
Al seleccionar esta opción, nos permite incorporar un texto (letras o números), con los cuales va a buscar en la base de datos del sistema y muestra los hallazgos pendientes que tengan alguna letra o número que coincida con lo que ingresamos, tenemos la posibilidad de seleccionar uno de los propuestos, luego podemos seguir buscando e incorporando de uno los que necesitamos para este informe


**Sugerir hallazgo pendiente**
Al seleccionar esta opción nos muestra los hallazgos pendientes de toda la organización para la unidad organizativa que tenemos seleccionada, tenemos la posibilidad de seleccionar cuales nos interesan eliminando los que no necesitamos para este informe.


- **Descripción:** el texto incluido en esta parte, formará parte del título del informe borrador y definitivo.


- **Relevamiento:** opcionalmente podemos completar el campo relevamiento y/o subir algún archivo que consideremos importante como anexo al informe.


A continuación mostramos las pantallas con los datos cargados para el proyecto Acuerdo.

![]({% asset basic_process_flow/new_review-1.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/new_review-2.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/new_review-3.png @path %}){: class="img-responsive"}




Para guardar los datos seleccionamos **Crear informe**, si todo está bien nos muestra la siguiente pantalla (en caso de inconvenientes da un mensaje con los errores encontrados, los cuales podemos ir solucionando hasta que nos permite crear el informe).

Luego de crear el informe, podemos agregar observaciones al objetivo de control incorporado en el informe. Para realizar estas actividades el sistema brinda 2 opciones (Opción 1 y Opción 2).

**Opción 1 (Ejecución -> Informes -> Editar)**


Seleccionar **Ejecución -> Informes**- seleccionar el informe con el que necesitamos trabajar,  luego seleccionar **Editar**, aparecen los objetivos de control separados por proceso (Préstamos) con los cuales trabajar.

![]({% asset basic_process_flow/execution_control_objetive.png @path %}){: class="img-responsive"}

Luego seleccionar **Editar** en el objetivo de control que necesitamos trabajar (por ejemplo: Préstamos - Otorgamiento - Instrumentación), muestra la siguiente pantalla.

![]({% asset basic_process_flow/control_objective_items_1.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/control_objective_items_2.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/control_objective_items_3.png @path %}){: class="img-responsive"}


Esta pantalla es el **escritorio** de trabajo del usuario **auditor**, el cual le permite **analizar y evaluar el control interno del objetivo de control** por medio de las pruebas previstas (en este caso pruebas de cumplimiento).

Las pruebas permiten revisar si se cumplen los **controles previstos** y obtener la efectividad de control para el objetivo de control que estamos revisando.

Procedemos a realizar la Calificación de la prueba de cumplimiento, en caso que se cumplan los controles colocamos la calificación que consideramos oportuna [por ejemplo: Medio alto (7)], o podemos encontrar que no se cumplen algunos aspectos, ante esta situación podemos agregar observaciones. También tenemos la posibilidad de agregar oportunidades de mejora, de realizar cambios en la redacción del objetivo de control y el efecto.

Para realizar la Calificación de las pruebas (evaluación de diseño, cumplimiento, y sustantivas) tenemos la siguiente escala: Nulo (0), Muy bajo (1), Bajo (2), Medianamente bajo (3), Medio bajo (4), Medio (5), Medianamente alto (6), Medio alto (7), Alto (8), Muy Alto (9), Óptimo (10).

Realizamos la calificación de la prueba ejecutada (en este caso seleccionamos Medio alto 7), se actualiza la efectividad de control (pasa a ser 70%), también tenemos la opción de tildar No calificar (en este caso el objetivo de control no es calificado).

![]({% asset basic_process_flow/control_objective_items_1_1.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/control_objective_items_2_2.png @path %}){: class="img-responsive"}

Cuando creemos que hemos finalizado con las actividades, tildamos **Terminado**. En este caso el sistema revisa que se encuentren completas todas las actividades previstas para el objetivo de control que estamos revisando.

Para que se guarden los cambios realizados tenemos que seleccionar la opción **Actualizar objetivo de control**. En caso que existan campos faltantes el sistema brinda un mensaje de error con los aspectos a completar.

Seleccionamos **Actualizar objetivo de control**, nos muestra la siguiente pantalla:

![]({% asset basic_process_flow/control_objective_items_4.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/control_objective_items_5.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/control_objective_items_6.png @path %}){: class="img-responsive"}

Procedemos a solucionar los errores encontrados (completar los campos faltantes), luego muestra la siguiente pantalla.

![]({% asset basic_process_flow/control_objective_items_7.png @path %}){: class="img-responsive"}

Para observar que el objetivo de control está terminado, podemos hacerlo de la siguiente manera.

Seleccionamos **Ejecución -> Informes -> Editar**

Muestra todos los objetivos de control correspondientes al informe que hemos seleccionado, el que aparece tachado es el que hemos terminado.

![]({% asset basic_process_flow/control_objective_items_8.png @path %}){: class="img-responsive"}


También podemos seleccionar **Ejecución -> Objetivos de control**, aparece de la siguiente manera (**Terminado: SI**):

![]({% asset basic_process_flow/control_objective_items_9.png @path %}){: class="img-responsive"}

También tenemos la posibilidad de agregar papeles de trabajo como evidencia del trabajo realizado en el objetivo de control.

Para que se guarden los cambios seleccionar la opción **Actualizar objetivo de control**. La codificación es PTOC 001 (PTOC: papeles de trabajo objetivo de control. 001: primer papel de trabajo cargado). Si agregamos otro papel de trabajo va indicar PTOC 002.

![]({% asset execution/reviews/17.png @path %}){: class="img-responsive"}


**Opción 2 (Ejecución -> Objetivos de control -> Editar)**


Ahora vamos a realizar las actividades de control para el objetivo de control **Mantenimiento de una base de...**, por otro camino.

Seleccionamos **Ejecución -> Objetivos de control**. Muestra la siguiente pantallas con los objetivos de control:


![]({% asset basic_process_flow/control_objective_items_10.png @path %}){: class="img-responsive"}

Luego seleccionamos **Editar** en el objetivo de control con el cual necesitamos trabajar (en este caso Mantenimiento de una base de...).

A partir de este momento nos muestra las mismas pantallas de trabajo que la **opción 1**.

![]({% asset basic_process_flow/control_objective_items_11.png @path %}){: class="img-responsive"}


Esta pantalla es el "**escritorio"** de trabajo del auditor, el cual le permite analizar y evaluar el control interno del objetivo de control por medio de las pruebas previstas (en este caso pruebas de cumplimiento).

Las pruebas nos permiten revisar si se cumplen los controles previstos y obtener la efectividad de control para el objetivo de control que estamos revisando.

En este caso vemos que los **controles** no se están cumpliendo según lo previsto, según la prueba de cumplimiento realizada, por tal motivo la Calificación de la prueba de cumplimiento es Medio (5), logrando una efectividad de 50%.

![]({% asset basic_process_flow/control_objective_items_12.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/control_objective_items_13.png @path %}){: class="img-responsive"}


Por tal motivo vamos agregar una observación, para lo cual tenemos que seleccionar la opción **Agregar nueva observación**.

![]({% asset basic_process_flow/control_objective_items_14.png @path %}){: class="img-responsive"}

Al seleccionar **Agregar nueva observación**, muestra la siguiente pantalla.

![]({% asset basic_process_flow/control_objective_items_15.png @path %}){: class="img-responsive"}
![]({% asset basic_process_flow/control_objective_items_16.png @path %}){: class="img-responsive"}

Esta pantalla nos muestra los datos para crear una observación, para guardar los cambios tenemos que seleccionar **Crear Observación**.

Al crear una observación, se genera un código de observación en forma automática por el sistema (**O0001**). "O" significa: observación. “0001”: es la primera observación del informe. Y nos muestra todos los datos cargados en la buena práctica y en el trabajo realizado hasta el momento con el objetivo de control.

**Título**: es un descripción resumida del tema de la observación.

**Reiterada de**: podemos seleccionar si la observación es reiterada de otra observación. Si lo hacemos, la **anterior** pasa a reiterada, y la **nueva** toma todos los datos de la anterior.

**Observación**: se redacta la observación encontrada.

**Recomendaciones de auditoría**: colocamos los aspectos a tener en cuenta para solucionar la observación o cualquier otro tema que consideremos importante aportar desde una visión proactiva.

**Fecha de origen**: completamos con la fecha que fue detectada la observación.

**Riesgo**: seleccionamos el valor (Alto, Medio, Bajo) para esta observación.

**Prioridad**: seleccionamos el valor (Alta, Media, Baja) para esta observación.

**Estado**: los valores son Anulada, En proceso de implementación, Implementada, Implementada/auditada, Incompleta, Notificar, Riesgo asumido, Difiere Criterio.

Cuando el auditor inicia el trabajo con la observación, selecciona el estado **Incompleta **(es lo recomendable para seguir un circuito de trabajo ordenado y simple). Al colocarla en este estado, el usuario auditado no pueda ver la observación (se usa durante el tiempo que el auditor está trabajando con la observación). El auditor puede iniciar el trabajo con la observación en cualquiera de los estados previstos, esto depende de la forma de trabajo de la organización. En base al estado seleccionado por el auditor, el sistema solicita mayor cantidad de datos para crearla.

Si la colocamos en estado **Notificar**, el sistema envía un correo en forma automática a todos los responsables a las 20 hs. (o en el horario definido por la organización)

**Responsables**: nos muestra los usuarios cargados en la etapa de planificación. Podemos agregar y/o cambiar usuarios. Para crear una observación, como mínimo siempre tiene que existir 1 auditor, 1 supervisor y 1 auditado, o 1 auditor, 1 gerente de auditoría y 1 auditado. Podemos seleccionar en forma opcional el Auditor referente (es el encargado de seguir el proceso de trabajo con la observación), y el Responsable por el lado de los auditados (es el encargado de seguir el proceso de trabajo con la observación).

**Relacionda con**: podemos agregar si la observación está relacionada con otro hallazgo. Al hacerlo puedo colocar la fecha, en caso de no hacerlo coloca la fecha del informe.

**Papeles de trabajo**: permite agregar evidencias. Nombre, Código (PTO: papel de trabajo observación, 0001: es el primer papel de trabajo), Páginas (es opcional), Descripción, Archivo (adjuntar un documento).

Al finalizar con la carga de datos seleccionamos **Crear Observación** (si no nos faltan datos se guarda la observación), caso contrario nos muestra un mensaje de error con los aspectos faltantes, a continuación mostramos una pantalla con un mensaje de error.

![]({% asset basic_process_flow/control_objective_items_17.png @path %}){: class="img-responsive"}

Al completar los datos faltantes, y seleccionar **Crear Observación**, nos muestra el siguiente mensaje.

![]({% asset basic_process_flow/control_objective_items_18.png @path %}){: class="img-responsive"}

El resto de los campos faltantes (respuesta/acción correctiva, fecha de implementación/acción correctiva, fecha de solución, comentario de auditoría), se completan cuando tenga la respuesta de los usuarios auditados y a medida que avance en el proceso de trabajo.

Cuando necesitemos generar el informe borrador y definitivo (en la etapa de conclusión) el sistema realiza una serie de controles en forma automática, por ejemplo controla que todos los campos se encuentren completos, caso contrario nos informa los aspectos faltantes.

Para ver las observaciones generadas, seleccionar **Ejecución -> Observaciones**, nos muestra lo siguiente.

![]({% asset basic_process_flow/control_objective_items_19.png @path %}){: class="img-responsive"}

Podemos observar en primer lugar la observación generada recientemente (Estado Notificar), en caso de necesitar ver los detalles o seguir trabajando con la misma, seleccionó **Editar (Lápiz)**.

A las 20 hs. (o en el horario definido por la organización) el sistema envía un correo a los integrantes (notificación de hallazgos) de esta observación que se ha generado (debido a que se encuentra en estado **Notificar**).

![]({% asset basic_process_flow/control_objective_items_20.png @path %}){: class="img-responsive"}


El usuario auditado puede seleccionar **Confirmar notificación**, al hacerlo pasa al estado **"Confirmada"**, siempre que ingrese un comentario en “Comentarios de seguimiento”.

A continuación mostramos los pasos luego que el usuario auditado selecciona **Confirmar notificación**.

Aparece la pantalla de ingreso al sistema (ingresa usuario y contraseña), selecciona Ingresar.

![]({% asset basic_process_flow/control_objective_items_21.png @path %}){: class="img-responsive"}

Muestra la pantalla con la observación en estado **No confirmada**, al seleccionar **Editar**, muestra la siguiente pantalla:

![]({% asset basic_process_flow/control_objective_items_22.png @path %}){: class="img-responsive"}

El usuario auditado ingresa:  un comentario, la fecha de compromiso y puede dejar el tilde en enviar notificación (si lo saca no envía la notificación a los integrantes). También tiene que ingresar el tiempo dedicado (por defecto esta en minutos), y una descripción de las actividades realizadas (es opcional).

Seleccionamos **Actualizar observación**, aparece la siguiente pantalla (con el cambio de estado a confirmada):

![]({% asset basic_process_flow/control_objective_items_23.png @path %}){: class="img-responsive"}

Además envía un correo a los integrantes de la observación, ya que dejamos con el tilde Enviar notificación.

![]({% asset basic_process_flow/control_objective_items_24.png @path %}){: class="img-responsive"}

Luego de esto el usuario auditor, puede ingresar al sistema o por medio de **Ver hallazgo**, y seguir con el proceso de trabajo en la observación.

Luego podemos ver en el listado de observaciones, como cambio al estado Confirmada.

![]({% asset basic_process_flow/control_objective_items_25.png @path %}){: class="img-responsive"}


Para el informe creado en  las etapas anteriores se agregaron  2 observaciones, que se muestran a continuación:

![]({% asset basic_process_flow/control_objective_items_26.png @path %}){: class="img-responsive"}

En la imagen anterior una de las observaciónes se ha modificado al estado **"En proceso de Implementación"**. Un auditor puede tomar la decisión de cambiar ese estado dependiendo el comentario del usuario auditado. 

El próximo paso, es crear un informe borrador en la etapa de conclusión, a partir del informe creado en la etapa de ejecución.