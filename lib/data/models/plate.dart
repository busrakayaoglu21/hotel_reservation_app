class Plate {
  final int? id;
  final String plate;

  Plate({this.id, required this.plate});

  factory Plate.fromMap(Map<String, dynamic> map) =>
      Plate(id: map['id'], plate: map['plate']);

  Map<String, dynamic> toMap() => {'id': id, 'plate': plate};
}
