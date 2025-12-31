import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'booking_form_page.dart';

class HotelDetailPage extends StatefulWidget {
  final String hotelId;
  final String name;

  const HotelDetailPage({super.key, required this.hotelId, required this.name});

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  DateTime? startDate;
  DateTime? endDate;

  int adults = 2;
  int children = 0;
  List<int> childrenAges = [];

  Future<List<String>>? _bookedRoomsFuture;

  /* ---------------- HELPERS ---------------- */
  int get numberOfNights {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays;
  }

  int get totalPeople => adults + children;

  int get totalPeopleForPrice {
    final extraAdults = childrenAges.where((a) => a >= 12).length;
    return adults + extraAdults;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Tarih Seç";
    return DateFormat("dd.MM.yyyy").format(date);
  }

  /* ---------------- DATE PICKER ---------------- */
  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart
        ? (startDate ?? DateTime.now())
        : (endDate ??
              (startDate?.add(const Duration(days: 1)) ??
                  DateTime.now().add(const Duration(days: 1))));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStart
          ? DateTime.now()
          : (startDate?.add(const Duration(days: 1)) ?? DateTime.now()),
      lastDate: DateTime(2030),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;

        // Eğer çıkış tarihi seçilmiş ve yeni giriş tarihi çıkıştan büyükse sıfırla
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = null;
        }
      } else {
        // Çıkış tarihi seçiliyorsa giriş tarihi öncesi olamaz
        if (startDate != null && picked.isBefore(startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Çıkış tarihi girişten küçük olamaz")),
          );
          return;
        }
        endDate = picked;
      }

      if (startDate != null && endDate != null) {
        _bookedRoomsFuture = _getBookedRoomIds();
      }
    });
  }

  /* ---------------- BOOKINGS ---------------- */
  Future<List<String>> _getBookedRoomIds() async {
    if (startDate == null || endDate == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('hotelId', isEqualTo: widget.hotelId)
        .get();

    final List<String> bookedRoomIds = [];

    for (var doc in snap.docs) {
      final data = doc.data();

      DateTime? bookedStart;
      DateTime? bookedEnd;

      final checkIn = data['checkIn'];
      final checkOut = data['checkOut'];

      if (checkIn is Timestamp) {
        bookedStart = checkIn.toDate();
      } else if (checkIn is String) {
        bookedStart = DateTime.tryParse(checkIn);
      }

      if (checkOut is Timestamp) {
        bookedEnd = checkOut.toDate();
      } else if (checkOut is String) {
        bookedEnd = DateTime.tryParse(checkOut);
      }

      if (bookedStart == null || bookedEnd == null) continue;

      final overlap =
          bookedStart.isBefore(endDate!) && bookedEnd.isAfter(startDate!);

      if (overlap) {
        bookedRoomIds.add(data['roomId']);
      }
    }

    return bookedRoomIds;
  }

  /* ---------------- FETCH HOTEL IMAGES ---------------- */
  Future<List<String>> _fetchHotelImages() async {
    final doc = await FirebaseFirestore.instance
        .collection('hotelsImages')
        .doc(widget.hotelId)
        .get();

    if (!doc.exists) return [];
    final data = doc.data();
    return List<String>.from(data?['images'] ?? []);
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<List<String>>(
        future: _fetchHotelImages(),
        builder: (context, imageSnap) {
          if (imageSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!imageSnap.hasData || imageSnap.data!.isEmpty) {
            return const Center(child: Text("Resim yok"));
          }

          final images = imageSnap.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hotels')
                  .doc(widget.hotelId)
                  .snapshots(),
              builder: (context, hotelSnap) {
                if (!hotelSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hotel = hotelSnap.data!.data() as Map<String, dynamic>;
                final int hotelBasePrice = hotel['price'] ?? 0;
                final int stars = hotel['star'] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* HOTEL INFO */
                    Text(
                      "⭐ $stars yıldız",
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      "💰 $hotelBasePrice ₺ / gece",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),

                    /* HOTEL IMAGES */
                    const Text(
                      "Otel Resimleri",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        images[index],
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.broken_image,
                                                size: 50,
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  images[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    /* DATE PICKER */
                    const Text(
                      "Tarihler",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectDate(isStart: true),
                            child: Text(_formatDate(startDate)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectDate(isStart: false),
                            child: Text(_formatDate(endDate)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    /* GUEST COUNT */
                    const Text(
                      "Kişi Sayısı",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Yetişkin"),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: adults > 1
                                  ? () => setState(() => adults--)
                                  : null,
                            ),
                            Text(adults.toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => adults++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Çocuk"),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: children > 0
                                  ? () {
                                      setState(() {
                                        children--;
                                        childrenAges.removeLast();
                                      });
                                    }
                                  : null,
                            ),
                            Text(children.toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  children++;
                                  childrenAges.add(0);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (children > 0) ...[
                      const SizedBox(height: 8),
                      const Text("Çocuk Yaşları"),
                      Column(
                        children: List.generate(children, (i) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Çocuk ${i + 1}"),
                              DropdownButton<int>(
                                value: childrenAges[i],
                                items: List.generate(
                                  18,
                                  (age) => DropdownMenuItem(
                                    value: age,
                                    child: Text("$age"),
                                  ),
                                ),
                                onChanged: (v) =>
                                    setState(() => childrenAges[i] = v!),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 24),

                    /* ROOMS */
                    const Text(
                      "Uygun Odalar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rooms')
                          .where('hotelId', isEqualTo: widget.hotelId)
                          .snapshots(),
                      builder: (context, roomSnap) {
                        if (!roomSnap.hasData)
                          return const CircularProgressIndicator();
                        if (_bookedRoomsFuture == null)
                          return const Text("Lütfen tarih seçiniz");

                        return FutureBuilder<List<String>>(
                          future: _bookedRoomsFuture,
                          builder: (context, bookedSnap) {
                            if (bookedSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final bookedIds = bookedSnap.data ?? [];

                            return Column(
                              children: roomSnap.data!.docs.map((doc) {
                                final room = doc.data() as Map<String, dynamic>;
                                final capacity = room['capacity'];
                                final available = room['available'] == true;
                                final isBooked = bookedIds.contains(doc.id);

                                final canSelect =
                                    startDate != null &&
                                    endDate != null &&
                                    available &&
                                    !isBooked &&
                                    capacity >= totalPeople;

                                // PRICE CALCULATION
                                final roomMultiplier =
                                    room['priceMultiplier'] ?? 1.0;
                                final double multiplier = roomMultiplier is int
                                    ? roomMultiplier.toDouble()
                                    : roomMultiplier as double;
                                final double basePrice = hotelBasePrice is int
                                    ? hotelBasePrice.toDouble()
                                    : hotelBasePrice.toDouble();
                                final double hotelPrice =
                                    basePrice * multiplier;

                                return Card(
                                  child: ListTile(
                                    title: Text(room['name']),
                                    subtitle: Text(
                                      "Kapasite: $capacity • $hotelPrice ₺",
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: canSelect
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      BookingFormPage(
                                                        hotelId: widget.hotelId,
                                                        hotelName: widget.name,
                                                        roomId: doc.id,
                                                        roomName: room['name'],
                                                        pricePerNight:
                                                            hotelPrice,
                                                        numberOfNights:
                                                            numberOfNights,
                                                        adults: adults,
                                                        childrenAges:
                                                            childrenAges,
                                                        checkInDate: startDate!,
                                                        checkOutDate: endDate!,
                                                      ),
                                                ),
                                              );
                                            }
                                          : null,
                                      child: Text(isBooked ? "Dolu" : "Seç"),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
