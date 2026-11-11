# Privacidad y protección de datos (RGPD)

> **Aviso**: este documento es una guía técnica y una plantilla. El responsable
> del tratamiento (el departamento de psicología) debe revisar y adaptar los
> textos legales, el registro de actividades de tratamiento, la evaluación de
> impacto y los contratos con encargados antes de usar la app con pacientes
> reales.

## Roles

- **Responsable del tratamiento**: el departamento de psicología que facilita la
  app y decide para qué se usan los datos.
- **Encargado del tratamiento**: el proveedor tecnológico que aloja Firebase
  (Google Cloud), si se activa el modo conectado. Debe existir un contrato de
  encargo del tratamiento y una revisión de las cláusulas de Google.
- **Persona usuaria**: el paciente, que registra sus propias emociones.

## Datos tratados

- Seudónimo o identificador interno.
- Fecha y hora de los registros.
- Situación, emociones, intensidad, pensamiento, conducta y texto libre.
- Audio del dictado, solo mientras la persona activa el micrófono. La app no
  guarda grabaciones ni las envía a Firebase; el texto reconocido es lo único
  que se conserva si la persona decide guardarlo.
- Nombre del departamento.
- Fechas técnicas de creación, edición y aceptación de privacidad.
- Identificador técnico de la sesión (UID de la cuenta de Firebase o UUID local).
- Correo electrónico y contraseña de la cuenta, gestionados por Firebase
  Authentication. La contraseña se almacena cifrada por Firebase y la app nunca
  la guarda.

**No se solicitan**: nombre real, DNI, teléfono, dirección, geolocalización,
contactos ni datos de salud de terceros. El correo electrónico se usa solo para
crear la cuenta, iniciar sesión y recuperar la contraseña; no se copia a los
registros emocionales ni al perfil de Firestore.

Los datos emocionales pueden considerarse datos relativos a la salud (art. 9
RGPD) cuando permiten inferir el estado de salud de una persona. Por eso se
aplica minimización, consentimiento explícito y acceso restringido.

## Finalidad y base jurídica

- Finalidad: facilitar el autorregistro emocional entre sesiones y permitir al
  paciente compartir un informe con su psicóloga.
- Base jurídica: consentimiento explícito de la persona usuaria (art. 6.1.a y
  art. 9.2.a RGPD), recogido en el alta mediante una casilla no premarcada.
- El consentimiento puede retirarse en cualquier momento; la retirada no afecta
  a la licitud del tratamiento previo.

## Almacenamiento

### Modo local

Los datos se guardan en `shared_preferences` del dispositivo. No se envían a
ningún servidor. La protección depende del bloqueo y cifrado del propio
dispositivo. Si el paciente desinstala la app o borra sus datos, se pierden.

### Modo Firebase

- Firebase Authentication con cuenta de correo y contraseña. La contraseña la
  gestiona Firebase; la app no la almacena.
- Cloud Firestore con reglas que aíslan `users/{uid}/...`.
- Comunicación cifrada en tránsito (HTTPS/TLS) y cifrado en reposo de Google
  Cloud.
- No se usan Analytics, Crashlytics, publicidad ni rastreadores.

## Dictado por voz

El dictado es una alternativa opcional al teclado. Al pulsar el micrófono, la
app pide permiso para grabar y delega el reconocimiento en el servicio de voz
del sistema operativo (Google en Android, Apple en iOS), que puede procesar el
audio en línea según la configuración del dispositivo.

- La app no guarda grabaciones de audio.
- El audio no se envía a Firebase ni a servidores del departamento.
- Solo se conserva el texto reconocido que la persona revisa y decide guardar.
- La persona puede escribir con el teclado en cualquier momento, sin usar el
  micrófono.
- El responsable debe revisar si el proveedor del servicio de voz del sistema
  requiere un acuerdo adicional o aparece en el registro de actividades.

## Conservación

El responsable debe fijar un plazo concreto (por ejemplo, el tiempo que dure el
acompañamiento terapéutico más el plazo legal aplicable). La app no borra datos
automáticamente. El paciente puede eliminar registros y, en modo local, todos
sus datos desde Configuración.

En Firebase, para suprimir toda la información hay que borrar
`users/{uid}` y sus subcolecciones (Firestore no lo hace en cascada).

## Derechos de las personas

El paciente puede ejercer acceso, rectificación, supresión, limitación,
portabilidad y oposición, y retirar su consentimiento, dirigiéndose al
departamento de psicología. También puede reclamar ante la Agencia Española de
Protección de Datos (<https://www.aepd.es>).

La app facilita el acceso y la edición, pero la atención a los derechos se
gestiona por el canal que defina el responsable.

## Seguridad

- Minimización de datos y seudonimización.
- Autenticación individual con correo y contraseña; sin cuentas compartidas.
- Posibilidad de restablecer la contraseña por correo electrónico.
- Recomendación: activar la verificación de correo en Firebase para producción.
- Reglas de Firestore con aislamiento estricto por UID y validación de
  `patientId`.
- Sin credenciales ni claves en el repositorio; configuración por variables de
  compilación.
- PDF generado en el dispositivo; la app no lo sube a ningún servidor.
- Recomendación: activar bloqueo de pantalla, mantener el sistema actualizado y
  no compartir capturas con datos identificables.

## Evaluación de impacto y decisiones pendientes

Antes de un uso real, el responsable debería:

1. Confirmar si procede una evaluación de impacto (EIPD) por tratamiento de datos
   de salud a gran escala.
2. Definir la base jurídica y el plazo de conservación.
3. Revisar la información de privacidad y el consentimiento con asesoría legal.
4. Formalizar el encargo de tratamiento con el proveedor de Firebase.
5. Definir un protocolo de brechas de seguridad y un canal de contacto.
6. Decidir si se permite el uso en dispositivos compartidos (la app no tiene
   perfiles múltiples).
7. Definir el proceso de supresión de la cuenta: borrar el usuario de Firebase
   Authentication y sus datos en Firestore.
8. Valorar la verificación de correo y un panel de administración para el
   profesional.

## Riesgos conocidos

- El correo electrónico es un dato personal adicional; se limita a la
  autenticación y no se incluye en los registros emocionales.
- Quien conozca el correo y la contraseña puede acceder a la cuenta. Conviene
  exigir contraseñas robustas y activar la verificación de correo.
- No hay borrado de cuenta desde la app: debe gestionarlo el responsable.
- En modo local no hay inicio de sesión, copia de seguridad ni sincronización.
- Un dispositivo desbloqueado permite ver la app abierta.
- La compartición de un PDF saca los datos del control de la app; el paciente
  decide con quién lo comparte.

## Texto para el paciente

El texto completo está en `lib/core/constants/privacy_text.dart` y se muestra en
el alta y en Configuración. Debe mantenerse sincronizado con este documento y
con la versión `AppConfig.privacyVersion`.
