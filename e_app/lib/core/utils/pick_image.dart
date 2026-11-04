import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Cho người dùng chọn một ảnh từ thư viện, thu nhỏ rồi trả về dạng data URL base64
/// (`data:image/...;base64,...`) để gửi lên backend. Trả về null nếu người dùng huỷ.
/// Ném [Exception] nếu ảnh vẫn quá lớn sau khi thu nhỏ (backend giới hạn ~300KB).
Future<String?> pickImageDataUrl({double maxSide = 480, int quality = 70}) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: maxSide,
    maxHeight: maxSide,
    imageQuality: quality,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final mime =
      file.mimeType ?? (file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
  final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
  if (dataUrl.length > 380000) {
    throw Exception('Ảnh quá lớn, hãy chọn ảnh nhỏ hơn.');
  }
  return dataUrl;
}
