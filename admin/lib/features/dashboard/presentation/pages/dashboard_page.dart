import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/providers/api_providers.dart';
import '../../../../core/theme/app_theme.dart';

class BackendDashboardMetrics {
  const BackendDashboardMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalProfiles,
    required this.activeProfiles,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalProfiles;
  final int activeProfiles;

  factory BackendDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return BackendDashboardMetrics(
      totalUsers: json['totalUsers'] as int? ?? 0,
      activeUsers: json['activeUsers'] as int? ?? 0,
      totalProfiles: json['totalProfiles'] as int? ?? 0,
      activeProfiles: json['activeProfiles'] as int? ?? 0,
    );
  }
}

final backendMetricsProvider = FutureProvider.autoDispose<BackendDashboardMetrics>((ref) async {
  final ipAddress = await ref.watch(ec2IpProvider.future);
  
  try {
    final response = await http.get(Uri.parse('https://$ipAddress/api/admin/dashboard'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return BackendDashboardMetrics.fromJson(data);
    } else {
      throw Exception('Server returned status code ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to connect to API backend at $ipAddress: $e');
  }
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(backendMetricsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContent =
            constraints.maxWidth >= 1500 ? 1480.0 : double.infinity;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContent),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    onRefresh: () {
                      ref.invalidate(ec2IpProvider);
                      ref.invalidate(backendMetricsProvider);
                    },
                  ),
                  const SizedBox(height: 24),
                  metricsAsync.when(
                    data: (m) => _MetricsGrid(
                      totalUsers: m.totalUsers,
                      activeUsers: m.activeUsers,
                      totalProfiles: m.totalProfiles,
                      activeProfiles: m.activeProfiles,
                    ),
                    loading: () => const SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'API connection failed: $e. Showing mock preview data.',
                                  style: const TextStyle(
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF92400E)),
                                onPressed: () {
                                  ref.invalidate(ec2IpProvider);
                                  ref.invalidate(backendMetricsProvider);
                                },
                                tooltip: 'Retry API connection',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _MetricsGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, innerConstraints) {
                      if (innerConstraints.maxWidth >= 1000) {
                        return const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _RevenueOverviewCard(),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _RecentActivityCard(),
                            ),
                          ],
                        );
                      } else {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _RevenueOverviewCard(),
                            SizedBox(height: 24),
                            _RecentActivityCard(),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Akshay Maldhure  ·  Client: Runanubandh  ·  Commission: 20%  ·  Updated 02:24:10',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppTheme.primaryDarkColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    this.totalUsers = 1220,
    this.activeUsers = 256,
    this.totalProfiles = 2301,
    this.activeProfiles = 2119,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalProfiles;
  final int activeProfiles;

  @override
  Widget build(BuildContext context) {
    final activeUsersRatio = totalUsers == 0 ? 0.0 : activeUsers / totalUsers;
    final activeProfilesRatio = totalProfiles == 0 ? 0.0 : activeProfiles / totalProfiles;

    final cards = <Widget>[
      _MetricCard(
        icon: Icons.people_alt_outlined,
        label: 'Total Users',
        value: totalUsers,
        accent: AppTheme.primaryDarkColor,
        badgeText: 'Total',
        badgeBg: const Color(0xFFF1F5F9),
        badgeFg: const Color(0xFF64748B),
        ratio: 0.65,
      ),
      _MetricCard(
        icon: Icons.person_add_alt_1_outlined,
        label: 'Active Users',
        value: activeUsers,
        accent: Colors.teal,
        badgeText: '${(activeUsersRatio * 100).toStringAsFixed(0)}% Growth',
        badgeBg: const Color(0xFFE6F4EA),
        badgeFg: Colors.teal,
        ratio: activeUsersRatio,
      ),
      _MetricCard(
        icon: Icons.badge_outlined,
        label: 'Total Profiles',
        value: totalProfiles,
        accent: Colors.orange,
        badgeText: 'Database',
        badgeBg: const Color(0xFFFFF4E5),
        badgeFg: Colors.orange,
        ratio: 0.8,
      ),
      _MetricCard(
        icon: Icons.shield_outlined,
        label: 'Active Profiles',
        value: activeProfiles,
        accent: const Color(0xFFE91E63),
        badgeText: '${(activeProfilesRatio * 100).toStringAsFixed(0)}% Live',
        badgeBg: const Color(0xFFFCE4EC),
        badgeFg: const Color(0xFFC2185B),
        ratio: activeProfilesRatio,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 1200
            ? 4
            : w >= 800
                ? 2
                : 1;
        const gap = 16.0;
        final cardWidth = (w - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in cards)
              SizedBox(width: cardWidth, child: c),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
    required this.ratio,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color accent;
  final String badgeText;
  final Color badgeBg;
  final Color badgeFg;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _formatNumber(value),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
                height: 1.05,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 6,
                backgroundColor: accent.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(int v) {
    if (v < 1000) return v.toString();
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _RevenueOverviewCard extends StatelessWidget {
  const _RevenueOverviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payments collected over the last 30 days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Last 30 Days',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 600),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.transparent),
                  dividerThickness: 1.0,
                  horizontalMargin: 0,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Transaction ID',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Profile',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Amount',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  rows: [
                    for (final p in _mockPayments)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(
                              p['id']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              p['profileName']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatAmount(p['amount']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          DataCell(_statusBadge(p['status'])),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatAmount(dynamic amt) {
    if (amt == null) return 'Rs. 0.00';
    if (amt is num) {
      return 'Rs. ${amt.toStringAsFixed(2)}';
    }
    return amt.toString();
  }

  static Widget _statusBadge(dynamic status) {
    final isCompleted = status == 'COMPLETED';
    final isPending = status == 'PENDING';

    Color bgColor = const Color(0xFFF1F5F9);
    Color fgColor = const Color(0xFF64748B);
    String label = 'UNKNOWN';

    if (isCompleted) {
      bgColor = const Color(0xFFECFDF5);
      fgColor = const Color(0xFF10B981);
      label = 'COMPLETED';
    } else if (isPending) {
      bgColor = const Color(0xFFFFFBEB);
      fgColor = const Color(0xFFF59E0B);
      label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static const _mockPayments = [
    {
      'id': 'TXN - 88219',
      'profileName': 'Rahul Deshpande',
      'amount': 1500.00,
      'status': 'COMPLETED',
    },
    {
      'id': 'TXN - 88220',
      'profileName': 'Sneha Kulkarni',
      'amount': 3000.00,
      'status': 'COMPLETED',
    },
    {
      'id': 'TXN - 88221',
      'profileName': 'Vikram Salve',
      'amount': 750.00,
      'status': 'PENDING',
    },
  ];
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                for (int i = 0; i < _mockActivities.length; i++)
                  _ActivityTimelineItem(
                    item: _mockActivities[i],
                    isLast: i == _mockActivities.length - 1,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryDarkColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'View All Activity',
                style: TextStyle(
                  color: AppTheme.primaryDarkColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _mockActivities = [
    {
      'text': 'New user Ananya S. registered a profile.',
      'boldText': 'Ananya S.',
      'time': '2 MINUTES AGO',
      'color': Color(0xFF5D1E3C),
    },
    {
      'text': 'Payment of Rs. 1,500 received from Rahul D.',
      'boldText': 'Rs. 1,500',
      'boldText2': 'Rahul D.',
      'time': '14 MINUTES AGO',
      'color': Colors.teal,
    },
    {
      'text': 'Account verification pending for Priya M.',
      'boldText': 'Priya M.',
      'time': '1 HOUR AGO',
      'color': Colors.amber,
    },
    {
      'text': 'Commission report for May 2024 is now available.',
      'boldText': 'May 2024',
      'time': '3 HOURS AGO',
      'color': Color(0xFF5D1E3C),
    },
  ];
}

class _ActivityTimelineItem extends StatelessWidget {
  const _ActivityTimelineItem({required this.item, required this.isLast});

  final Map<String, dynamic> item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = item['color'] as Color? ?? Colors.grey;
    final text = item['text'] as String;
    final boldText = item['boldText'] as String?;
    final boldText2 = item['boldText2'] as String?;

    Widget textWidget;
    if (boldText != null) {
      final parts = text.split(boldText);
      textWidget = RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1E293B),
            height: 1.4,
            fontFamily: 'Poppins',
          ),
          children: [
            TextSpan(text: parts[0]),
            TextSpan(
              text: boldText,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (parts.length > 1) ...[
              if (boldText2 != null && parts[1].contains(boldText2)) ...[
                TextSpan(text: parts[1].split(boldText2)[0]),
                TextSpan(
                  text: boldText2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: parts[1].split(boldText2)[1]),
              ] else
                TextSpan(text: parts[1]),
            ],
          ],
        ),
      );
    } else {
      textWidget = Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1E293B),
          height: 1.4,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget,
                  const SizedBox(height: 4),
                  Text(
                    item['time']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
