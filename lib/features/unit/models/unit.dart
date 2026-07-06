class Unit {
  final int id;
  final String name;

  Unit({required this.id, required this.name});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(id: json['unitId'] as int, name: json['name'] as String);
  }
}
