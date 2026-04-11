class TeamModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String messageCode;
  final String password;
  final String description;
  final String userFullname;
  final String logo;

  TeamModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.messageCode,
    required this.password,
    required this.description,
    required this.userFullname,
    required this.logo,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
  return TeamModel(
    id: json['id'],
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    messageCode: json['message_code']?.toString() ?? '',
    password: json['password']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    userFullname: json['user_fullname']?.toString() ?? '',
    logo: json['logo'] != null
        ? 'https://teams.quriyatclub.net/${json['logo']}'
        : '',
  );
}

}
