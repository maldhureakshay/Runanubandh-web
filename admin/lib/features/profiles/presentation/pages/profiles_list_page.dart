import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/admin_network_image.dart';
import '../../data/profiles_repository.dart';
import '../providers/profiles_providers.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfilesListPage extends ConsumerStatefulWidget {
  const ProfilesListPage({super.key});

  @override
  ConsumerState<ProfilesListPage> createState() => _ProfilesListPageState();
}

class _ProfilesListPageState extends ConsumerState<ProfilesListPage> {
  /// Cache key = Algolia query (`*` for browse).
  final Map<String, Map<int, ProfilesPageResult>> _pageCache = {};
  final TextEditingController _searchController = TextEditingController();

  String _listQuery = '*';
  int _page = 0;
  bool _loading = true;
  String? _error;
  bool _searchMode = false;

  Map<int, ProfilesPageResult> get _activeBucket =>
      _pageCache.putIfAbsent(_listQuery, () => {});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPage(0);
      ref.read(profilesRepositoryProvider).ensureFormOptionsLoaded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int targetPage) async {
    final bucket = _activeBucket;
    if (bucket.containsKey(targetPage)) {
      setState(() {
        _page = targetPage;
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ref.read(profilesRepositoryProvider).fetchPage(
            page: targetPage,
            pageSize: ProfilesRepository.defaultPageSize,
            query: _listQuery,
          );
      if (!mounted) return;
      setState(() {
        bucket[targetPage] = result;
        _page = targetPage;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _goNext() async {
    final cur = _activeBucket[_page];
    if (cur == null || !cur.hasMore) return;
    await _loadPage(_page + 1);
  }

  void _goPrev() {
    if (_page <= 0) return;
    if (_activeBucket.containsKey(_page - 1)) {
      setState(() => _page = _page - 1);
    }
  }

  Future<void> _refresh() async {
    _pageCache.remove(_listQuery);
    await _loadPage(_page);
  }

  void _invalidateFrom(int fromPage) {
    final bucket = _activeBucket;
    for (final k in bucket.keys.toList()) {
      if (k >= fromPage) bucket.remove(k);
    }
  }

  Future<void> _runSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name, book ID, job, or education to search.')),
      );
      return;
    }

    setState(() {
      _searchMode = true;
      _listQuery = q;
      _page = 0;
      _error = null;
    });
    _pageCache.remove(_listQuery);
    await _loadPage(0);
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    setState(() {
      _searchMode = false;
      _listQuery = '*';
      _page = 0;
      _error = null;
    });
    await _loadPage(0);
  }

  void _retryAfterError() {
    if (_searchMode && _searchController.text.trim().isNotEmpty) {
      _runSearch();
    } else {
      _loadPage(_page);
    }
  }

  Future<void> _openEdit(Map<String, dynamic> profile) async {
    final id = profile['id'] as String? ?? '';
    if (id.isEmpty) return;

    final saved = await EditProfileDialog.show(context, id);
    if (saved != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
    _invalidateFrom(_page);
    await _loadPage(_page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bucket = _activeBucket;
    final result = bucket[_page];
    final profiles = result?.profiles ?? const [];
    final hasMore = result?.hasMore ?? false;
    final totalHits = result?.totalHits ?? 0;
    final totalPages = result?.totalPages ?? 0;
    final tableLoading = _loading && result == null;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profiles',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle(
                            result: result,
                            totalHits: totalHits,
                            totalPages: totalPages,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Card(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorColor),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_error!)),
                        TextButton(
                          onPressed: _retryAfterError,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error != null) const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  decoration: const InputDecoration(
                                    labelText: 'Search profiles',
                                    hintText:
                                        'Name, book ID, education, job, branch…',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _runSearch(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: FilledButton.icon(
                                  onPressed: _loading ? null : _runSearch,
                                  icon: const Icon(Icons.search, size: 20),
                                  label: const Text('Search'),
                                ),
                              ),
                              if (_searchMode) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: OutlinedButton(
                                    onPressed: _loading ? null : _clearSearch,
                                    child: const Text('Clear'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: tableLoading
                            ? const SizedBox(
                                height: 280,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : profiles.isEmpty
                                ? SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Text(
                                        _searchMode
                                            ? 'No profiles match this search.'
                                            : 'No profiles on this page.',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 1560),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(
                                          Colors.grey.shade100,
                                        ),
                                        columnSpacing: 16,
                                        columns: const [
                                          DataColumn(label: Text('Photo')),
                                          DataColumn(label: Text('Book ID')),
                                          DataColumn(label: Text('Name')),
                                          DataColumn(label: Text('Gender')),
                                          DataColumn(label: Text('Type')),
                                          DataColumn(label: Text('Branch')),
                                          DataColumn(label: Text('Education')),
                                          DataColumn(label: Text('Job')),
                                          DataColumn(label: Text('Height')),
                                          DataColumn(label: Text('DOB')),
                                          DataColumn(label: Text('Active')),
                                          DataColumn(label: Text('Verified')),
                                          DataColumn(label: Text('Book')),
                                          DataColumn(label: Text('Created')),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: [
                                          for (final p in profiles)
                                            DataRow(
                                              cells: [
                                                DataCell(_ProfilePhoto(profile: p)),
                                                DataCell(
                                                  Tooltip(
                                                    message: p['id'] as String? ?? '',
                                                    child: Text(_cellStr(p['original_id'])),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(_displayName(p)),
                                                ),
                                                DataCell(Text(_cellStr(p['gender']))),
                                                DataCell(Text(_cellStr(p['type']))),
                                                DataCell(Text(_cellStr(p['branch']))),
                                                DataCell(
                                                  SizedBox(
                                                    width: 160,
                                                    child: Text(
                                                      _cellStr(p['education']),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(Text(_cellStr(p['job']))),
                                                DataCell(Text(_heightLabel(p))),
                                                DataCell(Text(_formatDate(p['birth_date']))),
                                                DataCell(_ActiveChip(value: p['active'])),
                                                DataCell(_VerifiedChip(value: p['is_verified'])),
                                                DataCell(_BookChip(value: p['is_from_book'])),
                                                DataCell(Text(_formatDate(p['created']))),
                                                DataCell(
                                                  IconButton(
                                                    tooltip: 'Edit profile',
                                                    onPressed: () => _openEdit(p),
                                                    visualDensity: VisualDensity.compact,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(
                                                      minWidth: 36,
                                                      minHeight: 36,
                                                    ),
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size: 20,
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: (_page > 0 && !_loading) ? _goPrev : null,
                            child: const Text('Previous'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Page ${_page + 1}${totalPages > 0 ? ' of $totalPages' : ''}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: (hasMore && !_loading) ? _goNext : null,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle({
    required ProfilesPageResult? result,
    required int totalHits,
    required int totalPages,
  }) {
    final perPage = ProfilesRepository.defaultPageSize;
    if (result == null) {
      return _searchMode
          ? 'Search · $perPage per page'
          : 'Newest first · $perPage per page';
    }
    final pagePart =
        'Page ${_page + 1} of ${totalPages > 0 ? totalPages : 1} · $totalHits total · $perPage per page';
    if (_searchMode) {
      return 'Search: “$_listQuery” · $pagePart';
    }
    return 'Newest first · $pagePart';
  }

  static String _cellStr(dynamic v) {
    if (v == null) return '-';
    final s = v.toString().trim();
    return s.isEmpty ? '-' : s;
  }

  static String _displayName(Map<String, dynamic> p) {
    final full = p['full_name']?.toString().trim();
    if (full != null && full.isNotEmpty) return full;
    final parts = [
      p['first_name'],
      p['middle_name'],
      p['last_name'],
    ].map((e) => e?.toString().trim() ?? '').where((s) => s.isNotEmpty);
    final joined = parts.join(' ');
    return joined.isEmpty ? '-' : joined;
  }

  static String _heightLabel(Map<String, dynamic> p) {
    final h = p['height']?.toString().trim();
    if (h != null && h.isNotEmpty) return h;
    final cm = p['height_cm'];
    if (cm is num) return '${cm.toInt()} cm';
    return '-';
  }

  /// Algolia may store dates as epoch ms [num] or ISO strings (`1989-12-22T00:00:00.000`).
  static String _formatDate(dynamic v) {
    final d = _parseDate(v);
    if (d == null) return '-';
    return '${d.year}-${_two(d.month)}-${_two(d.day)}';
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toLocal();
    if (v is num) {
      final n = v.toInt();
      if (n <= 0) return null;
      // Values below ~1e12 are usually epoch seconds; above are milliseconds.
      final ms = n < 1000000000000 ? n * 1000 : n;
      return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }
    if (v is Map) {
      final inner = v['value'];
      if (inner != null) return _parseDate(inner);
    }
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      final parsed = DateTime.tryParse(s);
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final images = profile['images'];
    String? url;
    if (images is List && images.isNotEmpty) {
      url = images.first?.toString();
    }
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, color: Colors.grey.shade500, size: 22),
      );
    }
    return AdminNetworkImage(
      url: url,
      width: 40,
      height: 40,
      borderRadius: BorderRadius.circular(8),
      placeholder: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade200,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.broken_image, color: Colors.grey.shade500, size: 20),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.value});

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final active = value == true;
    return Chip(
      label: Text(
        active ? 'Yes' : 'No',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: active ? Colors.green.shade50 : Colors.grey.shade200,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip({required this.value});

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final ok = value == true;
    return Chip(
      label: Text(
        ok ? 'Yes' : 'No',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: ok ? Colors.green.shade50 : Colors.grey.shade200,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BookChip extends StatelessWidget {
  const _BookChip({required this.value});

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final ok = value == true;
    return Chip(
      label: Text(
        ok ? 'Yes' : 'No',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: ok ? Colors.blue.shade50 : Colors.grey.shade200,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}
