import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'booking_summary_page.dart';

class BookingFormPage extends StatefulWidget {
  final String hotelId;
  final String hotelName;
  final String roomId;
  final String roomName;
  final double pricePerNight;
  final int numberOfNights;
  final int adults;
  final List<int> childrenAges;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  const BookingFormPage({
    super.key,
    required this.hotelId,
    required this.hotelName,
    required this.roomName,
    required this.pricePerNight,
    required this.numberOfNights,
    required this.adults,
    required this.childrenAges,
    required this.checkInDate,
    required this.checkOutDate,
    required this.roomId,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  late List<TextEditingController> guestControllers;

  int get chargeableGuestCount =>
      widget.adults + widget.childrenAges.where((age) => age >= 12).length;

  double get totalPrice =>
      (widget.pricePerNight * widget.numberOfNights * chargeableGuestCount)
          .toDouble();

  final TextEditingController hotelNameController = TextEditingController();
  final TextEditingController roomNameController = TextEditingController();
  DateTime? checkIn;
  DateTime? checkOut;

  int selectedAdults = 1;
  List<int> selectedChildrenAges = [];
  @override
  void initState() {
    super.initState();

    final totalGuests = widget.adults + widget.childrenAges.length;
    final extraGuests = totalGuests > 1 ? totalGuests - 1 : 0;

    guestControllers = List.generate(
      extraGuests,
      (_) => TextEditingController(),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitBooking() async {
    // Dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Firestore ekleme işlemi
      await FirebaseFirestore.instance.collection('bookings').add({
        'hotelId': widget.hotelId,
        'roomId': widget.roomId,
        'roomName': widget.roomName,
        'checkIn': Timestamp.fromDate(widget.checkInDate),
        'checkOut': Timestamp.fromDate(widget.checkOutDate),
        'adults': widget.adults,
        'childrenAges': widget.childrenAges,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Dialog kapat
      Navigator.of(context).pop();

      // BookingSummaryPage’e git ve önceki sayfaları temizle
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => BookingSummaryPage(
            hotelName: widget.hotelName,
            roomName: widget.roomName,
            checkIn: widget.checkInDate,
            checkOut: widget.checkOutDate,
            adults: widget.adults,
            childrenAges: widget.childrenAges,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      // Dialog kapat
      Navigator.of(context).pop();
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rezervasyonu Tamamla")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 24),

              const Text(
                "Ana Konuk Bilgileri",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _buildTextField(
                controller: nameController,
                label: "İsim Soyisim",
                keyboardType: TextInputType.name,
              ),
              _buildTextField(
                controller: phoneController,
                label: "Telefon",
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "E-posta"),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9@._\-+]'),
                  ),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "Bu alan zorunlu";
                  if (!v.contains('@')) return "Geçerli bir e-posta girin";
                  return null;
                },
              ),

              if (guestControllers.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  "Ek Konuklar",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],

              ...List.generate(guestControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildTextField(
                    controller: guestControllers[index],
                    label: "Konuk ${index + 2} İsim Soyisim",
                  ),
                );
              }),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitBooking,
                  child: const Text("Rezervasyonu Tamamla"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Otel: ${widget.hotelName}"),
            Text("Oda: ${widget.roomName}"),
            Text("Gece: ${widget.numberOfNights}"),
            Text("Fiyat / Gece: ${widget.pricePerNight} ₺"),
            Text("Giriş: ${_formatDate(widget.checkInDate)}"),
            Text("Çıkış: ${_formatDate(widget.checkOutDate)}"),
            const Divider(),
            Text(
              "Toplam Tutar: $totalPrice ₺",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label),
      validator: (v) =>
          v == null || v.trim().isEmpty ? "Bu alan zorunlu" : null,
    );
  }
}
