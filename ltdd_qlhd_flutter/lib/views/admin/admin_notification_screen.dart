import 'package:flutter/material.dart';

import '../../controllers/admin_notification_controller.dart';
import '../../models/admin_notification_model.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBackground = Color(0xFFF4F8FF);

  final AdminNotificationController _controller = AdminNotificationController();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF0F172A) : lightBackground;

  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;

  Color get _textColor => _isDark ? Colors.white : const Color(0xFF0F172A);

  Color get _subTextColor =>
      _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  Color get _softBlue =>
      _isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD);

  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<AdminNotificationModel>>(
              stream: _controller.watchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Không tải được thông báo.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(notifications[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<int>(
      stream: _controller.watchUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            right: 12,
            bottom: 16,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, darkBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              _BackButtonCard(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  unreadCount > 0 ? 'Thông báo ($unreadCount)' : 'Thông báo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (unreadCount > 0)
                TextButton(
                  onPressed: () async {
                    await _controller.markAllRead();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text(
                    'Đọc tất cả',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: primaryBlue,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa có thông báo',
              style: TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Các thông báo quản trị sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _subTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotificationModel notification) {
    final color = _controller.typeColor(notification.type);
    final icon = _controller.typeIcon(notification.type);
    final label = _controller.typeLabel(notification.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          if (!notification.isRead) {
            await _controller.markOneRead(notification.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? _cardColor
                : (_isDark ? const Color(0xFF172554) : const Color(0xFFEAF4FF)),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: notification.isRead
                  ? _borderColor
                  : primaryBlue.withOpacity(0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.22 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: _cardColor, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _typeBadge(label, color),
                        if (!notification.isRead)
                          _typeBadge('Chưa đọc', Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: _subTextColor,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: _subTextColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _controller.formatTime(notification.createdAt),
                          style: TextStyle(
                            color: _subTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (!notification.isRead)
                          Text(
                            'Chạm để đọc',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BackButtonCard extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButtonCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.32)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
