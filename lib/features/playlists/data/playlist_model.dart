import '../../player/data/queue_item.dart';

/// قائمة تشغيل مخصّصة بيعملها المستخدم بنفسه، ممكن يحط فيها أي سورة بأي
/// قارئ من أي مكان في التطبيق (زي البلاي ليست في ساوند كلاود).
class Playlist {
  final String id;
  final String name;
  final int createdAt;
  final List<QueueItem> items;

  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.items,
  });

  Playlist copyWith({String? name, List<QueueItem>? items}) => Playlist(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'items': items.map(QueueItem.encode).toList(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: json['createdAt'] as int,
        items: (json['items'] as List)
            .map((e) => QueueItem.decode(e as String))
            .toList(),
      );
}
