---
title: Unidades organizativas
layout: articles
category: administration
guide_order: 1
article_order: 2.2
parent: Organización
---
## Organización

### Unidades organizativas

Seleccionamos **Administración -> Organización -> Unidades organizativas**

Las unidades organizativas están compuestas por unidades de negocio (por ejemplo, Unidad organizativa: Procesos Centrales, está compuesta por las Unidades de negocio: Préstamos, Depósitos, Finanzas, Comercio Exterior y Cambios, Contabilidad, etc.)

**1)** ¿Cómo cargamos una unidad organizativa para la organización?

A continuación mostramos un ejemplo de las unidades organizativas necesarias para el área de auditoría interna de un Banco:

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-1.png){: class="img-responsive"}

Para agregar una unidad organizativa, seleccionamos **Nuevo**, muestra la siguiente pantalla (los datos indicados con * son obligatorios)

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-2.png){: class="img-responsive"}

Para guardar los cambios seleccionamos **Crear Tipo de unidad de negocio**

\* Nombre: de la unidad organizativa, por ejemplo: Procesos Centrales.

\* Etiqueta de la unidad de negocio en el informe: es una leyenda que aparece en el formato del informe.

* **Ejemplo 1:** si estamos trabajando con la unidad organizativa Procesos Centrales,  y la unidad de negocio Préstamos, podemos agregar como etiqueta CICLO, de esta manera cuando generemos el informe, va mostrarse de la siguiente manera:

  > **CICLO:** Préstamos  (corresponde a la descripción de la unidad de negocio).

* **Ejemplo 2:** si estamos trabajando con la unidad organizativa Sucursales, y la unidad de negocio Sucursal Buenos Aires, podemos agregar como etiqueta UNIDAD DE NEGOCIO, de esta manera cuando generemos el informe, va mostrarse de la siguiente manera:

  > **UNIDAD DE NEGOCIO:** Sucursal Buenos Aires  (corresponde a la descripción de la unidad de negocio).

* **Ejemplo 3:** si estamos trabajando con la Unidad Organizativa Tecnología Informática, y la unidad de negocio Cumplimiento Comunicación "A" 4609, podemos agregar como etiqueta CICLO, de esta manera cuando generemos el informe, va mostrarse de la siguiente manera:

  > **CICLO:** Cumplimiento Comunicación "A" 4609 (corresponde a la descripción de la unidad de negocio)

Etiqueta del proyecto en el informe (opcional): es una leyenda que aparece en el formato del informe.

* Si estamos trabajando con la unidad organizativa Tecnología Informática, y la unidad de negocio Cumplimiento Comunicación "A" 4609, podemos agregar como etiqueta SUBCICLO, de esta manera cuando generemos el informe, va mostrarse de la siguiente manera:

  > **CICLO:** Cumplimiento Comunicación "A" 4609 (corresponde a la descripción de la unidad de negocio).<br>
  > **SUBCICLO:** Sección 4 (corresponde a la descripción del nombre del proyecto cargada en el plan de trabajo).

<hr>

&nbsp;

&nbsp;

**2)** cómo agregar unidades de negocio a una unidad organizativa?

A continuación mostramos como se agrega una unidad de negocio:

> Unidad organizativa: Sucursales<br>
> Unidad de negocio: 1 - SUCURSAL BUENOS AIRES.

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-3.png){: class="img-responsive"}

A continuación agregamos otra unidad de negocio a la unidad organizativa Sucursales:

> Unidad de negocio: 2 - SUCURSAL SAN JUAN

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-4.png){: class="img-responsive"}

Para que se guarden los cambios hay que seleccionar **Actualizar Tipo de unidad de negocio**

Si seleccionamos **Listado**: muestra las unidades organizativas creadas en el sistema.

Si seleccionamos **Volver**: vuelve a la pantalla anterior.

Las unidades organizativas se pueden **Editar** (lápiz).

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-5.png){: class="img-responsive"}

A continuación editamos la unidad organizativa Procesos Centrales, la misma está compuesta por varias unidades de negocio.

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-6.png){: class="img-responsive"}

También podemos **Ver** (lupa) las unidades organizativas.

A continuación mostramos la unidad de organizativa Tecnología Informática, con sus correspondientes unidades de negocio.

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-7.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

Ejemplo de la funcionalidad organización corporativa.

**Administración -> Organización**

Seleccionamos ¨Organización¨.

> Nos muestra todas las organizaciones creadas para este grupo (Demo, Demo 1, Demo 2 y Demo BI), para este caso "Demo 2" es la organización corporativa.

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-8.png){: class="img-responsive"}

Luego seleccionamos ¨Editar¨ de la organización que tiene en la columna ¨Corporativa¨ Si.

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-9.png){: class="img-responsive"}

En la organización corporativa, se darán de alta a los usuarios corporativos y a quién designe la organización.

Los usuarios incorporados pueden interactuar en el circuito de observaciones de las 4 Organizaciones.

Además, los usuarios que se encuentren registrados en la Organización "Demo 2", van a poder ver datos del resto de las organizaciones con las siguientes opciones:
> **Seguimiento -> Hallazgos pendientes**<br>
> **Seguimiento -> Hallazgos solucionados**

A continuación mostramos un ejemplo para estas opciones.

**Seguimiento -> Hallazgos pendientes**

Seleccionar Seguimiento -> Hallazgos pendientes¨, muestra los hallazgos pendientes de todas las organizaciones.

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-10.png){: class="img-responsive"}

Si necesitamos ver solo de una organización, seleccionamos ¨Buscar¨, ingresamos el prefijo de la Organización que deseamos consultar (por ejemplo Demo-bi) y luego volvemos a seleccionar ¨Buscar¨.

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-11.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

Campo **¨Requerir etiqueta en informe¨**

**Administración -> Organización -> Unidades organizativas**

Se agregó el campo "Requerir etiqueta en informe". Cuando lo seleccionen, todos los informes de unidades de ese tipo van a requerir al menos una etiqueta al momento de la creación/modificación.

![image]({{ site.baseurl }}/assets/images/administration/organization/bu-12.png){: class="img-responsive"}
