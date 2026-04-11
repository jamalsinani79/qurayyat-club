class PlayerModel {
  final String cardId;
  final String name;
  final String birthDate;
  final String location;
  final String phone;
  final String? playerImg;
  final String? cardFront;
  final String? cardBack;
  final int? teamId;

  PlayerModel({
    required this.cardId,
    required this.name,
    required this.birthDate,
    required this.location,
    required this.phone,
    this.playerImg,
    this.cardFront,
    this.cardBack,
    this.teamId,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      cardId: json['card_id'] ?? '',
      name: json['name'] ?? '',
      birthDate: json['birth_date'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      playerImg: json['player_img'],
      cardFront: json['card_identy_front'],
      cardBack: json['card_identy_back'],
      teamId: json['team_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'name': name,
      'birth_date': birthDate,
      'location': location,
      'phone': phone,
      'player_img': playerImg,
      'card_identy_front': cardFront,
      'card_identy_back': cardBack,
      'team_id': teamId,
    };
  }
}
