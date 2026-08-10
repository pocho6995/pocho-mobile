import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/driver_document.dart';
import '../../widgets/modern_dialog.dart';
import 'document_upload_page.dart';

class DriverDocumentsPage extends StatefulWidget {
  const DriverDocumentsPage({super.key});

  static const String routeName = '/delivery/driver-documents';

  @override
  State<DriverDocumentsPage> createState() => _DriverDocumentsPageState();
}

class _DriverDocumentsPageState extends State<DriverDocumentsPage> {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();
  
  List<DriverDocument> _documents = [];
  bool _isLoading = true;

  // Обязательные документы
  static const List<String> _requiredDocuments = [
    'passport',
    'driving_license',
    'vehicle_passport',
  ];

  // Опциональные документы
  static const List<String> _optionalDocuments = [
    'insurance',
    'photo',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final documents = await _deliveryRepository.getDocuments();
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ModernDialog.show(
          context: context,
          title: 'Ошибка',
          content: 'Не удалось загрузить документы: ${e.toString()}',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(
            label: 'OK',
            onPressed: () {},
          ),
        );
      }
    }
  }

  bool _isRequired(String documentType) {
    return _requiredDocuments.contains(documentType);
  }

  bool _hasAllRequiredDocuments() {
    final uploadedTypes = _documents.map((d) => d.documentType).toSet();
    return _requiredDocuments.every((type) => uploadedTypes.contains(type));
  }

  bool _areAllRequiredDocumentsApproved() {
    final requiredDocs = _documents.where(
      (d) => _isRequired(d.documentType),
    ).toList();
    return requiredDocs.isNotEmpty && 
           requiredDocs.every((d) => d.isApproved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Документы',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 360;
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Информационное сообщение
                        if (!_hasAllRequiredDocuments() || !_areAllRequiredDocumentsApproved())
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF59E0B).withOpacity(0.1),
                              const Color(0xFFF59E0B).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Требуются документы',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    !_hasAllRequiredDocuments()
                                        ? 'Загрузите все обязательные документы для проверки администратором'
                                        : 'Ожидайте проверки всех документов администратором',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: const Duration(milliseconds: 400))
                          .slideY(begin: -0.1, end: 0),
                    if (!_hasAllRequiredDocuments() || !_areAllRequiredDocumentsApproved())
                      const SizedBox(height: 20),
                        // Обязательные документы
                        Text(
                          'Обязательные документы',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: const Duration(milliseconds: 400))
                            .slideX(begin: -0.1, end: 0),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        ..._buildDocumentSection(_requiredDocuments, isSmallScreen),
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        // Опциональные документы
                        Text(
                          'Дополнительные документы',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              duration: const Duration(milliseconds: 400),
                              delay: const Duration(milliseconds: 200),
                            )
                            .slideX(begin: -0.1, end: 0),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        ..._buildDocumentSection(_optionalDocuments, isSmallScreen),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  List<Widget> _buildDocumentSection(List<String> documentTypes, bool isSmallScreen) {
    return documentTypes.map((type) {
      final document = _documents.firstWhere(
        (d) => d.documentType == type,
        orElse: () => DriverDocument(
          id: 0,
          driverId: 0,
          documentType: type,
          status: 'pending',
        ),
      );
      
      final index = documentTypes.indexOf(type);
      return _DocumentCard(
        document: document,
        isRequired: _isRequired(type),
        isSmallScreen: isSmallScreen,
        onTap: () async {
          final result = await Navigator.of(context).pushNamed(
            DocumentUploadPage.routeName,
            arguments: {
              'documentType': type,
              'existingDocument': document.id != 0 ? document : null,
            },
          );
          if (result == true) {
            // Обновляем список документов
            _loadDocuments();
          }
        },
      )
          .animate()
          .fadeIn(
            duration: const Duration(milliseconds: 400),
            delay: Duration(milliseconds: 300 + index * 100),
          )
          .slideX(
            begin: -0.2,
            end: 0,
            delay: Duration(milliseconds: 300 + index * 100),
          );
    }).toList();
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.isRequired,
    required this.onTap,
    this.isSmallScreen = false,
  });

  final DriverDocument document;
  final bool isRequired;
  final VoidCallback onTap;
  final bool isSmallScreen;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Одобрен';
      case 'pending':
        return 'На проверке';
      case 'rejected':
        return 'Отклонен';
      default:
        return 'Не загружен';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.add_circle_outline_rounded;
    }
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType) {
      case 'passport':
        return Icons.credit_card_rounded;
      case 'driving_license':
        return Icons.drive_eta_rounded;
      case 'vehicle_passport':
        return Icons.description_rounded;
      case 'insurance':
        return Icons.shield_rounded;
      case 'photo':
        return Icons.camera_alt_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(document.status);

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRequired
              ? statusColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: isRequired ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDocumentIcon(document.documentType),
                    color: statusColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              document.documentTypeName,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRequired) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Обязательно',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 8 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(document.status),
                            size: isSmallScreen ? 12 : 14,
                            color: statusColor,
                          ),
                          SizedBox(width: isSmallScreen ? 3 : 4),
                          Flexible(
                            child: Text(
                              _getStatusText(document.status),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: isSmallScreen ? 20 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
