// models/card_item.dart
class CardItem {
  final String id;
  String time;
  String note;
  bool enabled;

  CardItem({
    required this.id,
    required this.time,
    required this.note,
    this.enabled = true,
  });

  // 新增：转 Map
  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'note': note,
        'enabled': enabled,
      };

  // 新增：从 Map 构造
  factory CardItem.fromJson(Map<String, dynamic> json) => CardItem(
        id: json['id'],
        time: json['time'],
        note: json['note'],
        enabled: json['enabled'] ?? true,
      );
}