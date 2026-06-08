import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ltdd_qlhd_flutter/views/admin/admin_attendance_screen.dart';
import 'package:ltdd_qlhd_flutter/views/admin/admin_feedback_screen.dart';
import 'package:ltdd_qlhd_flutter/views/admin/admin_news_screen.dart';

import '../../controllers/admin_dashboard_controller.dart';
import '../../controllers/admin_notification_controller.dart';
import '../../models/admin_dashboard_stats.dart';
import '../../widgets/admin_drawer.dart';
import 'admin_notification_screen.dart';
import 'manage_activities_screen.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF1565C0);
  static const Color lightBackground = Color(0xFFF4F8FF);

  final AdminDashboardController _controller = AdminDashboardController();
  final AdminNotificationController _notificationController =
      AdminNotificationController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF0F172A) : lightBackground;

  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;

  Color get _textColor => _isDark ? Colors.white : const Color(0xFF0F172A);

  Color get _subTextColor =>
      _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  Color get _softBlue =>
      _isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD);

  Color get _gridColor =>
      _isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchAdminProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchActivities() {
    return _db.collection('activities').snapshots();
  }

  String _shortName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'Admin';
    if (parts.length == 1) return parts.first;

    return '${parts[parts.length - 2]} ${parts.last}';
  }

  String _adminNameFromData(Map<String, dynamic>? data) {
    final name = data?['name']?.toString().trim() ?? '';

    if (name.isEmpty) return 'Admin';

    return _shortName(name);
  }

  String _adminAvatarFromData(Map<String, dynamic>? data) {
    final avatar = data?['avatar']?.toString().trim() ?? '';
    final avatarUrl = data?['avatarUrl']?.toString().trim() ?? '';

    if (avatar.isNotEmpty) return avatar;

    return avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      drawer: AdminDrawer(
        selectedIndex: 0,
        onTapDashboard: () {
          Navigator.pop(context);
        },
        onTapManageActivities: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageActivitiesScreen()),
          );
        },
        onTapManageNews: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminNewsScreen()),
          );
        },
        onTapAttendance: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
          );
        },
        onTapFeedbacks: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
          );
        },
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<AdminDashboardStats>(
              stream: _controller.watchDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                final stats = snapshot.data;

                if (stats == null) {
                  return Center(
                    child: Text(
                      'Chưa có dữ liệu thống kê',
                      style: TextStyle(
                        color: _subTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Tổng quan"),
                      const SizedBox(height: 12),
                      _buildStatGrid(stats),
                      const SizedBox(height: 18),
                      _buildAttendanceCard(stats),
                      const SizedBox(height: 22),
                      _sectionTitle("Biểu đồ thống kê"),
                      const SizedBox(height: 12),
                      _buildCharts(stats),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'Không tải được thống kê.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _watchAdminProfile(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final adminName = _adminNameFromData(data);
        final avatarUrl = _adminAvatarFromData(data);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 8,
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
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
              const SizedBox(width: 6),
              _adminAvatar(avatarUrl, size: 42, whiteBg: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Xin chào, $adminName",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _notificationButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _notificationButton() {
    return StreamBuilder<int>(
      stream: _notificationController.watchUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminNotificationScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _adminAvatar(
    String avatarUrl, {
    required double size,
    required bool whiteBg,
  }) {
    final hasAvatar = avatarUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: hasAvatar ? EdgeInsets.zero : const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: whiteBg ? Colors.white : Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: whiteBg ? Colors.white : Colors.white.withOpacity(0.35),
        ),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _adminIcon(whiteBg);
                },
              )
            : _adminIcon(whiteBg),
      ),
    );
  }

  Widget _adminIcon(bool whiteBg) {
    return Icon(
      Icons.person_rounded,
      color: whiteBg ? primaryBlue : Colors.white,
      size: 28,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _textColor,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildStatGrid(AdminDashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.26,
      children: [
        _StatCard(
          icon: Icons.event_available_rounded,
          value: stats.totalActivities.toString(),
          label: "Hoạt động",
          cardColor: _cardColor,
          textColor: _textColor,
          subTextColor: _subTextColor,
          softBlue: _softBlue,
        ),
        _StatCard(
          icon: Icons.how_to_reg_rounded,
          value: stats.totalRegistrations.toString(),
          label: "Lượt đăng ký",
          cardColor: _cardColor,
          textColor: _textColor,
          subTextColor: _subTextColor,
          softBlue: _softBlue,
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          value: "${stats.attendancePercent}%",
          label: "Tỷ lệ điểm danh",
          cardColor: _cardColor,
          textColor: _textColor,
          subTextColor: _subTextColor,
          softBlue: _softBlue,
        ),
        _StatCard(
          icon: Icons.feedback_rounded,
          value: stats.pendingFeedbacks.toString(),
          label: "Góp ý chờ xử lý",
          cardColor: _cardColor,
          textColor: _textColor,
          subTextColor: _subTextColor,
          softBlue: _softBlue,
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(AdminDashboardStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tình hình điểm danh",
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Theo tổng lượt đăng ký hoạt động",
            style: TextStyle(
              color: _subTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _progressRow(
            label: "Đã điểm danh",
            value: stats.attendedCount,
            total: stats.totalRegistrations,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _progressRow(
            label: "Chờ xử lý",
            value: stats.waitingAttendanceCount,
            total: stats.totalRegistrations,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _progressRow(
            label: "Vắng",
            value: stats.absentCount,
            total: stats.totalRegistrations,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _progressRow({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final double percent = total <= 0 ? 0 : value / total;
    final int percentText = (percent * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              "$value/$total • $percentText%",
              style: TextStyle(
                color: _subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 1),
            minHeight: 9,
            backgroundColor: _gridColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCharts(AdminDashboardStats stats) {
    return Column(
      children: [
        _buildAttendancePieChart(stats),
        const SizedBox(height: 14),
        _buildCategoryBarChart(),
      ],
    );
  }

  Widget _buildAttendancePieChart(AdminDashboardStats stats) {
    final attended = stats.attendedCount;
    final waiting = stats.waitingAttendanceCount;
    final absent = stats.absentCount;
    final total = stats.totalRegistrations;

    final hasData = total > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tỷ lệ điểm danh",
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Đã điểm danh, chờ xử lý và vắng",
            style: TextStyle(
              color: _subTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 142,
                height: 142,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 38,
                        sectionsSpace: 3,
                        startDegreeOffset: -90,
                        borderData: FlBorderData(show: false),
                        sections: hasData
                            ? [
                                PieChartSectionData(
                                  value: attended.toDouble(),
                                  color: Colors.green,
                                  radius: 28,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: waiting.toDouble(),
                                  color: Colors.orange,
                                  radius: 28,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: absent.toDouble(),
                                  color: Colors.red,
                                  radius: 28,
                                  showTitle: false,
                                ),
                              ]
                            : [
                                PieChartSectionData(
                                  value: 1,
                                  color: _gridColor,
                                  radius: 28,
                                  showTitle: false,
                                ),
                              ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toString(),
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "lượt",
                          style: TextStyle(
                            color: _subTextColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _legendItem(
                      color: Colors.green,
                      title: "Đã điểm danh",
                      value: attended,
                    ),
                    const SizedBox(height: 10),
                    _legendItem(
                      color: Colors.orange,
                      title: "Chờ xử lý",
                      value: waiting,
                    ),
                    const SizedBox(height: 10),
                    _legendItem(
                      color: Colors.red,
                      title: "Vắng",
                      value: absent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String title,
    required int value,
  }) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _subTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            color: _textColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBarChart() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _watchActivities(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final Map<String, int> counts = {};

        for (final doc in docs) {
          final data = doc.data();
          final category = data['category']?.toString().trim() ?? 'Khác';
          final key = category.isEmpty ? 'Khác' : category;

          counts[key] = (counts[key] ?? 0) + 1;
        }

        final entries = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final items = entries.take(6).toList();
        final maxValue = items.isEmpty
            ? 1
            : items.map((e) => e.value).reduce(max);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hoạt động theo danh mục",
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Thống kê số hoạt động theo từng loại",
                style: TextStyle(
                  color: _subTextColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                Text(
                  "Chưa có dữ liệu hoạt động.",
                  style: TextStyle(
                    color: _subTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                SizedBox(
                  height: 230,
                  child: BarChart(
                    BarChartData(
                      maxY: maxValue.toDouble() + 1,
                      minY: 0,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(color: _gridColor, strokeWidth: 1);
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) {
                            return _isDark
                                ? const Color(0xFF334155)
                                : Colors.white;
                          },
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          tooltipBorderRadius: BorderRadius.circular(12),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = items[group.x.toInt()];

                            return BarTooltipItem(
                              '${item.key}\n${item.value} hoạt động',
                              TextStyle(
                                color: _textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) {
                                return const SizedBox.shrink();
                              }

                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: _subTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();

                              if (index < 0 || index >= items.length) {
                                return const SizedBox.shrink();
                              }

                              final label = items[index].key;

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: 54,
                                  child: Text(
                                    label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _subTextColor,
                                      fontSize: 10.5,
                                      height: 1.1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (int i = 0; i < items.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: items[i].value.toDouble(),
                                color: primaryBlue,
                                width: 18,
                                borderRadius: BorderRadius.circular(8),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxValue.toDouble() + 1,
                                  color: _gridColor.withOpacity(0.45),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(_isDark ? 0.22 : 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color softBlue;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.softBlue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: _FacultyDashboardScreenState.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
