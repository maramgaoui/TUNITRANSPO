enum NotificationType { chat, journey, system }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'system').toString();
    final timestampValue = json['timestamp'];

    DateTime parsedTime;
    if (timestampValue is DateTime) {
      parsedTime = timestampValue;
    } else if (timestampValue is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else if (timestampValue is String) {
      parsedTime = DateTime.tryParse(timestampValue) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: NotificationType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => NotificationType.system,
      ),
      timestamp: parsedTime,
      isRead: (json['isRead'] ?? false) == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
