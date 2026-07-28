import 'moshaf_model.dart';

class ReciterModel {
  final int id;
  final String name;
  final String letter;
  final List<MoshafModel> moshaf;

  const ReciterModel({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshaf,
  });

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    final list = (json['moshaf'] as List<dynamic>? ?? [])
        .map((e) => MoshafModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReciterModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      letter: json['letter'] as String? ?? '',
      moshaf: list,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'letter': letter,
        'moshaf': moshaf.map((e) => e.toJson()).toList(),
      };

  MoshafModel? get defaultMoshaf => moshaf.isNotEmpty ? moshaf.first : null;

  String get avatarSeed => id.toString();
}
