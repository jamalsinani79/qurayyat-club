class ClubModel {
  final String name;
  final String phone;

  ClubModel({required this.name, required this.phone});

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      name: json['name'],
      phone: json['phone'].toString(),

    );
  }
}
