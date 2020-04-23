---
title: Organización
layout: articles
category: administration
article_order: 2
has_children: true
---

### Organización - Gestión

Seleccionamos **Administración -> Organización -> Gestión**

Se cargan los siguientes datos de la organización: nombre, prefijo, y la descripción.

![]({% asset administration/organization/org-1.png @path %}){: class="img-responsive"}

Seleccionamos **Crear organización** para que se genere.

Luego de creada la organización se puede cargar el isologotipo. A continuación mostramos la vista global de la organización creada (por ejemplo en este caso: Demo):

![]({% asset administration/organization/org-2.png @path %}){: class="img-responsive"}

Luego mostramos los datos en detalle de la organización creada:

![]({% asset administration/organization/org-3.png @path %}){: class="img-responsive"}

### Configuración LDAP

Esta opción es utilizada cuando el sistema es instalado en la infraestructura de la organización.

Se cargan los datos de acuerdo a la configuración de Active Directory informados por las áreas de sistemas y seguridad informática de la organización.

![]({% asset administration/organization/org-4.png @path %}){: class="img-responsive"}

### Mejora funcionalidad

Incorporamos la funcionalidad que permite realizar la autenticación e importación de usuarios en forma diaria de manera automática (es opcional, se puede seguir usando la alternativa de hacerlo en forma manual cuando lo decide la organización).

&nbsp;

Si lo hacemos de manera automática, todos los días llega un correo a los supervisores y gerente de auditoría con los cambios realizados.

Seleccionamos **Administración -> Organización**

![]({% asset administration/organization/org-5.png @path %}){: class="img-responsive"}

Seleccionamos **Editar** de la organización que necesitamos cargar los datos.

![]({% asset administration/organization/org-6.png @path %}){: class="img-responsive"}

Luego, seleccionamos **Configuración LDAP**

Se cargan los datos de acuerdo a la configuración de Active Directory informados por las áreas de sistemas y seguridad informática de la organización.

Para la opción automática se agregaron dos campos: Usuario de servicio y Contraseña de servicio. Al finalizar la carga de datos seleccionamos **Actualizar Organización¨**.

![]({% asset administration/organization/org-7.png @path %}){: class="img-responsive"}

Si lo hacemos de manera automática, todos los días llega un correo a los supervisores y gerente de auditoria como el siguiente:

![]({% asset administration/organization/org-8.png @path %}){: class="img-responsive"}
