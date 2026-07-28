class MoshafModel {
  final int id;
  final String name;
  final int rewayaId;
  final String server;
  final int surahTotal;
  final int moshafType;
  final List<int> surahList;

  const MoshafModel({
    required this.id,
    required this.name,
    required this.rewayaId,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  factory MoshafModel.fromJson(Map<String, dynamic> json) {
    final rawList = (json['surah_list'] as String? ?? '').trim();
    final parsedList = rawList.isEmpty
        ? <int>[]
        : rawList.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e > 0).toList();

    return MoshafModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      rewayaId: json['rewaya_id'] as int? ?? 0,
      server: json['server'] as String? ?? '',
      surahTotal: json['surah_total'] as int? ?? 0,
      moshafType: json['moshaf_type'] as int? ?? 0,
      surahList: parsedList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rewaya_id': rewayaId,
        'server': server,
        'surah_total': surahTotal,
        'moshaf_type': moshafType,
        'surah_list': surahList.join(','),
      };

  bool hasSurah(int surahNumber) => surahList.contains(surahNumber);
}
