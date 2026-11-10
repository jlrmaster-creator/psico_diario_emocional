import '../../models/patient_profile.dart';

abstract interface class ProfileRepository {
  Future<PatientProfile?> load(String patientId);
  Future<void> save(PatientProfile profile);
}
