# igle-org

Igle Org es una aplicacion web para la administracion de iglesias dentro de una plataforma multi-iglesia. La meta es que varias iglesias puedan usar el mismo sistema, pero que cada una mantenga sus datos completamente separados.

El proyecto esta en fase de planificacion. La guia completa esta en [general planification.md](./general%20planification.md).

## Objetivo

Crear una plataforma que ayude a una iglesia a organizar miembros, usuarios, ministerios, junta administrativa, eventos, asistencia, ocupaciones, habilidades, directorio de servicios, reportes y permisos internos.

## Stack Definido

- Ruby on Rails 8.
- PostgreSQL.
- Docker para desarrollo.
- Tailwind CSS.
- Tailwind UI Pro como base visual.
- Devise para autenticacion.
- Pundit como base de autorizacion.
- Capa propia de permisos dinamicos por rol, modulo y accion.
- Active Storage para logos y fotos.
- DigitalOcean como destino de produccion.

## Modelo General

- La plataforma sera multi-iglesia.
- Cada iglesia sera independiente.
- Solo el super administrador podra crear iglesias.
- Cada iglesia tendra un administrador inicial con acceso completo administrativo.
- Un usuario global puede pertenecer a una o varias iglesias.
- Los datos principales se aislaran por `church_id`.

## Funcionalidades Del MVP

- Super administrador de plataforma.
- Registro y administracion de iglesias.
- Usuarios por iglesia.
- Miembros oficiales.
- Roles personalizados por iglesia.
- Matriz de permisos por rol.
- Ministerios.
- Junta administrativa opcional.
- Eventos y calendario.
- Confirmacion y registro de asistencia.
- Ocupaciones, habilidades y directorio de servicios.
- Solicitudes de cambio de perfil.
- Reportes y exportaciones.
- Pagina publica basica por iglesia.

## Roles Y Permisos

Cada iglesia podra crear sus propios roles. Los roles no tendran permisos fijos por nombre.

La matriz de permisos usara checkboxes por accion:

- Leer.
- Crear.
- Editar.
- Activar.
- Desactivar.
- Exportar.
- Administrar.

Tambien tendra atajos:

- Solo lectura.
- Lectura y escritura.
- Acceso completo.

Las notas pastorales seran visibles solo para roles pastorales autorizados.

## Junta Administrativa

La junta administrativa no es un rol y no otorga permisos automaticamente.

Los cargos definidos son:

- Presidente.
- Vicepresidente.
- Secretario.
- Tesorero.
- Vocal 1.
- Vocal 2.
- Vocal 3.
- Fiscal.

Cada cargo se asignara seleccionando un miembro activo de la iglesia.

## Decisiones Cerradas

- Nombre provisional: `igle-org`.
- Rails 8 como version objetivo.
- Docker desde desarrollo.
- Tailwind CSS y Tailwind UI Pro como base visual.
- DigitalOcean para produccion.
- Tarifa unica para iglesias; el monto se definira despues.
- Sin limites iniciales por cantidad de miembros o usuarios.
- Email del miembro opcional.
- Ocupacion, habilidades y ministerio se pueden completar despues.
- Finanzas, diezmos, ofrendas y gastos quedan para una fase futura.

## Fuera Del MVP

- Subdominios por iglesia.
- Pagos automaticos.
- App movil nativa.
- Notificaciones por email o WhatsApp.
- Importacion desde Excel.
- Visitantes.
- Documentos legales.
- Finanzas completas.

## Siguiente Paso

Iniciar la creacion del proyecto Rails con PostgreSQL, Tailwind y Docker siguiendo la planificacion general.
