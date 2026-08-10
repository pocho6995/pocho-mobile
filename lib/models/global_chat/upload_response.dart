import 'attachment.dart';
import 'global_chat_message.dart';

/// Модель ответа API при загрузке файла
class UploadResponse {
  final bool success;
  final String fileUrl;
  final Attachment attachment;
  final MessageType messageType;

  UploadResponse({
    required this.success,
    required this.fileUrl,
    required this.attachment,
    required this.messageType,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success: json['success'] as bool? ?? true,
      fileUrl: json['file_url'] as String,
      attachment: Attachment.fromJson(json['attachment'] as Map<String, dynamic>),
      messageType: MessageType.fromString(json['message_type'] as String),
    );
  }
}











