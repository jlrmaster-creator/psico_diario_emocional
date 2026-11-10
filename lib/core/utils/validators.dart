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
}
