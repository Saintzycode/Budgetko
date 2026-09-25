import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/notifications/notification_triggers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => ref
                  .read(notificationsDaoProvider)
                  .markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: notifsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.textHint,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Alerts and updates will show up here',
                    style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: items.length,
            itemBuilder: (context, i) =>
                _NotificationTile(item: items[i]),
          );
        },
        loading: () => const Center(
          child: SpinKitRipple(
              color: AppColors.teal, size: 42),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(
                color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = _metaFor(item.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('notif-${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.expense
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: AppColors.expense,
            size: 22,
          ),
        ),
        onDismissed: (_) => ref
            .read(notificationsDaoProvider)
            .deleteNotification(item.id),
        child: GestureDetector(
          onTap: () => _openItem(context, ref),
          child: GlowContainer(
            glowColor: item.isRead
                ? AppColors.bgSurface
                : AppColors.teal,
            glowRadius: item.isRead ? 6 : 12,
            padding: const EdgeInsets.all(14),
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: meta.color
                        .withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(meta.icon,
                      color: meta.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: AppColors
                                    .textPrimary,
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration:
                                  const BoxDecoration(
                                color: AppColors.teal,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.relativeDate(
                            item.createdAt),
                        style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openItem(
      BuildContext context, WidgetRef ref) async {
    if (!item.isRead) {
      await ref
          .read(notificationsDaoProvider)
          .markAsRead(item.id);
    }
    if (!context.mounted) return;
    final route = notificationRouteFor(item.payload);
    if (route != null) context.go(route);
  }

  ({IconData icon, Color color}) _metaFor(String type) {
    return switch (type) {
      'overspend' => (
          icon: Icons.warning_amber_outlined,
          color: AppColors.expense
        ),
      'goal' => (
          icon: Icons.flag_outlined,
          color: AppColors.savings
        ),
      'quickadd' => (
          icon: Icons.bolt_outlined,
          color: AppColors.teal
        ),
      'recurring' => (
          icon: Icons.repeat_outlined,
          color: AppColors.teal
        ),
      'daily' => (
          icon: Icons.alarm_outlined,
          color: AppColors.warning
        ),
      _ => (
          icon: Icons.notifications_outlined,
          color: AppColors.textSecondary
        ),
    };
  }
}
