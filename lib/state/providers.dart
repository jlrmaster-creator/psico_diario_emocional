import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/config/app_config.dart';
import '../core/services/firebase_bootstrap.dart';
import '../data/repositories/emotion_catalog_repository.dart';
import '../data/repositories/emotional_record_repository.dart';
import '../data/repositories/firestore_emotion_catalog_repository.dart';
import '../data/repositories/firestore_emotional_record_repository.dart';
import '../data/repositories/firestore_profile_repository.dart';
import '../data/repositories/local_emotion_catalog_repository.dart';
import '../data/repositories/local_emotional_record_repository.dart';
import '../data/repositories/local_profile_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/pdf_report_service.dart';
import '../models/emotion.dart';
import '../models/emotion_group.dart';
import '../models/emotional_record.dart';
import '../models/patient_profile.dart';
import '../models/record_filter.dart';
import '../models/selected_emotion.dart';

/// Sesión creada durante el arranque de la aplicación.
final appSessionProvider = Provider<AppSession>((ref) {
  throw StateError('appSessionProvider debe sobrescribirse en main.dart');
});

final recordRepositoryProvider = Provider<EmotionalRecordRepository>((ref) {
  final session = ref.watch(appSessionProvider);
  if (session.isFirebaseEnabled) {
    return FirestoreEmotionalRecordRepository();
  }
  return LocalEmotionalRecordRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final session = ref.watch(appSessionProvider);
  if (session.isFirebaseEnabled) {
    return FirestoreProfileRepository();
  }
  return LocalProfileRepository();
});

final catalogRepositoryProvider = Provider<EmotionCatalogRepository>((ref) {
  final session = ref.watch(appSessionProvider);
  if (session.isFirebaseEnabled) {
    return FirestoreEmotionCatalogRepository();
  }
  return LocalEmotionCatalogRepository();
});

final pdfReportServiceProvider = Provider<PdfReportService>(
  (ref) => const PdfReportService(),
);

/// Perfil del paciente. `null` significa que aún no ha completado el alta.
final profileProvider = AsyncNotifierProvider<ProfileNotifier, PatientProfile?>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<PatientProfile?> {
  @override
  Future<PatientProfile?> build() async {
    final session = ref.watch(appSessionProvider);
    return ref.watch(profileRepositoryProvider).load(session.patientId);
  }

  Future<PatientProfile> create({
    required String pseudonym,
    required String departmentName,
  }) async {
    final session = ref.read(appSessionProvider);
    final profile = PatientProfile.create(
      patientId: session.patientId,
      pseudonym: pseudonym.trim(),
      departmentName: departmentName.trim().isEmpty
          ? AppConfig.defaultDepartmentName
          : departmentName.trim(),
    );
    await ref.read(profileRepositoryProvider).save(profile);
    state = AsyncData(profile);
    return profile;
  }

  Future<PatientProfile> saveProfile({
    String? pseudonym,
    String? departmentName,
  }) async {
    final current = state.value;
    if (current == null) {
      throw StateError('Todavía no existe un perfil.');
    }
    final updated = current.copyWith(
      pseudonym: pseudonym?.trim(),
      departmentName: departmentName?.trim(),
      updatedAt: DateTime.now(),
    );
    await ref.read(profileRepositoryProvider).save(updated);
    state = AsyncData(updated);
    return updated;
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Catálogo base + emociones personalizadas del paciente.
final catalogProvider =
    AsyncNotifierProvider<EmotionCatalogNotifier, EmotionCatalog>(
      EmotionCatalogNotifier.new,
    );

class EmotionCatalogNotifier extends AsyncNotifier<EmotionCatalog> {
  @override
  Future<EmotionCatalog> build() async {
    final raw = await rootBundle.loadString(
      'assets/data/emotions_catalog.json',
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El catálogo de emociones no es válido.');
    }
    final base = EmotionCatalog.fromJson(decoded);

    final session = ref.watch(appSessionProvider);
    final custom = await ref
        .watch(catalogRepositoryProvider)
        .loadCustomEmotions(session.patientId);

    return base.withCustomEmotions(custom);
  }

  Future<Emotion> addCustomEmotion({
    required String name,
    required String groupId,
    String? description,
  }) async {
    final catalog = state.value ?? await future;
    final group = catalog.groupById(groupId) ?? catalog.groups.first;
    final session = ref.read(appSessionProvider);

    final emotion = Emotion(
      id: 'custom_${const Uuid().v4()}',
      name: name.trim(),
      groupId: group.id,
      description: description?.trim().isEmpty ?? true
          ? null
          : description!.trim(),
      isCustom: true,
    );

    await ref
        .read(catalogRepositoryProvider)
        .addCustomEmotion(session.patientId, emotion);

    ref.invalidateSelf();
    await future;
    return emotion;
  }

  Future<void> deleteCustomEmotion(String emotionId) async {
    final session = ref.read(appSessionProvider);
    await ref
        .read(catalogRepositoryProvider)
        .deleteCustomEmotion(session.patientId, emotionId);
    ref.invalidateSelf();
    await future;
  }
}

/// Todos los registros del paciente, ordenados del más reciente al más antiguo.
final recordsProvider =
    AsyncNotifierProvider<RecordsNotifier, List<EmotionalRecord>>(
      RecordsNotifier.new,
    );

class RecordsNotifier extends AsyncNotifier<List<EmotionalRecord>> {
  @override
  Future<List<EmotionalRecord>> build() async {
    final session = ref.watch(appSessionProvider);
    final repository = ref.watch(recordRepositoryProvider);
    return repository.fetchRecords(patientId: session.patientId);
  }

  Future<void> saveRecord(EmotionalRecord record) async {
    final repository = ref.read(recordRepositoryProvider);
    await repository.upsertRecord(record);
    ref.invalidateSelf();
    await ref.read(recordsProvider.future);
  }

  Future<void> deleteRecord(String recordId) async {
    final session = ref.read(appSessionProvider);
    final repository = ref.read(recordRepositoryProvider);
    await repository.deleteRecord(
      patientId: session.patientId,
      recordId: recordId,
    );
    ref.invalidateSelf();
    await ref.read(recordsProvider.future);
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Registros recientes para la pantalla de inicio.
final recentRecordsProvider = Provider<AsyncValue<List<EmotionalRecord>>>((
  ref,
) {
  return ref.watch(recordsProvider).whenData((records) {
    return records.take(3).toList(growable: false);
  });
});

final recordFilterProvider =
    NotifierProvider<RecordFilterNotifier, RecordFilter>(
      RecordFilterNotifier.new,
    );

class RecordFilterNotifier extends Notifier<RecordFilter> {
  @override
  RecordFilter build() => const RecordFilter();

  void apply(RecordFilter filter) => state = filter;

  void clear() => state = const RecordFilter();
}

/// Registros que cumplen el filtro activo del historial.
final filteredRecordsProvider = Provider<AsyncValue<List<EmotionalRecord>>>((
  ref,
) {
  final filter = ref.watch(recordFilterProvider);
  return ref.watch(recordsProvider).whenData((records) {
    return records.where(filter.matches).toList(growable: false);
  });
});

/// Registros de un día concreto (para el informe diario).
List<EmotionalRecord> recordsForDate(
  List<EmotionalRecord> records,
  DateTime date,
) {
  return records
      .where(
        (record) =>
            record.eventDate.year == date.year &&
            record.eventDate.month == date.month &&
            record.eventDate.day == date.day,
      )
      .toList(growable: false);
}

/// Construye un registro nuevo a partir de los datos del formulario.
EmotionalRecord buildRecord({
  required String patientId,
  required DateTime eventDate,
  required DateTime createdAt,
  required String situation,
  required List<SelectedEmotion> emotions,
  required String thought,
  required String behavior,
  String? freeText,
  String? eventTime,
  String? id,
}) {
  final now = DateTime.now();
  return EmotionalRecord(
    id: id ?? const Uuid().v4(),
    patientId: patientId,
    eventDate: DateTime(eventDate.year, eventDate.month, eventDate.day),
    createdAt: createdAt,
    updatedAt: now,
    situation: situation.trim(),
    emotions: emotions,
    thought: thought.trim(),
    behavior: behavior.trim(),
    freeText: freeText?.trim().isEmpty ?? true ? null : freeText!.trim(),
    eventTime: eventTime,
  );
}
