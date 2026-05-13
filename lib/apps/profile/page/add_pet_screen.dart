import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/profile/model/pet_dto.dart';
import 'package:petpee_mobile/apps/profile/api/pet_service.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final PetService _petService = PetService();
  bool _isLoading = false;

  String _name = '';
  String _speciesId = 'dog'; // Will map to speciesId: 1 for dog
  String _breed = '';
  String _gender = '';
  DateTime? _dob;
  String _note = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thêm thú cưng mới',
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
                        child: const Icon(
                          LucideIcons.camera,
                          color: Colors.grey,
                          size: 40,
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
                const SizedBox(height: 32),

                _buildTextField(
                  'Tên thú cưng (*)',
                  'Nhập tên...',
                  (v) => _name = v!,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        'Loại',
                        {
                          'dog': 'Chó',
                          'cat': 'Mèo',
                          'other': 'Khác',
                        }.entries.map((e) => e.value).toList(),
                        _speciesId == 'dog'
                            ? 'Chó'
                            : _speciesId == 'cat'
                            ? 'Mèo'
                            : 'Khác',
                        (v) => setState(() {
                          _speciesId = v == 'Chó'
                              ? 'dog'
                              : v == 'Mèo'
                              ? 'cat'
                              : 'other';
                        }),
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
        name: _name,
        speciesId: _speciesId == 'dog'
            ? 1
            : _speciesId == 'cat'
            ? 2
            : 3,
        gender: _gender.isEmpty ? null : _gender,
        breedText: _breed.isEmpty ? null : _breed,
        dob: _dob,
        note: _note.isEmpty ? null : _note,
      );

      await _petService.create(petDTO);
      if (mounted) {
        showAppToast(
          context,
          message: 'Thêm thú cưng thành công',
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

  Widget _buildTextField(
    String label,
    String hint,
    void Function(String?) onSaved, {
    bool isRequired = true,
    int maxLines = 1,
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
          value: value,
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
