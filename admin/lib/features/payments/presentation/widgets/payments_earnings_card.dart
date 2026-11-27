import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin_profile/data/admin_profile.dart';
import '../../data/commission_earnings.dart';
import '../../data/maintenance_bill.dart';
import '../../data/maintenance_cost.dart';

/// Step-by-step commission earnings breakdown for the selected month.
class PaymentsEarningsCard extends StatefulWidget {
  const PaymentsEarningsCard({
    super.key,
    required this.periodLabel,
    required this.profile,
    required this.summary,
  });

  final String periodLabel;
  final AdminProfile profile;
  final CommissionEarningsSummary summary;

  @override
  State<PaymentsEarningsCard> createState() => _PaymentsEarningsCardState();
}

class _PaymentsEarningsCardState extends State<PaymentsEarningsCard> {
  bool _showPerPurchase = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;
    final rateLabel = formatCommissionRate(summary.commissionRatePercent);
    final bill = summary.maintenanceBill;
    final maintenanceCost = summary.maintenanceCost;
    final clientLabel = widget.profile.clientName ?? widget.profile.clientId;
    final maintenanceChipLabel = !maintenanceCost.isAvailable
        ? 'Maintenance: not in Firebase'
        : summary.usesFirebaseBill
            ? 'Bill: ${formatInr(summary.totalSystemMaintenanceCostInr)}'
            : 'Maintenance: ${formatCommissionRate(maintenanceCost.ratePercent!)} (Firebase)';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  AppTheme.accentColor.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your earnings',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            widget.periodLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatInr(summary.totalCommissionEarningsInr),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (clientLabel != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('Client: $clientLabel'),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          !maintenanceCost.isAvailable
                              ? Icons.warning_amber_outlined
                              : summary.usesFirebaseBill
                                  ? Icons.receipt_long_outlined
                                  : Icons.build_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        label: Text(maintenanceChipLabel),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          Icons.percent,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        label: Text('Commission: $rateLabel'),
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.08),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How your earnings are calculated',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _StepRow(
                  step: 1,
                  title: 'Purchases in this period',
                  value: '${summary.purchaseCount}',
                  detail:
                      'Account activation purchases included in this month (after filters).',
                ),
                _StepRow(
                  step: 2,
                  title: 'Total amount received',
                  value: formatInr(summary.totalAmountReceivedInr),
                  detail:
                      'For each purchase, Google Play keeps 30% of the list price. '
                      'Amount received is what remains (70% of the base price).',
                ),
                _StepRow(
                  step: 3,
                  title: 'System maintenance cost',
                  value: formatInr(summary.totalSystemMaintenanceCostInr),
                  detail: summary.usesFirebaseBill
                      ? 'Monthly bill from Firestore for ${widget.periodLabel} '
                          '(allocated across purchases by share of amount received).'
                      : summary.usesFirebaseRate
                          ? 'Rate loaded from ${maintenanceCost.rateConfigPath} — '
                              '${formatCommissionRate(maintenanceCost.ratePercent!)} of amount received.'
                          : 'Add a monthly bill or maintenance rate in Firestore (see below).',
                ),
                const SizedBox(height: 4),
                if (bill != null)
                  _MaintenanceBillPanel(bill: bill)
                else if (summary.usesFirebaseRate)
                  _MaintenanceRatePanel(cost: maintenanceCost)
                else
                  const _NoMaintenanceConfigNotice(),
                _StepRow(
                  step: 4,
                  title: 'Amount after maintenance',
                  value: formatInr(summary.totalAmountAfterMaintenanceInr),
                  detail:
                      'Amount received minus system maintenance — this is the base for your commission.',
                ),
                _StepRow(
                  step: 5,
                  title: 'Your commission rate',
                  value: rateLabel,
                  detail: clientLabel != null
                      ? 'Rate set for your client ($clientLabel) in Firestore.'
                      : 'Rate from your linked client in Firestore.',
                ),
                _StepRow(
                  step: 6,
                  title: 'Your earnings',
                  value: formatInr(summary.totalCommissionEarningsInr),
                  detail:
                      'Commission applied on amount after maintenance (not on gross received).',
                  emphasized: true,
                ),
                const SizedBox(height: 16),
                _FormulaBox(summary: summary),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showPerPurchase = !_showPerPurchase),
                  icon: Icon(
                    _showPerPurchase
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  label: Text(
                    _showPerPurchase
                        ? 'Hide per-purchase breakdown'
                        : 'Show per-purchase breakdown',
                  ),
                ),
                if (_showPerPurchase) ...[
                  const SizedBox(height: 8),
                  _PerPurchaseTable(summary: summary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.title,
    required this.value,
    required this.detail,
    this.emphasized = false,
  });

  final int step;
  final String title;
  final String value;
  final String detail;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: emphasized
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.15),
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: emphasized ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: emphasized
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceBillPanel extends StatelessWidget {
  const _MaintenanceBillPanel({required this.bill});

  final MaintenanceBill bill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: Colors.blue.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bill.displayTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              Text(
                formatInr(bill.totalAmountInr),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          if (bill.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              bill.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade900.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (bill.hasLineItems) ...[
            const SizedBox(height: 12),
            Text(
              'Bill breakdown',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in bill.lineItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      formatInr(item.amountInr),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 6),
          Text(
            'Document: bills/${bill.id}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceRatePanel extends StatelessWidget {
  const _MaintenanceRatePanel({required this.cost});

  final MaintenanceCost cost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = cost.ratePercent!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: Colors.teal.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Maintenance rate (Firestore)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900,
                  ),
                ),
              ),
              Text(
                formatCommissionRate(rate),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.teal.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Config: ${cost.rateConfigPath}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.teal.shade800),
          ),
          const SizedBox(height: 6),
          Text(
            'Cost this month: ${formatInr(cost.totalAmountInr)} = '
            'amount received × ($rate% ÷ 100)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.teal.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMaintenanceConfigNotice extends StatelessWidget {
  const _NoMaintenanceConfigNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Text(
        'Configure maintenance in Firestore:\n'
        '• Monthly bill: bills/{client_id}_{year}_{month} with field amount\n'
        '• Or rate %: clients/{client_id}.system_maintenance_rate\n'
        '• Or app_config/system_maintenance.maintenance_rate_percent',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade900),
      ),
    );
  }
}

class _FormulaBox extends StatelessWidget {
  const _FormulaBox({required this.summary});

  final CommissionEarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rateLabel = formatCommissionRate(summary.commissionRatePercent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formula',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            summary.usesFirebaseBill
                ? 'Amount after maintenance = Amount received − Maintenance bill'
                : summary.usesFirebaseRate
                    ? 'Amount after maintenance = Amount received − (Amount received × Maintenance rate ÷ 100)'
                    : 'Amount after maintenance = Amount received (no maintenance configured)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            'Your earnings = Amount after maintenance × (Commission rate ÷ 100)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            '${formatInr(summary.totalAmountAfterMaintenanceInr)} = '
            '${formatInr(summary.totalAmountReceivedInr)} − '
            '${formatInr(summary.totalSystemMaintenanceCostInr)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            '${formatInr(summary.totalCommissionEarningsInr)} = '
            '${formatInr(summary.totalAmountAfterMaintenanceInr)} × ($rateLabel ÷ 100)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          if (summary.usesFirebaseRate && summary.maintenanceRatePercent != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              'Maintenance (${summary.maintenanceCost.rateConfigPath}): '
              '${formatInr(summary.totalSystemMaintenanceCostInr)} = '
              '${formatInr(summary.totalAmountReceivedInr)} × '
              '(${formatCommissionRate(summary.maintenanceRatePercent!)} ÷ 100)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ] else if (summary.maintenanceBill != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              'Maintenance bill (${summary.maintenanceBill!.displayTitle}): '
              '${formatInr(summary.totalSystemMaintenanceCostInr)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerPurchaseTable extends StatelessWidget {
  const _PerPurchaseTable({required this.summary});

  final CommissionEarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rateLabel = formatCommissionRate(summary.commissionRatePercent);
    final maintenanceColumnLabel = summary.usesFirebaseBill
        ? 'Maintenance (bill share)'
        : summary.usesFirebaseRate && summary.maintenanceRatePercent != null
            ? 'Maintenance (${formatCommissionRate(summary.maintenanceRatePercent!)})'
            : 'Maintenance';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columnSpacing: 20,
            columns: [
              const DataColumn(label: Text('User')),
              const DataColumn(label: Text('Product')),
              const DataColumn(label: Text('Amount received')),
              DataColumn(label: Text(maintenanceColumnLabel)),
              const DataColumn(label: Text('After maintenance')),
              DataColumn(label: Text('× $rateLabel')),
              const DataColumn(label: Text('Your share')),
            ],
            rows: [
              for (final line in summary.lines)
                DataRow(
                  cells: [
                    DataCell(Text(line.userLabel)),
                    DataCell(Text(line.productLabel)),
                    DataCell(Text(formatInr(line.amountReceivedInr))),
                    DataCell(Text(formatInr(line.systemMaintenanceCostInr))),
                    DataCell(Text(formatInr(line.amountAfterMaintenanceInr))),
                    DataCell(Text(rateLabel)),
                    DataCell(
                      Text(
                        formatInr(line.commissionEarningsInr),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              DataRow(
                color: WidgetStateProperty.all(
                  AppTheme.primaryColor.withValues(alpha: 0.06),
                ),
                cells: [
                  const DataCell(
                    Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const DataCell(Text('')),
                  DataCell(
                    Text(
                      formatInr(summary.totalAmountReceivedInr),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatInr(summary.totalSystemMaintenanceCostInr),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatInr(summary.totalAmountAfterMaintenanceInr),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(Text(rateLabel)),
                  DataCell(
                    Text(
                      formatInr(summary.totalCommissionEarningsInr),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when admin has no commission rate on their profile.
class PaymentsEarningsUnavailable extends StatelessWidget {
  const PaymentsEarningsUnavailable({super.key, required this.profile});

  final AdminProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDoc = profile?.hasFirestoreDoc ?? false;
    final hasClient = profile?.hasClient ?? false;

    String message;
    if (profile == null) {
      message = 'Sign in to see your commission earnings.';
    } else if (!hasDoc) {
      message =
          'Add your admin profile in Firestore (admins/{your-uid}) with first_name, last_name, and client_id.';
    } else if (!hasClient) {
      message =
          'Link a client to your admin profile (client_id) so we can load your commission rate.';
    } else {
      message =
          'Your client has no commission_rate set, or it could not be loaded.';
    }

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade900),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commission earnings unavailable',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
