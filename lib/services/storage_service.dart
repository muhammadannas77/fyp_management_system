import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';


class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Pick a PDF or DOC file. Always requests bytes so it works on web + mobile.
  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip'],
      withData: true, // always load bytes — safe on web & mobile
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.first;
    }
    return null;
  }

  /// Pick multiple images for screenshots
  Future<List<PlatformFile>> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files;
    }
    return [];
  }

  /// Upload file to Firebase Storage and return download URL.
  Future<String?> uploadFile({
    required PlatformFile file,
    required String projectId,
    required int phaseNo,
  }) async {
    try {
      if (file.bytes == null) return null; // bytes always present due to withData:true

      final ext = file.name.contains('.') ? file.name.split('.').last : 'pdf';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_phase$phaseNo.$ext';

      final ref = _storage
          .ref()
          .child('phases')
          .child(projectId)
          .child('phase_$phaseNo')
          .child(fileName);

      String contentType;
      switch (ext.toLowerCase()) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          contentType = 'application/msword';
      }

      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putData(file.bytes!, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
