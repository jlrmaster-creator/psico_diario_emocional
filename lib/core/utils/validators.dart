/// Validaciones de formularios compartidas.
class Validators {
  Validators._();

  static String? requiredText(
    String? value, {
    String fieldName = 'Este campo',
    int minLength = 1,
    int maxLength = 2000,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$fieldName es obligatorio.';
    if (text.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres.';
    }
    if (text.length > maxLength) {
      return '$fieldName no puede superar los $maxLength caracteres.';
    }
    return null;
  }

  static String? pseudonym(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe un nombre o seudónimo.';
    if (text.length < 2) return 'Debe tener al menos 2 caracteres.';
    if (text.length > 40) return 'No puede superar los 40 caracteres.';
    return null;
  }

  static String? departmentName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe el nombre del departamento.';
    if (text.length < 3) return 'Debe tener al menos 3 caracteres.';
    if (text.length > 80) return 'No puede superar los 80 caracteres.';
    return null;
  }

  static String? emotionName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe el nombre de la emoción.';
    if (text.length < 2) return 'Debe tener al menos 2 caracteres.';
    if (text.length > 40) return 'No puede superar los 40 caracteres.';
    return null;
  }

  /// Valida el correo usado para iniciar sesión.
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo electrónico.';
    if (text.length > 254) return 'El correo es demasiado largo.';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) {
      return 'Escribe un correo válido (ej.: nombre@ejemplo.com).';
    }
    return null;
  }

  /// Valida la contraseña de la cuenta.
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe tu contraseña.';
    if (text.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (text.length > 128) {
      return 'La contraseña no puede superar los 128 caracteres.';
    }
    return null;
  }
}
