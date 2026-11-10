import '../../models/emotional_record.dart';
import '../../models/record_filter.dart';

/// Contrato de almacenamiento de registros emocionales.
///
/// Existe una implementación local (sin Firebase) y otra basada en Firestore.
/// La app elige una u otra según la configuración disponible.
abstract interface class EmotionalRecordRepository {
  Future<List<EmotionalRecord>> fetchRecords({
    required String patientId,
    RecordFilter filter = const RecordFilter(),
  });

  Future<void> upsertRecord(EmotionalRecord record);

  Future<void> deleteRecord({
    required String patientId,
    required String recordId,
  });
}
