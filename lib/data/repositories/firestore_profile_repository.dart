import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';
import '../../models/patient_profile.dart';
import 'profile_repository.dart';

/// Perfil del paciente en `users/{uid}`.
///
/// Solo se guardan el seudónimo, el nombre del departamento y fechas técnicas.
/// No se solicita nombre real, teléfono ni correo.
class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String patientId) =>
      _db.collection('users').doc(patientId);

  @override
  Future<PatientProfile?> load(String patientId) async {
    try {
      final snapshot = await _user(patientId).get();
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return PatientProfile.fromJson(data);
    } catch (error) {
      throw StorageException(friendlyStorageError(error), cause: error);
    }
  }

  @override
  Future<void> save(PatientProfile profile) async {
    try {
      final data = profile.toJson();
      data['patientId'] = profile.patientId;
      await _user(profile.patientId).set(data, SetOptions(merge: true));
    } catch (error) {
      throw StorageException(friendlyStorageError(error), cause: error);
    }
  }
}
