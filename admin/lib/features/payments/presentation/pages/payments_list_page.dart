import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin_profile/presentation/providers/admin_profile_providers.dart';
import '../../data/commission_earnings.dart';
import '../../data/maintenance_cost.dart';
import '../../data/purchases_repository.dart';
import '../providers/payments_providers.dart';
import '../widgets/payments_earnings_card.dart';

class PaymentsListPage extends ConsumerStatefulWidget {
  const PaymentsListPage({super.key});

  @override
  ConsumerState<PaymentsListPage> createState() => _PaymentsListPageState();
}

class _PaymentsListPageState extends ConsumerState<PaymentsListPage> {
  late int _year;
  late int _month;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _purchases = const [];
  double _totalAmountReceived = 0;
  MaintenanceCost? _maintenanceCost;
  bool _maintenanceCostLoaded = false;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _maintenanceCostLoaded = false;
    });

    try {
      final profile = ref.read(currentAdminProfileProvider).valueOrNull;
      final clientId = profile?.clientId;

      final result = await ref.read(purchasesRepositoryProvider).fetchForMonth(
            year: _year,
            month: _month,
          );

      final maintenanceCost =
          await ref.read(maintenanceCostRepositoryProvider).resolve(
                clientId: clientId,
                year: _year,
                month: _month,
                totalAmountReceivedInr: result.totalAmountReceivedInr,
              );

      if (!mounted) return;
      setState(() {
        _purchases = result.purchases;
        _totalAmountReceived = result.totalAmountReceivedInr;
        _maintenanceCost = maintenanceCost;
        _maintenanceCostLoaded = true;
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

  void _onMonthChanged(int? month) {
    if (month == null || month == _month) return;
    setState(() => _month = month);
    _load();
  }

  void _onYearChanged(int? year) {
    if (year == null || year == _year) return;
    setState(() => _year = year);
    _load();
  }

  List<int> get _yearOptions {
    final now = DateTime.now().year;
    return List.generate(now - 2019, (i) => now - i);
  }

  String get _periodLabel {
 
    return '${_monthNames[_month - 1]} $_year';
  }

  String get _dataSourceLabel {
    
    return 'Purchases collection';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodLabel = _periodLabel;
    final hitLimit = _purchases.length >= PurchasesRepository.maxPerMonth;
    final profileAsync = ref.watch(currentAdminProfileProvider);
    final profile = profileAsync.valueOrNull;
    final earningsSummary = !_loading &&
            _error == null &&
            _maintenanceCostLoaded &&
            _maintenanceCost != null
        ? CommissionEarningsSummary.compute(
            purchases: _purchases,
            commissionRatePercent: profile?.commissionRate,
            maintenanceCost: _maintenanceCost!,
          )
        : null;
    final commissionRate = profile?.commissionRate;
    final showCommissionColumn = commissionRate != null &&
        commissionRate > 0 &&
        !_loading &&
        earningsSummary != null;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payments',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_dataSourceLabel · $periodLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
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
                        TextButton(onPressed: _load, child: const Text('Retry')),
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
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<int>(
                                  value: _month,
                                  decoration: const InputDecoration(
                                    labelText: 'Month',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: [
                                    for (var i = 1; i <= 12; i++)
                                      DropdownMenuItem(
                                        value: i,
                                        child: Text(_monthNames[i - 1]),
                                      ),
                                  ],
                                  onChanged: _loading ? null : _onMonthChanged,
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: DropdownButtonFormField<int>(
                                  value: _year,
                                  decoration: const InputDecoration(
                                    labelText: 'Year',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: [
                                    for (final y in _yearOptions)
                                      DropdownMenuItem(
                                        value: y,
                                        child: Text('$y'),
                                      ),
                                  ],
                                  onChanged: _loading ? null : _onYearChanged,
                                ),
                              ),
                              if (!_loading && _error == null) ...[
                                Chip(
                                  avatar: Icon(
                                    Icons.receipt_long,
                                    size: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                  label: Text('${_purchases.length} purchase(s)'),
                                ),
                                Chip(
                                  avatar: Icon(
                                    Icons.currency_rupee,
                                    size: 18,
                                    color: Colors.green.shade700,
                                  ),
                                  label: Text(
                                    'Amount received: ${_formatInr(_totalAmountReceived)}',
                                  ),
                                  backgroundColor: Colors.green.shade50,
                                ),
                                if (earningsSummary != null)
                                  Chip(
                                    avatar: Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 18,
                                      color: AppTheme.primaryColor,
                                    ),
                                    label: Text(
                                      'Your earnings: ${formatInr(earningsSummary.totalCommissionEarningsInr)}',
                                    ),
                                    backgroundColor: AppTheme.primaryColor
                                        .withValues(alpha: 0.08),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (hitLimit && !_loading) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Showing first ${PurchasesRepository.maxPerMonth} results for this month.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                      if (!_loading && _error == null) ...[
                        const SizedBox(height: 16),
                        if (earningsSummary != null && profile != null)
                          PaymentsEarningsCard(
                            periodLabel: periodLabel,
                            profile: profile,
                            summary: earningsSummary,
                          )
                        else if (!profileAsync.isLoading)
                          PaymentsEarningsUnavailable(profile: profile),
                      ],
                      const SizedBox(height: 12),
                      Card(
                        child: _loading
                            ? const SizedBox(
                                height: 280,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : _purchases.isEmpty
                                ? SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Text(
                                        'No purchases in $periodLabel.',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: showCommissionColumn ? 1720 : 1560,
                                      ),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(
                                          Colors.grey.shade100,
                                        ),
                                        columnSpacing: 16,
                                        columns: [
                                          const DataColumn(label: Text('Purchase time')),
                                          const DataColumn(label: Text('Amount')),
                                          const DataColumn(
                                            label: Text('Play deduction (30%)'),
                                          ),
                                          const DataColumn(label: Text('Amount received')),
                                          if (showCommissionColumn)
                                            DataColumn(
                                              label: Text(
                                                'Your share (${formatCommissionRate(commissionRate)})',
                                              ),
                                            ),
                                          const DataColumn(label: Text('Product')),
                                          const DataColumn(label: Text('Order ID')),
                                          const DataColumn(label: Text('User')),
                                          const DataColumn(label: Text('Profile ID')),
                                          const DataColumn(label: Text('Acknowledged')),
                                          const DataColumn(label: Text('State')),
                                          const DataColumn(label: Text('Processed')),
                                          const DataColumn(label: Text('Discounted')),
                                        ],
                                        rows: [
                                          for (final p in _purchases)
                                            DataRow(
                                              cells: [
                                                DataCell(
                                                  Tooltip(
                                                    message: p['id'] as String? ?? '',
                                                    child: Text(
                                                      _formatTs(p['purchaseTime']),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(Text(_amountCell(p))),
                                                DataCell(Text(_playDeductionCell(p))),
                                                DataCell(Text(_amountReceivedCell(p))),
                                                if (showCommissionColumn)
                                                  DataCell(
                                                    Text(
                                                      _commissionShareCell(
                                                        p,
                                                        earningsSummary,
                                                      ),
                                                    ),
                                                  ),
                                                DataCell(Text(_cellStr(p['productId']))),
                                                DataCell(
                                                  SelectableText(_cellStr(p['orderId'])),
                                                ),
                                                DataCell(
                                                  Tooltip(
                                                    message:
                                                        'User ID: ${_cellStr(p['userId'])}',
                                                    child: Text(
                                                      _titleCase(
                                                        _cellStr(p['userDisplayName']),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  SelectableText(_cellStr(p['profileId'])),
                                                ),
                                                DataCell(_boolChip(p['acknowledged'])),
                                                DataCell(Text(_purchaseState(p))),
                                                DataCell(Text(_formatTs(p['processedAt']))),
                                                DataCell(_boolChip(p['isDiscounted'])),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
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

  static String _cellStr(dynamic v) {
    if (v == null) return '-';
    final s = v.toString().trim();
    return s.isEmpty ? '-' : s;
  }

  static double? _amountValue(Map<String, dynamic> p) {
    final amount = p['amount'];
    if (amount is num) return amount.toDouble();
    return null;
  }

  static String _formatInr(double value) {
    final whole = value == value.roundToDouble();
    return '₹${value.toStringAsFixed(whole ? 0 : 2)}';
  }

  static String _amountCell(Map<String, dynamic> p) {
    final value = _amountValue(p);
    if (value == null) return '-';
    final currency = _cellStr(p['currency']);
    if (currency != 'INR' && currency != '-') {
      return '$currency $value';
    }
    return _formatInr(value);
  }

  static String _playDeductionCell(Map<String, dynamic> p) {
    final deduction = PurchaseSettlement.playDeduction(p);
    if (deduction == null) return '-';
    return _formatInr(deduction);
  }

  static String _amountReceivedCell(Map<String, dynamic> p) {
    final received = PurchaseSettlement.amountReceived(p);
    if (received == null) return '-';
    return _formatInr(received);
  }

  static String _commissionShareCell(
    Map<String, dynamic> p,
    CommissionEarningsSummary? summary,
  ) {
    if (summary == null) return '-';
    final share = CommissionEarningsSummary.commissionShareForPurchase(p, summary);
    if (share == null) return '-';
    return _formatInr(share);
  }

  static String _titleCase(String raw) {
    if (raw == '-') return raw;
    return raw
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return w;
          return '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}';
        })
        .join(' ');
  }

  static String _purchaseState(Map<String, dynamic> p) {
    final state = p['purchaseState'];
    if (state == null) return '-';
    if (state == 0) return 'Purchased';
    if (state == 1) return 'Canceled';
    if (state == 2) return 'Pending';
    return state.toString();
  }

  static String _formatTs(dynamic v) {
    if (v is Timestamp) {
      final d = v.toDate().toLocal();
      return '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
    }
    return '-';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static Widget _boolChip(dynamic v) {
    final ok = v == true;
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
