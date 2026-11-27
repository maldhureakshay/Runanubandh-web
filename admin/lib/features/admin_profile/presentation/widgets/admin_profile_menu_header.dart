import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_profile.dart';

/// Account menu header: name, client, commission, email.
class AdminProfileMenuHeader extends StatelessWidget {
  const AdminProfileMenuHeader({
    super.key,
    required this.profile,
    required this.email,
  });

  final AdminProfile profile;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commission = profile.commissionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          profile.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (profile.hasClient) ...[
          const SizedBox(height: 6),
          _Row(
            icon: Icons.business_outlined,
            label: profile.clientName ?? profile.clientId!,
          ),
        ],
        if (commission != null) ...[
          const SizedBox(height: 4),
          _Row(
            icon: Icons.percent_outlined,
            label: 'Commission rate: $commission',
            emphasized: true,
          ),
        ],
        if (email != null && email!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            email!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (!profile.hasFirestoreDoc) ...[
          const SizedBox(height: 8),
          Text(
            'No admin profile in Firestore yet. Add admins/{your-uid} with first_name, last_name, and client_id.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: emphasized ? AppTheme.primaryColor : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
              color: emphasized
                  ? AppTheme.primaryColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
