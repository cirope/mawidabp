---
title: Administración
layout: articles
category: basic_process_flow
guide_order: 7
article_order: 2
---

## Administración

Seleccionamos **Administración**, nos muestra la siguiente pantalla.

![]({% asset administration/menu.png @path %}){: class="img-responsive"}


### Organización

##### Gestión

Seleccionamos **Administración -> Organización -> Gestión**

Se cargan los siguientes datos de la organización: nombre, prefijo, y la descripción.

![]({% asset basic_process_flow/new_organization.png @path %}){: class="img-responsive"}

*Seleccionamos **Crear organización** para que se genere.*
*Luego de creada la organización se puede cargar el isologotipo.*

A continuación mostramos la vista global de la organización creada *(por ejemplo en este caso: Demo).*

![]({% asset basic_process_flow/list_organizations.png @path %}){: class="img-responsive"}

Luego mostramos los datos en detalle de la organización creada:

##### Configuración LDAP:

Esta opción es utilizada cuando el sistema es instalado en la infraestructura de la organización.
Se cargan los datos de acuerdo a la configuración de Active Directory informados por las áreas de sistemas y seguridad informática de la organización.

![]({% asset basic_process_flow/ldap.png @path %}){: class="img-responsive"}

##### Unidades organizativas
Seleccionamos **Administración -> Organización -> Unidades organizativas**

Las unidades organizativas están compuestas por unidades de negocio (por ejemplo, Unidad organizativa: Procesos Centrales, está compuesta por las Unidades de negocio: Préstamos, Depósitos, Finanzas, Comercio Exterior y Cambios, Contabilidad, etc.)

**1. Cómo cargamos una unidad organizativa para la organización?**


A continuación mostramos un ejemplo de las unidades organizativas necesarias para el área de auditoría interna de un Banco:

![]({% asset basic_process_flow/business_unit_types.png @path %}){: class="img-responsive"}

Para agregar una unidad organizativa, seleccionamos Nuevo, muestra la siguiente pantalla (los datos indicados con * son obligatorios)

![]({% asset basic_process_flow/new_business_unit_types.png @path %}){: class="img-responsive"}

>Para guardar los cambios seleccionamos **Crear Tipo de unidad de negocio**


- **Nombre:** de la unidad organizativa, por ejemplo: Procesos Centrales.
- **Etiqueta de la unidad de negocio en el informe:** es una leyenda que aparece en el formato del informe (es opcional).


	* **Ejemplo 1:** si estamos trabajando con la unidad organizativa Procesos Centrales,  y la unidad de negocio Préstamos, podemos agregar como etiqueta CICLO, de esta manera cuando generemos el informe, va mostrarse de la siguiente manera: 
		+ **CICLO**: Préstamos  (corresponde a la descripción de la unidad de negocio).  
   &nbsp;
	* **Ejemplo 2:** si estamos trabajando con la unidad organizativa Sucursales, y la unidad de negocio Sucursal Buenos Aires, podemos agregar como etiqueta UNIDAD DE NEGOCIO, de esta manera cuando generemos el informe, va mostrarse de la siguiente manera:
		+ **UNIDAD DE NEGOCIO**: Sucursal Buenos Aires  (corresponde a la descripción de la unidad de negocio).  
	&nbsp;
	* **Ejemplo 3:** si estamos trabajando con la Unidad Organizativa Tecnología Informática, y la unidad de negocio Cumplimiento Comunicación “A” 4609, podemos agregar como etiqueta CICLO, de esta manera cuando generemos el informe, va mostrarse de la siguiente manera:
		+ **CICLO:** Cumplimiento Comunicación “A” 4609 (corresponde a la descripción de la unidad de negocio)
Etiqueta del proyecto en el informe (opcional): es una leyenda que aparece en el formato del informe.  
	&nbsp;

- Si estamos trabajando con la unidad organizativa Tecnología Informática, y la unidad de negocio Cumplimiento Comunicación “A” 4609, podemos agregar como etiqueta SUBCICLO, de esta manera cuando generemos el informe, va mostrarse de la siguiente manera:

	- **CICLO:** Cumplimiento Comunicación “A” 4609 (corresponde a la descripción de la unidad de negocio).

	- **SUBCICLO:** Sección 4 (corresponde a la descripción del nombre del proyecto).  
	&nbsp;

**2. Cómo agregar unidades de negocio a una unidad organizativa?**

A continuación mostramos como se agrega una unidad de negocio:
- Unidad organizativa: Sucursales
- Unidad de negocio: 1 - SUCURSAL BUENOS AIRES.

![]({% asset basic_process_flow/new_business_unit_types_with_data.png @path %}){: class="img-responsive"}

A continuación agregamos otra unidad de negocio a la unidad organizativa Sucursales:
Unidad de negocio: 2 - SUCURSAL SAN JUAN

![]({% asset basic_process_flow/new_business_unit_types_with_data_2.png @path %}){: class="img-responsive"}


Para que se guarden los cambios hay que seleccionar Actualizar Tipo de unidad de negocio
Si seleccionamos Listado: muestra las unidades organizativas creadas en el sistema.
Si seleccionamos Volver: vuelve a la pantalla anterior.

![]({% asset basic_process_flow/business_unit_types.png @path %}){: class="img-responsive"}

Las unidades organizativas se pueden Editar (lápiz).


A continuación editamos la unidad organizativa Procesos Centrales, la misma está compuesta por varias unidades de negocio.

![]({% asset basic_process_flow/edit_business_unit_types.png @path %}){: class="img-responsive"}

También podemos Ver (lupa) las unidades organizativas.
A continuación mostramos la unidad de organizativa Tecnología Informática, con sus correspondientes unidades de negocio.

![]({% asset basic_process_flow/show_business_unit_types.png @path %}){: class="img-responsive"}


### Buenas prácticas

Seleccionamos Administración -> Buenas prácticas.


Las buenas prácticas son la base del control interno de una organización. 
Una buena práctica se encuentra formada por procesos y estos por objetivos de control.
En las buenas prácticas se definen los controles a cumplir por la organización en los diferentes procesos. 
Los controles se revisan (chequean) por medio de pruebas (evaluación de diseño, pruebas de cumplimiento y pruebas sustantivas), las cuales permiten definir un grado de cumplimiento con los controles definidos (10% a 100% de cumplimiento).


A continuación mostramos como se carga una Nueva buena práctica:

![]({% asset basic_process_flow/new_best_practices.png @path %}){: class="img-responsive"}

**Nombre:** de la buena práctica.  
**Descripción:** es opcional.  
**Obsoleta:** si la tildamos, no vamos a poder utilizarla.  
**Compartida:** si la tildamos, vamos a poder utilizarla en otra organización que pertenezca al mismo grupo (no se puede volver para atrás).

Para generar la buena práctica, seleccionamos **Crear Buena Práctica**

**Proceso:** cargamos el proceso (por ejemplo: Operaciones activas).  
**Obsoleto:** si lo tildamos, no vamos a poder utilizar los controles y pruebas definidos en este proceso.  
Si seleccionamos la Flecha que se encuentra debajo de Procesos, aparece la opción agregar objetivo.  

Si seleccionamos Agregar objetivo muestra los datos a cargar.

![]({% asset basic_process_flow/processes.png @path %}){: class="img-responsive"}


Para que se guarde tenemos que seleccionar **Actualizar Buena práctica.**


A continuación mostramos un ejemplo de Procesos cargados en la Buena práctica Operaciones Activas:

En este caso los Procesos Controles generales de Activas y Acuerdos en Cuenta Corriente.

![]({% asset basic_process_flow/edit_process.png @path %}){: class="img-responsive"}


Luego mostramos, un ejemplo de un objetivo de control para el proceso Controles generales de Activas:

![]({% asset basic_process_flow/process_control_objective.png @path %}){: class="img-responsive"}

**Objetivo de control:** el resultado que se desea alcanzar mediante la implementación de procedimientos de control en los procesos de trabajo de una organización.


**Importancia:** del objetivo de control para el proceso en la organización. Los valores que puede tomar son Crítico (5), Alto (4), Moderado (3), Moderado/bajo (2), Bajo (1), Nulo (0). El valor depende de la incidencia que tiene el objetivo de control para cumplir con los objetivos y metas institucionales de la organización.


**Riesgo:** es la probabilidad de ocurrencia de un evento no deseado o la falta de ocurrencia de un evento si deseado y su impacto potencial para la organización. Puede tomar el valor Alto, Medio y Bajo. Este valor se obtiene de una evaluación de riesgos de cada objetivo de control para la organización en el momento actual.


**Soporte:** permite subir una plantilla de papel de trabajo que se quiera usar cuando se realiza el trabajo de campo. Después cuando los incorporan en un informe tienen para descargar ese archivo (tanto en la edición del informe como en la del objetivo de control).


**Obsoleto:** si lo tildamos, no vamos a poder utilizarlo en otros controles a realizar en la organización.


**Controles:** apoyan el cumplimento de los objetivos de control. Su ausencia provoca riesgos. Los procedimientos de control (preventivos, detectivos, correctivos, y proactivos) son todos los elementos de administración que una organización establece con la intención de lograr sus objetivos de control.


**Pruebas:** evalúan existencia y cumplimiento de controles. Proporcionan conocimiento y evidencia. Luego de realizada colocamos un valor entre 0 a 100% en base a la existencia y cumplimiento de los controles definidos.


**Evaluación de diseño:** las pruebas de diseño a realizar para poder revisar que se cumplan los controles definidos.


**Pruebas de cumplimiento:** las pruebas a realizar para poder revisar que se cumplan los controles definidos.


**Pruebas sustantivas:** las pruebas a realizar para poder revisar que se cumplan los controles definidos.


**Efecto:** se definen los temas que se pueden producir al no cumplirse con los controles definidos para cada uno de los objetivos de control (impacto en la organización). Es uno de los componentes del riesgo. Cualquier impacto (económico, patrimonial, en productividad, en servicio al cliente, en normatividad, en desarrollo institucional, posicionamiento competitivo, etc.) que afecte a una organización se refleja en los objetivos y metas de la organización. Es importante analizar el comportamiento del impacto en cada uno de los objetivos de control.


**Etiqueta:** podemos agregar etiquetas que han sido definidas en la etapa de Administración - Etiquetas, para luego poder identificar el objetivo de control en un filtro o reporte. 


A continuación mostramos un ejemplo de las buenas prácticas cargadas en esta organización:

![]({% asset basic_process_flow/best_practices.png @path %}){: class="img-responsive"}

Podemos Editar (Lápiz) una buena práctica cargada en el sistema, si lo seleccionamos muestra la siguiente pantalla.

![]({% asset basic_process_flow/edit_best_practice.png @path %}){: class="img-responsive"}

Podemos Ver (Lupa) una buena práctica cargada en el sistema, si la seleccionamos muestra la siguiente pantalla.

![]({% asset basic_process_flow/show_best_practice.png @path %}){: class="img-responsive"}