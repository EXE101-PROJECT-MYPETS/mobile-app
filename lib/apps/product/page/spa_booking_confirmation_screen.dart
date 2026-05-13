import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'spa_booking_success_screen.dart';

class SpaBookingConfirmationScreen extends StatefulWidget {
  final int selectedPackage;
  final int selectedTime;
  final int selectedPet;
  final DateTime selectedDate;

  const SpaBookingConfirmationScreen({
    super.key,
    required this.selectedPackage,
    required this.selectedTime,
    required this.selectedPet,
    required this.selectedDate,
  });

  @override
  State<SpaBookingConfirmationScreen> createState() =>
      _SpaBookingConfirmationScreenState();
}

class _SpaBookingConfirmationScreenState
    extends State<SpaBookingConfirmationScreen> {
  // 0: Đến tận nơi, 1: Shop đến đón
  int _transportOption = 0;
  final int _pickupFee = 50000;

  // Dữ liệu mock dựa trên index
  final _packages = [
    {'name': 'Cắt tỉa lông chuyên nghiệp', 'price': 450000, 'duration': '90m'},
    {'name': 'Tắm & Sấy tiêu chuẩn', 'price': 300000, 'duration': '45m'},
    {'name': 'Cắt móng & Vệ sinh tai', 'price': 200000, 'duration': '30m'},
  ];

  final _times = ['10:00 AM', '11:30 AM', '1:00 PM', '3:30 PM'];
  final _pets = ['Buddy (Chó)', 'Lucy (Mèo)'];

  @override
  Widget build(BuildContext context) {
    final package = _packages[widget.selectedPackage];
    final time = _times[widget.selectedTime];
    final pet = _pets[widget.selectedPet];

    // Tính tổng tiền
    int basePrice = package['price'] as int;
    int totalPrice = basePrice + (_transportOption == 1 ? _pickupFee : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Xác nhận Đặt lịch',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Phân tóm tắt dịch vụ
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.calendarCheck,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sunny Spa - CS1',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildSummaryRow(
                    LucideIcons.clock,
                    'Thời gian:',
                    '$time, ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(Icons.pets, 'Thú cưng:', pet),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    LucideIcons.timer,
                    'Thời lượng:',
                    package['duration'] as String,
                  ),
                ],
              ),
            ),

            // 2. Tùy chọn di chuyển
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn muốn sử dụng hình thức nào?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  // Lựa chọn 0: Đến tận nơi
                  GestureDetector(
                    onTap: () => setState(() => _transportOption = 0),
                    child: _buildTransportOption(
                      icon: LucideIcons.mapPin,
                      title: 'Đến tận nơi',
                      subtitle: 'Bạn sẽ đem bé trực tiếp đến Spa',
                      isSelected: _transportOption == 0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lựa chọn 1: Shop tới đón
                  GestureDetector(
                    onTap: () => setState(() => _transportOption = 1),
                    child: _buildTransportOption(
                      icon: LucideIcons.car,
                      title: 'Shop tới đón',
                      subtitle: 'Nhân viên sẽ đến đón bé tại nhà',
                      extraText: '+ 50.000đ',
                      isSelected: _transportOption == 1,
                    ),
                  ),

                  // Nhập địa chỉ nếu Chọn Shop tới đón
                  if (_transportOption == 1) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tòa nhà Lotte, 54 Liễu Giai, Ba Đình, Hà Nội',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Thay đổi',
                              style: TextStyle(
                                color: Colors.pink,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '${_formatCurrency(totalPrice)}đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.pink,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpaBookingSuccessScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Thanh Toán',
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
    );
  }

  Widget _buildTransportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    String? extraText,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.pink.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.pink : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.pink : Colors.grey.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.pink : Colors.black87,
                      ),
                    ),
                    if (extraText != null)
                      Text(
                        extraText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? Colors.pink : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int value) {
    final str = value.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = str[i] + result;
      count++;
    }
    return result;
  }
}
