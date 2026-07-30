/// آية واحدة من نص القرآن (بالرسم العثماني) زي ما بترجع من Al Quran Cloud API.
class AyahModel {
  final int numberInSurah;
  final String text;

  const AyahModel({required this.numberInSurah, required this.text});

  factory AyahModel.fromJson(Map<String, dynamic> json) => AyahModel(
        numberInSurah: json['numberInSurah'] as int,
        text: json['text'] as String,
      );

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'text': text,
      };
}
