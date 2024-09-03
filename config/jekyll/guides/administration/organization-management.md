---
title: Gestión
layout: articles
category: administration
article_order: 2.1
parent: Organización
---

## Organización

### Gestión

Seleccionamos **Administración** -> **Organización**

Nos muestra las organizaciones generadas hasta el momento

![image]({{ site.baseurl }}/assets/images/administration/organization/org-1.png){: class="img-responsive"}

En el caso que no tengamos ninguna organización generada, seleccionamos **Nuevo**

Se cargan los siguientes datos de la organización: nombre, prefijo, y la descripción.

![image]({{ site.baseurl }}/assets/images/administration/organization/org-2.png){: class="img-responsive"}

Seleccionamos **Crear organización** para que se genere.

Luego de creada la organización se puede cargar el isologotipo. A continuación mostramos la vista global de la organización creada (por ejemplo en este caso: Demo):

![image]({{ site.baseurl }}/assets/images/administration/organization/org-3.png){: class="img-responsive"}

Luego mostramos los datos en detalle de la organización creada:

![image]({{ site.baseurl }}/assets/images/administration/organization/org-4.png){: class="img-responsive"}

#### Configuración LDAP

Esta opción es utilizada cuando el sistema es instalado en la infraestructura de la organización.

Se cargan los datos de acuerdo a la configuración de Active Directory informados por las áreas de sistemas y seguridad informática de la organización.

![image]({{ site.baseurl }}/assets/images/administration/organization/org-5.png){: class="img-responsive"}

<hr>

&nbsp;

&nbsp;

**Mejora funcionalidad**

Incorporamos la funcionalidad que permite realizar la autenticación e importación de usuarios en forma diaria de manera automática (es opcional, se puede seguir usando la alternativa de hacerlo en forma manual cuando lo decide la organización).

Si lo hacemos de manera automática, todos los días llega un correo a los supervisores y gerente de auditoría con los cambios realizados.

**Administración -> Organización**.

Seleccionamos ¨Administración¨ -> ¨Organización¨

![image]({{ site.baseurl }}/assets/images/administration/organization/org-6.png){: class="img-responsive"}

Seleccionamos ¨Editar¨ de la organización que necesitamos cargar los datos.

![image]({{ site.baseurl }}/assets/images/administration/organization/org-7.png){: class="img-responsive"}

Luego, seleccionamos ¨Configuración LDAP¨

Se cargan los datos de acuerdo a la configuración de Active Directory informados por las áreas de sistemas y seguridad informática de la organización.

Para la opción automática se agregaron dos campos: Usuario de servicio y Contraseña de servicio. Al finalizar la carga de datos seleccionamos ¨Actualizar Organización¨.

![image]({{ site.baseurl }}/assets/images/administration/organization/org-8.png){: class="img-responsive"}

Si lo hacemos de manera automática, todos los días llega un correo a los supervisores y gerente de auditoría como el siguiente:

![image]({{ site.baseurl }}/assets/images/administration/organization/org-9.png){: class="img-responsive"}
