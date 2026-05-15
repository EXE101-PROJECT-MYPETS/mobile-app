import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 80,
          leading: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFFFB7185),
              size: 16,
            ),
            label: const Text(
              'Back',
              style: TextStyle(color: Color(0xFFFB7185), fontSize: 14),
            ),
          ),
          title: Text(
            'Đơn mua',
            style: GoogleFonts.inter(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFFE91E63),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFFE91E63),
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đang xử lý'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã hoàn thành'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersList(),
            _OrdersList(), // Mock same data for all tabs for now
            _OrdersList(),
            _OrdersList(),
            _OrdersList(),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList();

  @override
  Widget build(BuildContext context) {
    final mockOrders = [
      {
        'shop': 'PETPEEs Mall',
        'status': 'Đang xử lý',
        'statusColor': Colors.blue,
        'orderId': 'DH-102931',
        'product': 'Gói spa cao cấp cho chó',
        'date': '08/03/2026',
        'price': '349.000đ',
      },
      {
        'shop': 'Spa House Official',
        'status': 'Đang giao',
        'statusColor': Colors.blue,
        'orderId': 'DH-102887',
        'product': 'Thức ăn mèo premium',
        'date': '06/03/2026',
        'price': '149.000đ',
      },
      {
        'shop': 'Doggo Planet',
        'status': 'Đã hoàn thành',
        'statusColor': Colors.green,
        'orderId': 'DH-102821',
        'product': 'Khám tổng quát cho chó',
        'date': '02/03/2026',
        'price': '259.000đ',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: mockOrders.length,
      itemBuilder: (context, index) {
        final order = mockOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 14,
                          color: Color(0xFFFB7185),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order['shop'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    order['status'] as String,
                    style: TextStyle(
                      color: order['statusColor'] as Color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Body card
              Text(
                'Mã đơn: ${order['orderId']}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Sản phẩm: ${order['product']}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Ngày tạo: ${order['date']}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),

              const SizedBox(height: 12),
              // Footer card
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  order['price'] as String,
                  style: const TextStyle(
                    color: Color(0xFFC62828), // Đỏ đậm
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
