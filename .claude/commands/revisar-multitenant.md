---
description: Audita el código actual buscando violaciones del aislamiento multi-tenant
---

Revisa el archivo o cambio actual y reporta cualquier posible violación del aislamiento multi-tenant del proyecto `igle-org`.

Reglas a verificar:

1. **`church_id` obligatorio.** Toda tabla operativa debe tener `church_id`. Una migración nueva que cree una tabla operativa sin `church_id` indexado es una violación.
2. **Scopes filtran por iglesia.** Cualquier `Model.where(...)`, `Model.find(...)`, `Model.all`, `Model.first` sobre una tabla operativa debe estar acotado por la iglesia actual (vía `current_church` o un scope explícito). Reporta cada query que no lo haga.
3. **Asociaciones no cruzan iglesias.** Un `belongs_to`/`has_many` que apunte a otra tabla operativa debe validar que ambos lados pertenecen a la misma iglesia. Revisa validaciones tipo `validate :same_church`.
4. **Polimórficas con `church_id`.** Si encuentras una relación polimórfica (`addressable`, `contactable`, etc.), la tabla polimórfica debe tener `church_id` propio.
5. **Permisos.** Ninguna autorización debe depender del nombre del rol (`role.name == "Pastor"`). Toda decisión pasa por `Permissions::PermissionChecker`.
6. **Notas pastorales.** Acceso bloqueado salvo rol con `pastoral: true` + permiso explícito sobre el módulo `pastoral_notes`.
7. **Borrado físico.** `destroy`, `delete_all`, `destroy_all` en tablas operativas → violación (excepto tablas de unión que se rehacen).
8. **Vistas públicas.** En controladores/vistas `Public::*` no debe filtrarse información sensible (teléfono, dirección, fecha de nacimiento, notas).

Formato del reporte:

- Lista cada hallazgo como `archivo:línea` + tipo de violación + explicación breve + sugerencia de fix.
- Si no hay violaciones, di explícitamente "Sin violaciones detectadas" y lista qué verificaste.
- No modifiques código en este comando — solo audita.

Si el usuario te pasó un argumento ($ARGUMENTS), enfoca la revisión solo en ese archivo o directorio. Si no, revisa los archivos modificados (`git diff --name-only`).
