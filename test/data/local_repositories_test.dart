import 'package:diario_emocional/data/repositories/local_emotion_catalog_repository.dart';
import 'package:diario_emocional/data/repositories/local_emotional_record_repository.dart';
import 'package:diario_emocional/data/repositories/local_profile_repository.dart';
import 'package:diario_emocional/models/emotion.dart';
import 'package:diario_emocional/models/emotional_record.dart';
import 'package:diario_emocional/models/patient_profile.dart';
import 'package:diario_emocional/models/record_filter.dart';
import 'package:diario_emocional/models/selected_emotion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalEmotionalRecordRepository records;
  late LocalProfileRepository profiles;
  late LocalEmotionCatalogRepository emotions;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    records = LocalEmotionalRecordRepository(preferences: prefs);
    profiles = LocalProfileRepository(preferences: prefs);
    emotions = LocalEmotionCatalogRepository(preferences: prefs);
  });

  EmotionalRecord record({
    required String id,
    required String patientId,
    DateTime? eventDate,
    String situation = 'Situación',
  }) {
    final date = eventDate ?? DateTime(2026, 11, 10);
    return EmotionalRecord(
      id: id,
      patientId: patientId,
      eventDate: date,
      createdAt: date,
      updatedAt: date,
      situation: situation,
      emotions: const [
        SelectedEmotion(
          emotionId: 'ira_enfado',
          name: 'Enfado',
          groupId: 'ira',
          groupName: 'Ira',
          intensity: 5,
        ),
      ],
      thought: 'Pensamiento',
      behavior: 'Conducta',
    );
  }

  test('guarda, actualiza, lista y elimina registros', () async {
    await records.upsertRecord(
      record(id: 'a', patientId: 'patient-1', situation: 'Primera'),
    );
    await records.upsertRecord(
      record(
        id: 'b',
        patientId: 'patient-1',
        eventDate: DateTime(2026, 11, 11),
        situation: 'Segunda',
      ),
    );

    final all = await records.fetchRecords(patientId: 'patient-1');
    expect(all, hasLength(2));
    expect(all.first.id, 'b', reason: 'Orden descendente por fecha');

    await records.upsertRecord(
      record(id: 'a', patientId: 'patient-1', situation: 'Actualizada'),
    );
    final updated = await records.fetchRecords(patientId: 'patient-1');
    expect(updated, hasLength(2));
    expect(
      updated.firstWhere((item) => item.id == 'a').situation,
      'Actualizada',
    );

    await records.deleteRecord(patientId: 'patient-1', recordId: 'a');
    final remaining = await records.fetchRecords(patientId: 'patient-1');
    expect(remaining.map((item) => item.id), <String>['b']);
  });

  test('aísla los registros por paciente', () async {
    await records.upsertRecord(record(id: 'a', patientId: 'patient-1'));
    await records.upsertRecord(record(id: 'b', patientId: 'patient-2'));

    final first = await records.fetchRecords(patientId: 'patient-1');
    final second = await records.fetchRecords(patientId: 'patient-2');

    expect(first.map((item) => item.id), <String>['a']);
    expect(second.map((item) => item.id), <String>['b']);
  });

  test('aplica filtros al leer', () async {
    await records.upsertRecord(
      record(id: 'a', patientId: 'patient-1', eventDate: DateTime(2026, 11, 1)),
    );
    await records.upsertRecord(
      record(
        id: 'b',
        patientId: 'patient-1',
        eventDate: DateTime(2026, 11, 10),
      ),
    );

    final filtered = await records.fetchRecords(
      patientId: 'patient-1',
      filter: RecordFilter(
        from: DateTime(2026, 11, 5),
        to: DateTime(2026, 11, 10),
      ),
    );

    expect(filtered.map((item) => item.id), <String>['b']);
  });

  test('guarda y recupera el perfil', () async {
    expect(await profiles.load('patient-1'), isNull);

    final profile = PatientProfile.create(
      patientId: 'patient-1',
      pseudonym: 'Luna',
      departmentName: 'Departamento de Psicología',
      now: DateTime(2026, 11, 10),
    );
    await profiles.save(profile);

    final loaded = await profiles.load('patient-1');
    expect(loaded, isNotNull);
    expect(loaded!.pseudonym, 'Luna');
    expect(loaded.privacyAcceptedAt, DateTime(2026, 11, 10));
  });

  test('gestiona emociones personalizadas', () async {
    const custom = Emotion(
      id: 'custom_1',
      name: 'Nostalgia',
      groupId: 'tristeza',
      description: 'Mezcla de cariño y pena',
      isCustom: true,
    );

    expect(await emotions.loadCustomEmotions('patient-1'), isEmpty);
    await emotions.addCustomEmotion('patient-1', custom);

    final loaded = await emotions.loadCustomEmotions('patient-1');
    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'Nostalgia');
    expect(loaded.single.isCustom, isTrue);

    await emotions.deleteCustomEmotion('patient-1', custom.id);
    expect(await emotions.loadCustomEmotions('patient-1'), isEmpty);
  });

  test('un JSON corrupto no rompe la lectura del diario', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'psico.records.patient-1': 'esto no es json',
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = LocalEmotionalRecordRepository(preferences: prefs);

    expect(await repository.fetchRecords(patientId: 'patient-1'), isEmpty);
    expect(prefs.getString('psico.records.patient-1.corrupt'), isNotNull);
  });
}
