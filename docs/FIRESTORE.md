# Modelo de datos en Firestore

## Estructura

```text
users/{uid}
  ├── patientId: string          (igual a {uid})
  ├── pseudonym: string
  ├── departmentName: string
  ├── createdAt: string ISO-8601
  ├── updatedAt: string ISO-8601
  └── privacyAcceptedAt: string ISO-8601 (opcional)

  ├── records/{recordId}
  │     ├── id: string
  │     ├── patientId: string
  │     ├── eventDate: Timestamp   (día normalizado a 00:00)
  │     ├── createdAt: Timestamp
  │     ├── updatedAt: Timestamp
  │     ├── situation: string
  │     ├── emotions: array<map>   (ver abajo)
  │     ├── thought: string
  │     ├── behavior: string
  │     ├── freeText: string       (opcional)
  │     ├── eventTime: string      ("HH:mm", opcional)
  │     └── schemaVersion: number
  │
  └── customEmotions/{emotionId}
        ├── id: string
        ├── name: string
        ├── groupId: string
        ├── description: string    (opcional)
        ├── isCustom: true
        └── createdAt: Timestamp
```

Cada elemento de `emotions` tiene esta forma:

```json
{
  "emotionId": "tristeza_pena",
  "name": "Pena",
  "groupId": "tristeza",
  "groupName": "Tristeza",
  "intensity": 7
}
```

`intensity` se omite si el paciente no la indicó. Se guarda una copia del nombre
y del grupo para que el registro histórico no dependa del catálogo actual.

## Aislamiento por paciente

El UID procede de Firebase Authentication (cuenta con correo y contraseña). Las
reglas incluidas solo permiten a cada usuario acceder a su propio documento y
subcolecciones:

```text
request.auth != null && request.auth.uid == userId
```

Además, las reglas de escritura comprueban que `patientId` coincide con el UID
en el perfil y en los registros.

## Consultas

La app descarga los registros del usuario ordenados por `eventDate` descendente y
aplica los filtros de fecha, grupo y emoción en el cliente. Esto evita índices
compuestos y funciona con la caché offline de Firestore.

No se usan consultas globales ni colecciones compartidas. Un futuro panel para
profesionales requeriría un modelo de permisos distinto (roles, claims y reglas
específicas), que **no** forma parte de esta versión.

## Índices

`firestore.indexes.json` no declara índices compuestos porque las consultas
actuales solo ordenan por un campo. Si en el futuro se añaden filtros en servidor
(por ejemplo `where('eventDate', '>=', ...)` combinado con `orderBy`), habrá que
declarar el índice correspondiente y desplegarlo.

## Migraciones

- `schemaVersion` permite evolucionar el formato de los registros.
- `fromJson` tolera campos ausentes y valores nulos.
- Las fechas escritas por versiones antiguas como cadena ISO se siguen leyendo.
- Antes de cambiar el esquema, documenta la migración y prueba con datos reales
  anonimizados.

## Borrado

- Eliminar un registro borra su documento.
- Eliminar una emoción propia no altera los registros que ya la usaban.
- El borrado local (`Configuración > Borrar todos mis datos locales`) elimina
  perfil, registros y emociones propias de `shared_preferences`.
- Para ejercer el derecho de supresión en Firebase hay que borrar el documento
  `users/{uid}` y sus subcolecciones. Firestore no borra subcolecciones en
  cascada: usa la consola, la CLI o una Cloud Function administrativa.
