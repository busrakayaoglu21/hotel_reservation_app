import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hotel_list_page.dart';

class CityListPage extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const CityListPage({super.key, this.startDate, this.endDate});

  @override
  State<CityListPage> createState() => _CityListPageState();
}

class _CityListPageState extends State<CityListPage> {
  int? selectedCityId;
  String? selectedCityName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Otel Rezervasyonu")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cities').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cities = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButton<int>(
                  isExpanded: true,
                  value: selectedCityId,
                  hint: const Text("Şehir seçiniz"),
                  items: cities.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<int>(
                      value: data['id'],
                      child: Text(data['cityName']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final city =
                        cities
                                .firstWhere(
                                  (c) =>
                                      (c.data()
                                          as Map<String, dynamic>)['id'] ==
                                      value,
                                )
                                .data()
                            as Map<String, dynamic>;

                    setState(() {
                      selectedCityId = value;
                      selectedCityName = city['cityName'];
                    });
                  },
                ),

                const SizedBox(height: 24),

                if (selectedCityName != null)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HotelListPage(
                            cityId: selectedCityId!,
                            cityName: selectedCityName!,
                            startDate: widget.startDate,
                            endDate: widget.endDate,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.hotel),
                        title: const Text("Otelleri Gör"),
                        subtitle: Text("$selectedCityName için oteller"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
