---
title: Usuarios
layout: articles
category: administration
guide_order: 1
article_order: 3.1
parent: Seguridad
---

### Usuarios

Seleccionamos **Administración -> Seguridad -> Usuarios**

Esta opción **NO** se utiliza cuando el sistema se encuentra instalado en la infraestructura de la organización (en ese caso usamos la opción **Configurar LDAP**, y el alta de usuarios se realiza desde Active Directory).

Permite el alta de usuarios.

![]({% asset administration/security/users-1.png @path %}){: class="img-responsive"}

Para dar de alta un usuario seleccionamos **Nuevo**, muestra la siguiente pantalla.

![]({% asset administration/security/users-2.png @path %}){: class="img-responsive"}

Usuario: por defecto el usuario se define con la primera letra del nombre y el apellido (no obstante es opcional la forma de cargarlo en base a la política definida por la organización).

Nombre del usuario, Apellido del usuario.

Email: correo de la organización a la que pertenece.

Cargo: puesto que ocupa en la organización.

Notas: detalle de las modificaciones que se realizan en la parametrización del usuario (estos datos son cargados por los usuarios responsables de esta tarea, para mantener una trazabilidad en los cambios realizados en la historia de un usuario).

Tipo de recurso: función que cumple el usuario (auditor, auditado, etc.). Luego estos datos se utilizan para realizar los cálculos de costos de los recursos de personal (la parte de costos es opcional).

Lenguaje: se utiliza por defecto Español.

Conectado: se utiliza para ver si está conectado el usuario en el sistema.

Habilitado: este campo se habilita cuando se da de alta al usuario. Pasa a deshabilitado cuando caduca la contraseña del usuario. Automáticamente se habilita cuando el usuario restablece su contraseña.

Oculto: se utiliza en la baja del usuario, para que el mismo se encuentre oculto en los campos de búsqueda de usuarios.

Enviar notificación: cuando se tilda esta opción al usuario le llega un correo notificando de que fue dado de alta y puede acceder a través del link indicado en el correo.

Superior: se coloca el superior del usuario a los fines de definir la estructura jerárquica de la organización (esto es opcional).

Personal a cargo: se colocan usuarios que estén a cargo del usuario en cuestión (esta parte es opcional). El usuario puede ver los Hallazgos de todas las personas que tiene a cargo.

Usuario relacionado: se agregan aquellos usuarios que no dependen de la jerarquía, pero que a nivel de procesos o funcional necesitamos ver sus hallazgos (es opcional).

Organización: se agregan las organizaciones en las que el usuario va trabajar (por ejemplo: Demo), y el perfil correspondiente en la misma (Auditado, Auditor, Comité, Supervisor, Gerente de auditoria, Administrador).

A continuación damos de alta un usuario auditor:

Ingresamos los datos requeridos (*) y tenemos la posibilidad de agregar los opcionales.

![]({% asset administration/security/users-3.png @path %}){: class="img-responsive"}

Al finalizar seleccionamos **Actualizar Usuario**, para que se guarden lo datos.

En **Acciones** tenemos las siguientes opciones: **Estado**, **Reasignar responsabilidades**, **Liberar responsabilidades**.

En la opción **Estado**: muestra las observaciones de riesgo alto, y el estado de las observaciones.

Al seleccionar **Estado** muestra lo siguiente (del usuario que se encuentra logueado).

Permite visualizar los **Estados** en que se encuentran las observaciones (En proceso de implementación, Implementadas o Implementadas/auditadas).

También nos muestra el estado de las **pendientes** (vencidas, reprogramada vigente).

![]({% asset administration/security/users-4.png @path %}){: class="img-responsive"}

Si seleccionamos **Ver tabla** nos muestra el detalle en forma ordenada.

![]({% asset administration/security/users-5.png @path %}){: class="img-responsive"}

Y tenemos la posibilidad de seleccionar **Ver gráfico** (para volver a la parte gráfica).

![]({% asset administration/security/users-6.png @path %}){: class="img-responsive"}

También podemos ver los datos de la observación si seleccionamos uno de los estados de las observaciones, por ejemplo: **11 observaciones pendientes**.

![]({% asset administration/security/users-7.png @path %}){: class="img-responsive"}

En la opción **Reasignar responsabilidades**, permite pasar las observaciones a otro usuario, seleccionando el Nuevo responsable.

![]({% asset administration/security/users-8.png @path %}){: class="img-responsive"}

Se pueden reasignar responsabilidades a otro usuario con el mismo perfil (de auditor a auditor, y de auditado a auditado).

Siempre se mantiene la historia de los hallazgos. Al seleccionar Reasignar responsabilidades, se reasignan los hallazgos en estado “En proceso de implementación” e “Implementada”. Los hallazgos en estado “Implementada/auditada” se mantienen en el historial del usuario anterior. También aparece en el historial del nuevo usuario la fecha y de qué usuarios son los hallazgos asignados.

En la opción **Liberar responsabilidades**, permite liberar los hallazgos que tiene asignado un auditor o auditado (si queremos liberar las observaciones que tiene asignado un auditor, tiene que haber otro auditor asignado en la observación, lo mismo sucede con el auditado).

![]({% asset administration/security/users-9.png @path %}){: class="img-responsive"}

A continuación mostramos un ejemplo en donde el sistema no deja liberar responsabilidades de un auditor, debido a que la observación tiene asignado un solo auditor. El sistema muestra el mensaje de lo que debemos hacer.

![]({% asset administration/security/users-10.png @path %}){: class="img-responsive"}

Es importante aclarar que cuando generamos una observación como mínimo tenemos que asignar: 1 Auditor, 1 Auditado y 1 Supervisor o Gerente de auditoría.
