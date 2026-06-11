import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../domain/models/notification_model.dart';
import '../controllers/notification_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_read') {
                ref.read(notificationControllerProvider.notifier).markAllAsRead();
              } else if (value == 'clear_all') {
                _showClearAllDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 8),
                    Text('Mark All as Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          final today = <NotificationModel>[];
          final yesterday = <NotificationModel>[];
          final earlier = <NotificationModel>[];

          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final yesterdayStart = todayStart.subtract(const Duration(days: 1));

          for (final n in notifications) {
            if (n.timestamp.isAfter(todayStart)) {
              today.add(n);
            } else if (n.timestamp.isAfter(yesterdayStart)) {
              yesterday.add(n);
            } else {
              earlier.add(n);
            }
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
            children: [
              if (today.isNotEmpty) ...[
                _buildSectionHeader(context, 'Today'),
                ...today.map((n) => _buildNotificationItem(context, ref, n)),
              ],
              if (yesterday.isNotEmpty) ...[
                _buildSectionHeader(context, 'Yesterday'),
                ...yesterday.map((n) => _buildNotificationItem(context, ref, n)),
              ],
              if (earlier.isNotEmpty) ...[
                _buildSectionHeader(context, 'Earlier'),
                ...earlier.map((n) => _buildNotificationItem(context, ref, n)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        AppDimensions.spacingSm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, WidgetRef ref, NotificationModel notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color color;

    switch (notification.category) {
      case NotificationCategory.weight:
        icon = Icons.monitor_weight;
        color = Colors.blue;
        break;
      case NotificationCategory.nutrition:
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case NotificationCategory.fasting:
        icon = Icons.timer;
        color = Colors.purple;
        break;
      case NotificationCategory.aiCoach:
        icon = Icons.auto_awesome;
        color = AppColors.primary;
        break;
      case NotificationCategory.achievement:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case NotificationCategory.system:
        icon = Icons.settings;
        color = Colors.grey;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.spacingLg),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(notificationControllerProvider.notifier).deleteNotification(notification.id);
      },
      child: Material(
        color: notification.isRead
            ? Colors.transparent
            : (isDark ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primarySurface),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
            }
            if (notification.routePath != null) {
              context.push(notification.routePath!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingSm),
                          Text(
                            timeago.format(notification.timestamp, allowFromNow: true),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead) ...[
                  const SizedBox(width: AppDimensions.spacingSm),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all your notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationControllerProvider.notifier).clearAllNotifications();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
