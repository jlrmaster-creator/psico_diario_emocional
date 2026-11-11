import '../config/app_config.dart';

/// Textos de privacidad mostrados dentro de la aplicación.
///
/// El responsable del tratamiento debe revisarlos y adaptarlos a su organización
/// antes de publicar la app (ver `docs/PRIVACY.md`).
const String privacySummary = '''
Esta aplicación es una herramienta personal para registrar emociones entre sesiones de terapia.

• Solo se guarda un seudónimo, no tu nombre real.
• El correo electrónico se usa únicamente para acceder a tu cuenta.
• Tus registros son privados y solo tú puedes acceder a ellos desde tu sesión.
• La información se guarda en Firebase o, si no está configurado, únicamente en este dispositivo.
• Puedes consultar, editar, descargar y eliminar tus registros.
• Los informes PDF se generan cuando tú decides y se comparten solo si tú lo eliges.

Esta app no diagnostica, no interpreta automáticamente tus emociones y no sustituye la atención de un profesional de la psicología.
''';

const String privacyDetails = '''
RESPONSABLE DEL TRATAMIENTO
El departamento de psicología que te ha facilitado esta aplicación.

FINALIDAD
Facilitar el registro personal de emociones, situaciones, pensamientos y conductas entre sesiones, y permitir la generación de informes que tú puedes compartir voluntariamente con tu psicóloga.

DATOS QUE SE TRATAN
• Seudónimo o identificador interno del paciente.
• Correo electrónico y contraseña de la cuenta, gestionados por Firebase Authentication.
• Fecha, hora y contenido de los registros emocionales que tú escribes.
• Emociones seleccionadas e intensidad indicada.
• Preferencias básicas de la aplicación.

No se solicitan nombre real, teléfono ni datos de localización. El correo electrónico no se copia a los registros emocionales.

BASE JURÍDICA
Consentimiento explícito de la persona usuaria para el registro de datos relativos a la salud emocional, y consentimiento para el tratamiento por parte del departamento de psicología.

ALMACENAMIENTO
Firebase (Google Cloud) con cifrado en tránsito y en reposo, o almacenamiento local del dispositivo cuando Firebase no esté configurado. En modo local, los datos no se envían a ningún servidor.

CONSERVACIÓN
Los registros se conservan hasta que tú los elimines o hasta que el responsable del tratamiento establezca un plazo. Consulta con tu psicóloga el plazo aplicable.

DESTINATARIOS
No se comparten datos con terceros automáticamente. Los informes PDF solo se comparten cuando tú utilizas las opciones de compartir del teléfono.

DERECHOS
Puedes solicitar acceso, rectificación, supresión, limitación, portabilidad y oposición, así como retirar tu consentimiento, dirigiéndote al departamento de psicología. También puedes reclamar ante la Agencia Española de Protección de Datos (www.aepd.es).

SEGURIDAD
Acceso mediante correo y contraseña gestionados por Firebase Authentication, reglas de seguridad de Firestore que aíslan los datos por usuario, ausencia de credenciales en el código y minimización de datos.

ADVERTENCIA
La aplicación no realiza diagnósticos ni valoraciones clínicas. En caso de urgencia o crisis, contacta con los servicios sanitarios o de emergencia.
''';

const String privacyVersionLabel =
    'Versión de la información de privacidad: ${AppConfig.privacyVersion}';
