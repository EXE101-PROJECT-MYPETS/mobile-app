import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/apps/profile/model/pet_dto.dart';
import 'package:pawly_mobile/apps/profile/model/pet_model.dart';
import 'package:pawly_mobile/apps/profile/api/pet_service.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
import 'package:pawly_mobile/apps/profile/model/pet_species_dto.dart';
import 'dart:io';

class AddPetScreen extends StatefulWidget {
  final PetModel? pet;

  const AddPetScreen({super.key, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final PetService _petService = PetService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  String _name = '';
  String _speciesId = '';
  String _breed = '';
  String _gender = '';
  DateTime? _dob;
  String _note = '';
  XFile? _avatarFile;

  bool get _isEditing => widget.pet != null;

  List<PetSpeciesDTO> _speciesList = [];
  bool _isLoadingSpecies = false;

  @override
  void initState() {
    super.initState();
    _loadSpecies();
    final pet = widget.pet;
    if (pet != null) {
      _name = pet.name;
      _breed = pet.breedText ?? '';
      _gender = pet.gender ?? '';
      _dob = pet.dob;
      _note = pet.note ?? '';
      _speciesId = pet.speciesId?.toString() ?? '';
    }
  }

  Future<void> _loadSpecies() async {
    setState(() => _isLoadingSpecies = true);
    try {
      final species = await _petService.getSpecies();
      setState(() {
        _speciesList = species;
        if (_speciesId.isEmpty && species.isNotEmpty) {
          _speciesId = species.first.id.toString();
        }
      });
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          message: 'Lỗi tải danh sách loài: $e',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSpecies = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Cập nhật thú cưng' : 'Thêm thú cưng mới',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Placeholder
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipOval(
                            child: _avatarFile != null
                                ? Image.file(
                                    File(_avatarFile!.path),
                                    fit: BoxFit.cover,
                                  )
                                : (widget.pet?.avatarUrl != null &&
                                      widget.pet!.avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    widget.pet!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      LucideIcons.camera,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  )
                                : const Icon(
                                    LucideIcons.camera,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE91E63),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(
                  'Tên thú cưng (*)',
                  'Nhập tên...',
                  (v) => _name = v!,
                  initialValue: _name,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _isLoadingSpecies
                          ? const Center(child: CircularProgressIndicator())
                          : _buildDropdownField(
                              'Loại',
                              _speciesList.map((e) => e.name).toList(),
                              _speciesList.any(
                                    (e) => e.id.toString() == _speciesId,
                                  )
                                  ? _speciesList
                                        .firstWhere(
                                          (e) => e.id.toString() == _speciesId,
                                        )
                                        .name
                                  : (_speciesList.isNotEmpty
                                        ? _speciesList.first.name
                                        : ''),
                              (v) {
                                if (v != null) {
                                  setState(() {
                                    _speciesId = _speciesList
                                        .firstWhere((e) => e.name == v)
                                        .id
                                        .toString();
                                  });
                                }
                              },
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField(
                        'Giới tính',
                        ['Đực', 'Cái'],
                        _gender.isEmpty ? 'Đực' : _gender,
                        (v) => setState(() => _gender = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Giống loài',
                  'VD: Golden Retriever...',
                  (v) => _breed = v!,
                  isRequired: false,
                  initialValue: _breed,
                ),
                const SizedBox(height: 16),

                _buildDateField(
                  'Ngày sinh',
                  (date) => setState(() => _dob = date),
                  isRequired: false,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Ghi chú',
                  'Thông tin thêm...',
                  (v) => _note = v!,
                  maxLines: 3,
                  isRequired: false,
                  initialValue: _note,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Lưu thông tin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    if (_name.isEmpty) {
      showAppToast(
        context,
        message: 'Vui lòng nhập tên thú cưng',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final petDTO = PetDTO(
        id: widget.pet?.id,
        name: _name,
        shopId: widget.pet?.shopId,
        customerId: widget.pet?.customerId,
        speciesId: int.tryParse(_speciesId),
        gender: _gender.isEmpty ? null : _gender,
        breedText: _breed.isEmpty ? null : _breed,
        dob: _dob,
        note: _note.isEmpty ? null : _note,
      );

      if (_isEditing && widget.pet?.id != null) {
        await _petService.update(
          widget.pet!.id!,
          petDTO,
          avatarFile: _avatarFile,
        );
      } else {
        await _petService.create(petDTO, avatarFile: _avatarFile);
      }
      if (mounted) {
        showAppToast(
          context,
          message: _isEditing
              ? 'Cập nhật thú cưng thành công'
              : 'Thêm thú cưng thành công',
          type: AppToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, message: 'Lỗi: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (!mounted || picked == null) return;

    setState(() {
      _avatarFile = picked;
    });
  }

  Widget _buildTextField(
    String label,
    String hint,
    void Function(String?) onSaved, {
    bool isRequired = true,
    int maxLines = 1,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          maxLines: maxLines,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Vui lòng nhập thông tin';
            }
            return null;
          },
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    void Function(DateTime) onChanged, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate:
                  _dob ?? DateTime.now().subtract(const Duration(days: 365)),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _dob != null
                  ? _dob!.toLocal().toString().split(' ')[0]
                  : 'Chọn ngày sinh',
              style: TextStyle(
                color: _dob != null ? Colors.black87 : Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String value,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
