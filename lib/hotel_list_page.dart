import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hotel_detail_page.dart';

class HotelListPage extends StatelessWidget {
  final int cityId;
  final String cityName;
  final DateTime? startDate;
  final DateTime? endDate;

  const HotelListPage({
    super.key,
    required this.cityId,
    required this.cityName,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$cityName Otelleri")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hotels')
            .where('cityId', isEqualTo: cityId)
            // .where('available', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Müsait otel bulunamadı"));
          }

          final hotels = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.hotel),
                  title: Text(hotel['name']),
                  subtitle: Text("${hotel['star']} ⭐ • ${hotel['price']} ₺"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelDetailPage(
                          hotelId: hotels[index].id,
                          name: hotel['name'], // ✅ EKLENDİ
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
