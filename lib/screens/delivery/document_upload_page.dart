import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/driver_document.dart';
import '../../widgets/modern_snackbar.dart';
import '../../widgets/safe_network_image.dart';
import '../../utils/image_url_helper.dart';

class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({
    super.key,
    required this.documentType,
    this.existingDocument,
  });

  final String documentType;
  final DriverDocument? existingDocument;

  static const String routeName = '/delivery/document-upload';

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();

  File? _frontImageFile;
  File? _backImageFile;
  String? _frontImageUrl;
  String? _backImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  bool get _needsBackImage {
    return widget.documentType == 'passport' ||
        widget.documentType == 'driving_license' ||
        widget.documentType == 'vehicle_passport';
  }

  String get _documentTypeName {
    switch (widget.documentType) {
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
        return widget.documentType;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingDocument != null) {
      _frontImageUrl = widget.existingDocument!.frontImageUrl;
      _backImageUrl = widget.existingDocument!.backImageUrl;
      _documentNumberController.text =
          widget.existingDocument!.documentNumber ?? '';
      if (widget.existingDocument!.issueDate != null) {
        _issueDateController.text = _formatDate(widget.existingDocument!.issueDate!);
      }
      if (widget.existingDocument!.expiryDate != null) {
        _expiryDateController.text = _formatDate(widget.existingDocument!.expiryDate!);
      }
    }
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _pickImage(String side, String source) async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (source == 'gallery') {
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } else if (source == 'camera') {
        pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      }

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      // Проверяем формат
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        if (mounted) {
          ModernSnackBar.showError(
            context,
            message: 'Поддерживаются только форматы: JPEG, PNG, WEBP',
          );
        }
        return;
      }

      setState(() {
        if (side == 'front') {
          _frontImageFile = imageFile;
          _frontImageUrl = null; // Сбрасываем URL при выборе нового файла
        } else {
          _backImageFile = imageFile;
          _backImageUrl = null;
        }
      });
    } catch (e) {
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Ошибка выбора изображения: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _uploadImage(String side) async {
    final imageFile = side == 'front' ? _frontImageFile : _backImageFile;
    if (imageFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await _deliveryRepository.uploadDocumentImage(imageFile);
      setState(() {
        if (side == 'front') {
          _frontImageUrl = imageUrl;
          _frontImageFile = null;
        } else {
          _backImageUrl = imageUrl;
          _backImageFile = null;
        }
        _isUploadingImage = false;
      });
      if (mounted) {
        ModernSnackBar.showSuccess(
          context,
          message: 'Изображение загружено',
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Ошибка загрузки изображения: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _submitDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_frontImageUrl == null && _frontImageFile == null) {
      ModernSnackBar.showError(
        context,
        message: 'Загрузите лицевую сторону документа',
      );
      return;
    }

    if (_needsBackImage && _backImageUrl == null && _backImageFile == null) {
      ModernSnackBar.showError(
        context,
        message: 'Загрузите обратную сторону документа',
      );
      return;
    }

    // Если выбраны новые файлы, сначала загружаем их
    if (_frontImageFile != null) {
      await _uploadImage('front');
      if (_frontImageUrl == null) return; // Ошибка загрузки
    }

    if (_backImageFile != null) {
      await _uploadImage('back');
      if (_needsBackImage && _backImageUrl == null) return; // Ошибка загрузки
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DateTime? issueDate;
      DateTime? expiryDate;

      if (_issueDateController.text.isNotEmpty) {
        final parts = _issueDateController.text.split('.');
        if (parts.length == 3) {
          issueDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      if (_expiryDateController.text.isNotEmpty) {
        final parts = _expiryDateController.text.split('.');
        if (parts.length == 3) {
          expiryDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      if (widget.existingDocument != null) {
        // Обновляем существующий документ
        await _deliveryRepository.updateDocument(
          documentType: widget.documentType,
          frontImageUrl: _frontImageUrl,
          backImageUrl: _backImageUrl,
          documentNumber: _documentNumberController.text.trim().isNotEmpty
              ? _documentNumberController.text.trim()
              : null,
          issueDate: issueDate,
          expiryDate: expiryDate,
        );
      } else {
        // Создаем новый документ
        await _deliveryRepository.uploadDocument(
          documentType: widget.documentType,
          frontImageUrl: _frontImageUrl!,
          backImageUrl: _backImageUrl,
          documentNumber: _documentNumberController.text.trim().isNotEmpty
              ? _documentNumberController.text.trim()
              : null,
          issueDate: issueDate,
          expiryDate: expiryDate,
        );
      }

      if (mounted) {
        ModernSnackBar.showSuccess(
          context,
          message: 'Документ успешно ${widget.existingDocument != null ? 'обновлен' : 'загружен'}',
        );
        Navigator.of(context).pop(true); // Возвращаем true для обновления списка
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Ошибка сохранения документа: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImagePicker(String side) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Выберите источник',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF6366F1)),
                title: const Text('Галерея'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(side, 'gallery');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1)),
                title: const Text('Камера'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(side, 'camera');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.existingDocument != null ? 'Редактировать документ' : 'Загрузить документ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isSmallScreen ? 18 : 20,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        size: isSmallScreen ? 40 : 48,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Text(
                      _documentTypeName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 400))
                  .slideY(begin: -0.2, end: 0),
              const SizedBox(height: 24),
              // Лицевая сторона
              Text(
                'Лицевая сторона',
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
                  ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              _ImageUploadCard(
                imageFile: _frontImageFile,
                imageUrl: _frontImageUrl,
                label: 'Лицевая сторона',
                onTap: () => _showImagePicker('front'),
                onUpload: _frontImageFile != null ? () => _uploadImage('front') : null,
                isUploading: _isUploadingImage,
                isSmallScreen: isSmallScreen,
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 300),
                  ),
              if (_needsBackImage) ...[
                SizedBox(height: isSmallScreen ? 20 : 24),
                // Обратная сторона
                Text(
                  'Обратная сторона',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                )
                    .animate()
                    .fadeIn(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 400),
                    ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                _ImageUploadCard(
                  imageFile: _backImageFile,
                  imageUrl: _backImageUrl,
                  label: 'Обратная сторона',
                  onTap: () => _showImagePicker('back'),
                  onUpload: _backImageFile != null ? () => _uploadImage('back') : null,
                  isUploading: _isUploadingImage,
                  isSmallScreen: isSmallScreen,
                )
                    .animate()
                    .fadeIn(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 500),
                    ),
              ],
              SizedBox(height: isSmallScreen ? 20 : 24),
              // Номер документа
              _ModernTextField(
                controller: _documentNumberController,
                label: 'Номер документа',
                hint: 'Введите номер документа',
                icon: Icons.numbers_rounded,
                delay: const Duration(milliseconds: 600),
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              // Дата выдачи
              _ModernTextField(
                controller: _issueDateController,
                label: 'Дата выдачи',
                hint: 'ДД.ММ.ГГГГ',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.datetime,
                delay: const Duration(milliseconds: 700),
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              // Дата окончания
              _ModernTextField(
                controller: _expiryDateController,
                label: 'Дата окончания',
                hint: 'ДД.ММ.ГГГГ',
                icon: Icons.event_rounded,
                keyboardType: TextInputType.datetime,
                delay: const Duration(milliseconds: 800),
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),
              // Кнопка сохранения
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Сохранить',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 900),
                  )
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    delay: const Duration(milliseconds: 900),
                  ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageUploadCard extends StatelessWidget {
  const _ImageUploadCard({
    required this.imageFile,
    required this.imageUrl,
    required this.label,
    required this.onTap,
    this.onUpload,
    this.isUploading = false,
    this.isSmallScreen = false,
  });

  final File? imageFile;
  final String? imageUrl;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onUpload;
  final bool isUploading;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return Container(
      height: isSmallScreen ? 160 : 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? const Color(0xFF6366F1) : Colors.grey.shade200,
          width: hasImage ? 2 : 1.5,
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
          onTap: hasImage ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageFile != null
                      ? Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : (imageUrl != null && imageUrl!.isNotEmpty
                          ? SafeNetworkImage(
                              imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              errorWidget: Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Фото не загружено',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_rounded,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Фото не загружено',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                ),
              if (!hasImage)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 48,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Text(
                        'Нажмите для выбора',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              if (hasImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      if (imageFile != null && onUpload != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_upload_rounded, size: 20),
                            onPressed: isUploading ? null : onUpload,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: onTap,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.delay = const Duration(milliseconds: 0),
    this.isSmallScreen = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final Duration delay;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        )
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: delay,
            )
            .slideX(begin: -0.1, end: 0),
        SizedBox(height: isSmallScreen ? 6 : 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 14 : 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: delay + const Duration(milliseconds: 100),
            )
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }
}

