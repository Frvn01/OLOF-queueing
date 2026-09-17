import 'package:flutter/foundation.dart';
import '../data/models/clinical_examination.dart';
import '../data/repositories/examination_repository.dart';

/// Provider for Nurse Station operations, clinical examinations and diagram history
class NurseProvider extends ChangeNotifier {
  final ExaminationRepository _repo = ExaminationRepository();

  List<Map<String, dynamic>> _groupedExams = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get groupedExams => _groupedExams;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all examinations for a patient, grouped by examination_uuid
  Future<void> loadExaminationsForPatient(String patientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groupedExams = await _repo.getGroupedExaminations(patientId);
    } catch (e) {
      _errorMessage = 'Failed to load examinations: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save / upload examination batch
  Future<bool> saveExaminationBatch(List<ClinicalExamination> exams) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repo.saveExaminationBatch(exams);
      if (exams.isNotEmpty) {
        await loadExaminationsForPatient(exams.first.patientId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save examination: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload rendered diagram image
  Future<String?> uploadDiagramImage({
    required String examinationUuid,
    required String viewName,
    required Uint8List bytes,
  }) async {
    return await _repo.uploadDiagramImage(
      examinationUuid: examinationUuid,
      viewName: viewName,
      bytes: bytes,
    );
  }

  /// Delete all views of an examination
  Future<bool> deleteExamination(String examinationUuid, String patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repo.deleteExaminationGroup(examinationUuid);
      await loadExaminationsForPatient(patientId);
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete examination: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export PNG image to local file
  Future<String> exportImageToFile(Uint8List bytes, String filename) async {
    return await _repo.exportImageToFile(bytes, filename);
  }
}
