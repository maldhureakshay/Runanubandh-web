import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/api_providers.dart';

class ApiUsersResult {
  const ApiUsersResult({
    required this.users,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  final List<Map<String, dynamic>> users;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  factory ApiUsersResult.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return ApiUsersResult(
      users: list,
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

// Global provider to fetch paginated users from API
final apiUsersPageProvider = FutureProvider.family.autoDispose<ApiUsersResult, (int, String?)>((ref, arg) async {
  final page = arg.$1;
  final phoneQuery = arg.$2;
  
  final ipAddress = await ref.watch(ec2IpProvider.future);
  
  String urlString = 'https://$ipAddress/api/admin/users?page=$page&limit=10';
  if (phoneQuery != null && phoneQuery.trim().isNotEmpty) {
    urlString += '&phone=${Uri.encodeComponent(phoneQuery.trim())}';
  }
  
  final response = await http.get(Uri.parse(urlString));
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    return ApiUsersResult.fromJson(data);
  } else {
    throw Exception('Server returned status code ${response.statusCode}');
  }
});

class UsersListPage extends ConsumerStatefulWidget {
  const UsersListPage({super.key});

  @override
  ConsumerState<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends ConsumerState<UsersListPage> {
  final TextEditingController _searchController = TextEditingController();
  int _page = 1; // 1-indexed for the API
  String? _phoneQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    setState(() {
      _phoneQuery = _searchController.text.isNotEmpty ? _searchController.text : null;
      _page = 1; // Reset to page 1 on search
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _phoneQuery = null;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(apiUsersPageProvider((_page, _phoneQuery)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContent = constraints.maxWidth >= 1500 ? 1480.0 : double.infinity;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContent),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header Section
                  _Header(
                    onFilterPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter dialog (mock)')),
                      );
                    },
                    onAddUserPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add New User dialog (mock)')),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Search Bar Card
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _runSearch(),
                              decoration: const InputDecoration(
                                hintText: 'Search by phone number (e.g. +91...)',
                                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_phoneQuery != null) ...[
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B)),
                              onPressed: _clearSearch,
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            onPressed: _runSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryDarkColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 0),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metrics Cards
                  usersAsync.when(
                    data: (result) => _MetricsCardsRow(totalUsers: result.total),
                    loading: () => const _MetricsCardsRow(totalUsers: 12842),
                    error: (_, __) => const _MetricsCardsRow(totalUsers: 12842),
                  ),
                  const SizedBox(height: 24),

                  // User Table Card
                  Card(
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
                          usersAsync.when(
                            data: (result) {
                              if (result.users.isEmpty) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text(
                                      'No users found matching the search criteria.',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                    ),
                                  ),
                                );
                              }
                              return _UsersTable(
                                users: result.users,
                                onViewUser: (u) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Viewing user: ${u['displayName'] ?? u['id']}')),
                                  );
                                },
                                onEditUser: (u) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Editing user: ${u['displayName'] ?? u['id']}')),
                                  );
                                },
                              );
                            },
                            loading: () => const SizedBox(
                              height: 300,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (err, _) => SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
                                    const SizedBox(height: 12),
                                    Text('Error: $err', style: const TextStyle(color: Color(0xFF64748B))),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => ref.invalidate(apiUsersPageProvider),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Pagination Footer
                          if (usersAsync.hasValue) ...[
                            const SizedBox(height: 20),
                            _PaginationFooter(
                              totalItems: usersAsync.value!.total,
                              currentPage: _page,
                              itemsPerPage: 10,
                              onPageChanged: (newPage) {
                                setState(() {
                                  _page = newPage;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
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
  const _Header({
    required this.onFilterPressed,
    required this.onAddUserPressed,
  });

  final VoidCallback onFilterPressed;
  final VoidCallback onAddUserPressed;

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
                'User Management',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage and monitor application users, access levels, and account statuses.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Filters Button
        OutlinedButton.icon(
          onPressed: onFilterPressed,
          icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF1E293B), size: 18),
          label: const Text('Filters', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 12),
        // Add New User Button
        Material(
          color: AppTheme.primaryDarkColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onAddUserPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Add New User',
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

class _MetricsCardsRow extends StatelessWidget {
  const _MetricsCardsRow({required this.totalUsers});

  final int totalUsers;

  @override
  Widget build(BuildContext context) {
    final activeNow = (totalUsers * 0.25).round();
    
    final cards = <Widget>[
      _MetricCard(
        icon: Icons.people_alt_outlined,
        label: 'Total Users',
        value: totalUsers,
        accent: AppTheme.primaryDarkColor,
      ),
      _MetricCard(
        icon: Icons.person_add_alt_1_outlined,
        label: 'Active Now',
        value: activeNow,
        accent: Colors.teal.shade600,
      ),
      _MetricCard(
        icon: Icons.assignment_ind_outlined,
        label: 'Pending Approval',
        value: 156,
        accent: Colors.orange.shade700,
      ),
      _MetricCard(
        icon: Icons.block_flipped,
        label: 'Deactivated',
        value: 42,
        accent: const Color(0xFFEF4444),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 1200 ? 4 : w >= 800 ? 2 : 1;
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
  });

  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatNumber(value),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
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

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.onViewUser,
    required this.onEditUser,
  });

  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic>) onViewUser;
  final Function(Map<String, dynamic>) onEditUser;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1000),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dividerThickness: 1.0,
          horizontalMargin: 0,
          columnSpacing: 36,
          columns: const [
            DataColumn(
              label: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text('User Details', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              ),
            ),
            DataColumn(
              label: Text('Email Address / Phone', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            ),
            DataColumn(
              label: Text('Caste / Subcaste', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            ),
            DataColumn(
              label: Text('Status', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            ),
            DataColumn(
              label: Align(
                alignment: Alignment.centerRight,
                child: Text('Actions', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          rows: [
            for (final u in users)
              DataRow(
                cells: [
                  // User Details (Avatar, Name, ID)
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              (u['displayName'] ?? u['first_name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u['displayName'] ?? '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${u['id']?.toString().substring(0, 8) ?? '-'}',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Email / Phone
                  DataCell(
                    Text(
                      u['phoneNumber'] ?? '-',
                      style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500),
                    ),
                  ),
                  // Caste / Subcaste
                  DataCell(
                    Text(
                      '${u['cast'] ?? '-'} / ${u['branch'] ?? '-'}',
                      style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500),
                    ),
                  ),
                  // Status
                  DataCell(
                    _StatusBadge(status: u['status']),
                  ),
                  // Actions
                  DataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: Color(0xFF64748B), size: 20),
                          onPressed: () => onViewUser(u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 20),
                          onPressed: () => onEditUser(u),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}


class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final dynamic status;

  @override
  Widget build(BuildContext context) {
    final active = status == true;
    final label = active ? 'Active' : 'Inactive';
    final dotColor = active ? const Color(0xFF10B981) : const Color(0xFF94A3B8);
    final textColor = active ? const Color(0xFF0F766E) : const Color(0xFF475569);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.totalItems,
    required this.currentPage,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  final int totalItems;
  final int currentPage;
  final int itemsPerPage;
  final Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPages = (totalItems / itemsPerPage).ceil();
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = (currentPage * itemsPerPage).clamp(1, totalItems);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startItem - $endItem of $totalItems users',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First Page
            IconButton(
              icon: const Icon(Icons.first_page_rounded, size: 20),
              onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
            ),
            // Prev Page
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            ),
            const SizedBox(width: 8),
            // Current Page Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryDarkColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$currentPage',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            // Next Page
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            ),
            // Last Page
            IconButton(
              icon: const Icon(Icons.last_page_rounded, size: 20),
              onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
            ),
          ],
        ),
      ],
    );
  }
}
