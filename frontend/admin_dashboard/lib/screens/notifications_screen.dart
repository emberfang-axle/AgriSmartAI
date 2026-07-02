import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/notification_model.dart';
import '../providers/app_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  AdminNotifType? _typeFilter;
  bool _unreadOnly = false;

  List<AdminNotification> _filtered(List<AdminNotification> all) {
    var items = all;
    if (_typeFilter != null) items = items.where((n) => n.type == _typeFilter).toList();
    if (_unreadOnly) items = items.where((n) => !n.isRead).toList();
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = _filtered(provider.notifications);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Notifications',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDeepGreen)),
              Text('Real-time alerts and disease reports',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            const Spacer(),
            // Unread badge
            if (provider.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kErrorRed, borderRadius: BorderRadius.circular(12)),
                child: Text('${provider.unreadCount} unread',
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            OutlinedButton.icon(
              onPressed: provider.unreadCount > 0 ? provider.markAllRead : null,
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark all read'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showClearConfirm(context, provider),
              icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: kErrorRed),
              label: const Text('Clear all', style: TextStyle(color: kErrorRed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kErrorRed)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: kDeepGreen),
              onPressed: provider.refreshNotifications,
              tooltip: 'Refresh',
            ),
          ]),
          const SizedBox(height: 20),

          // Filter bar
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text('Filter:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 12),
                  Wrap(spacing: 8, children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _typeFilter == null && !_unreadOnly,
                      onSelected: (_) => setState(() {
                        _typeFilter = null;
                        _unreadOnly = false;
                      }),
                    ),
                    FilterChip(
                      label: const Text('Unread'),
                      selected: _unreadOnly,
                      onSelected: (v) => setState(() => _unreadOnly = v),
                    ),
                    ...AdminNotifType.values.map((t) => FilterChip(
                      label: Text(t.label),
                      selected: _typeFilter == t,
                      onSelected: (_) => setState(() {
                        _typeFilter = _typeFilter == t ? null : t;
                      }),
                      avatar: Icon(t.icon, size: 14, color: t.color),
                    )),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: Card(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.notifications_none_outlined,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _unreadOnly
                              ? 'No unread notifications'
                              : 'No notifications yet',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ]),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _NotifRow(
                        notif: filtered[i],
                        onTap: () => provider.markRead(filtered[i].id),
                        onDelete: () => provider.deleteNotification(filtered[i].id),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'This will permanently delete all notifications. Continue?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kErrorRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  final AdminNotification notif;
  final VoidCallback onTap, onDelete;
  const _NotifRow({required this.notif, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final t = notif.type;
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: kErrorRed,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: notif.isRead ? Colors.transparent : t.bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: t.color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(t.icon, color: t.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(notif.title,
                        style: TextStyle(
                          fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 14,
                        ))),
                    if (!notif.isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text(notif.body,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                      child: Text(t.label,
                          style: TextStyle(fontSize: 11, color: t.color,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text(_fmtTime(notif.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ]),
                ],
              )),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, hh:mm a').format(dt);
  }
}
