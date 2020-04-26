---
title: Perfiles y privilegios
layout: articles
category: administration
guide_order: 1
article_order: 3.3
parent: Seguridad
---
## Seguridad

### Perfiles y privilegios

Seleccionamos **Administración -> Seguridad -> Perfiles y privilegios**

Cada usuario debe tener por lo menos un **Perfil** (por ejemplo: auditado, auditor, comité, supervisor, gerente de auditoría, administrador) correspondiente a una determinada **Organización**.

Al **Perfil** definido en el sistema, hay que asignarle un **Tipo de Perfil **(auditado, auditor junior, auditor senior, comité, gerente, gerente de auditoría, supervisor), y una serie de **Privilegios** (permisos) que permiten el acceso a determinadas funcionalidades del sistema.

Luego en ejecución al crear un informe, tenemos que asignar el **¨Rol¨** que va cumplir este perfil (Auditado, Auditor, Gerente, Supervisor, Veedor).

Estos son los equivalentes, lo único que se mira es el "Tipo perfil", pueden definir tantos perfiles como quieran. Sería "Tipo de rol en el informe" -> "Tipo perfil":

&nbsp;

Rol | Tipo Perfil
--- | -------:
Auditado | Auditado - Gerente - Administrador
Auditor | Auditor Junior - Auditor Senior
Supervisor | Supervisor
Gerente  | Gerente de auditoría
Veedor | cualquier tipo

&nbsp;

A continuación mostramos un ejemplo de los perfiles básicos que tienen que estar cargados en el sistema para poder iniciar su uso.

![]({% asset administration/security/users-13.png @path %}){: class="img-responsive"}

A continuación mostramos los campos a completar para agregar un **Nuevo perfil** y sus privilegios (permisos).

![]({% asset administration/security/users-14.png @path %}){: class="img-responsive"}
![]({% asset administration/security/users-15.png @path %}){: class="img-responsive"}

Una vez cargados los datos de la pantalla anterior, seleccionamos **Crear Perfil**.

**Incorporamos la funcionalidad de gráficos y tablas.**
Permite ver gráficos y en una tabla el estado de las observaciones que corresponden a un usuario (auditor y auditado).

**Administración -> Seguridad -> Usuarios**

Seleccionamos Editar **->** Acciones **->** Estado

![]({% asset administration/security/users-16.png @path %}){: class="img-responsive"}
![]({% asset administration/security/users-17.png @path %}){: class="img-responsive"}

**Reporte para ver las observaciones pendientes y solucionadas de un usuario y de las personas que tiene a cargo**

**Administración -> Seguridad**.

![]({% asset administration/security/users-18.png @path %}){: class="img-responsive"}

Seleccionamos ¨Editar¨ del usuario que necesitamos, vamos al final de la pantalla y seleccionamos ¨Acciones¨ (podemos observar que el cargo de Supervisor tiene una persona a cargo).

![]({% asset administration/security/users-19.png @path %}){: class="img-responsive"}

Seleccionamos ¨Estado¨, nos muestra la siguiente pantalla.

![]({% asset administration/security/users-20.png @path %}){: class="img-responsive"}

A la derecha de la pantalla muestra un icono **¨Persona¨**, si hacemos clic vemos el listado de todas las observaciones del usuario y las personas que tengan a cargo.

![]({% asset administration/security/users-21.png @path %}){: class="img-responsive"}

Tenemos la posibilidad de ¨Descargar CSV¨ y ¨Resumen en PDF¨
