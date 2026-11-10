/// Errores de negocio con mensajes en español listos para mostrar al paciente.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Convierte errores técnicos en mensajes comprensibles.
String friendlyStorageError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('permission-denied') || text.contains('permission')) {
    return 'No tienes permiso para acceder a estos datos. '
        'Revisa la sesión o contacta con tu psicóloga.';
  }
  if (text.contains('unavailable') || text.contains('network')) {
    return 'No hay conexión con el servidor. '
        'Puedes seguir escribiendo; vuelve a intentarlo más tarde.';
  }
  if (text.contains('quota')) {
    return 'Se ha alcanzado un límite temporal del servicio. '
        'Inténtalo de nuevo más tarde.';
  }
  if (text.contains('unauthenticated')) {
    return 'La sesión ha caducado. Vuelve a abrir la aplicación.';
  }
  return 'No se pudieron guardar los datos. Inténtalo de nuevo.';
}
