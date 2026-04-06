import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

const _notificationsBox = 'notifications';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String? dataId;
  final DateTime receivedAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.dataId,
    required this.receivedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'body': body, 'type': type,
    'dataId': dataId, 'receivedAt': receivedAt.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromMap(Map m) => NotificationItem(
    id: m['id'] as String,
    title: m['title'] as String,
    body: m['body'] as String,
    type: m['type'] as String?,
    dataId: m['dataId'] as String?,
    receivedAt: DateTime.parse(m['receivedAt'] as String),
    isRead: m['isRead'] as bool? ?? false,
  );
}

Future<void> storeNotification(NotificationItem item) async {
  final box = await Hive.openBox(_notificationsBox);
  await box.put(item.id, item.toMap());
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final box = await Hive.openBox(_notificationsBox);
    final items = box.values
        .whereType<Map>()
        .map(NotificationItem.fromMap)
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.headlineMedium),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: AppTextStyles.headlineMedium),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotifTile(
                item: _items[i],
                onTap: () => _markRead(i),
              ),
            ),
    );
  }

  Future<void> _markRead(int index) async {
    final item = _items[index];
    item.isRead = true;
    final box = await Hive.openBox(_notificationsBox);
    await box.put(item.id, item.toMap());
    setState(() {});
  }

  Future<void> _clearAll() async {
    final box = await Hive.openBox(_notificationsBox);
    await box.clear();
    setState(() => _items = []);
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotifTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.surface
              : AppColors.accent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: item.isRead ? AppColors.divider : AppColors.primary,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isRead ? Colors.transparent : AppColors.primary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(item.body,
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(item.receivedAt),
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
