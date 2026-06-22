import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../constants/app_constants.dart';

class StorageService {
  /// Pick a PDF or DOC file. Always requests bytes so it works on web + mobile.
  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip', 'jpg', 'jpeg', 'png'],
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
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files;
    }
    return [];
  }

  /// Upload file to Cloudinary and return secure URL.
  Future<String?> uploadFile({
    required PlatformFile file,
    required String projectId,
    required int phaseNo,
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/auto/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = 'fyp_management_system/phases/$projectId/phase_$phaseNo';

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ),
        );
      } else {
        print('Upload failed: both file.bytes and file.path are null.');
        throw Exception('File data missing. Please try selecting the file again from a local folder.');
      }

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        print('Cloudinary upload failed with status ${response.statusCode}: $responseString');
        throw Exception('Cloudinary Error ${response.statusCode}: $responseString');
      }
    } catch (e) {
      print('Cloudinary upload exception: $e');
      throw Exception('Failed to connect to Cloudinary: $e');
    }
  }

  Future<void> deleteFile(String url) async {
    // Cloudinary unsigned upload generally doesn't allow unsigned delete without API secret or token
    // Assuming delete functionality is not heavily used or needed for the requested scope.
  }
}
