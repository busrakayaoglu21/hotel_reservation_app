import 'package:flutter/material.dart';

import 'package:hotel_reservation_app/city_list_page.dart';

import 'package:intl/intl.dart';

class BookingSummaryPage extends StatelessWidget {
  final String hotelName;
  final String roomName;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final List<int> childrenAges;

  const BookingSummaryPage({
    super.key,
    required this.hotelName,
    required this.roomName,
    this.checkIn,
    this.checkOut,
    required this.adults,
    required this.childrenAges,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rezervasyon Özeti")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🏨 Otel: $hotelName"),
            Text("🛏 Oda: $roomName"),
            Text("📅 Giriş: ${DateFormat('dd.MM.yyyy').format(checkIn!)}"),
            Text("📅 Çıkış: ${DateFormat('dd.MM.yyyy').format(checkOut!)}"),
            Text("👤 Yetişkin: $adults"),
            Text("👶 Çocuk: ${childrenAges.length}"),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CityListPage(startDate: checkIn, endDate: checkOut),
                  ),
                );
              },
              child: const Text("Ana Menüye Dön"),
            ),
          ],
        ),
      ),
    );
  }
}
