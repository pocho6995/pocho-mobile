class DriverDocument {
  DriverDocument({
    required this.id,
    required this.driverId,
    required this.documentType,
    required this.status,
    this.frontImageUrl,
    this.backImageUrl,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.adminComment,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int driverId;
  final String documentType; // passport, driving_license, vehicle_passport, insurance, photo
  final String status; // pending, approved, rejected
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? adminComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  String get documentTypeName {
    switch (documentType) {
      case 'passport':
        return 'Паспорт';
      case 'driving_license':
        return 'Водительские права';
      case 'vehicle_passport':
        return 'Техпаспорт ТС';
      case 'insurance':
        return 'Страховка';
      case 'photo':
        return 'Фото водителя';
      default:
        return documentType;
    }
  }

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      documentType: json['document_type'] as String,
      status: json['status'] as String,
      frontImageUrl: json['front_image_url'] as String?,
      backImageUrl: json['back_image_url'] as String?,
      documentNumber: json['document_number'] as String?,
      issueDate: json['issue_date'] != null
          ? DateTime.parse(json['issue_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      adminComment: json['admin_comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'document_type': documentType,
      'status': status,
      'front_image_url': frontImageUrl,
      'back_image_url': backImageUrl,
      'document_number': documentNumber,
      'issue_date': issueDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'admin_comment': adminComment,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}





