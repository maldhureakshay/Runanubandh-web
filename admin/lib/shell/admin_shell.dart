import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/route_paths.dart';
import '../core/theme/app_theme.dart';
import '../features/admin_profile/presentation/providers/admin_profile_providers.dart';
import '../features/admin_profile/presentation/widgets/admin_profile_menu_header.dart';
import '../features/auth/presentation/providers/auth_providers.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go(AdminRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;
    final extended = width >= 1200;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F8FC),
      drawer: useRail
          ? null
          : Drawer(
              backgroundColor: Colors.transparent,
              child: _Sidebar(
                extended: true,
                onTapItem: () => Navigator.of(context).pop(),
                onSignOut: () {
                  Navigator.of(context).pop();
                  _signOut();
                },
              ),
            ),
      body: Row(
        children: [
          if (useRail)
            _Sidebar(
              extended: extended,
              onSignOut: _signOut,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopHeader(
                  email: user?.email,
                  onSignOut: _signOut,
                  onMenuPressed: useRail
                      ? null
                      : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeader extends ConsumerWidget {
  const _TopHeader({
    required this.email,
    required this.onSignOut,
    required this.onMenuPressed,
  });

  final String? email;
  final VoidCallback onSignOut;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentAdminProfileProvider);
    final profile = profileAsync.valueOrNull;

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search data...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF64748B),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF64748B),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            width: 1,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                profile?.displayName ?? 'Akshay Maldhure',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'MASTER ADMIN',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (val) {
              if (val == 'logout') onSignOut();
            },
            offset: const Offset(0, 48),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.displayName ?? 'Akshay Maldhure',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      email ?? '',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                (profile?.displayName ?? 'AM').substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.extended,
    required this.onSignOut,
    this.onTapItem,
  });

  final bool extended;
  final VoidCallback onSignOut;
  final VoidCallback? onTapItem;

  static const _collapsedWidth = 84.0;
  static const _extendedWidth = 256.0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: extended ? _extendedWidth : _collapsedWidth,
      decoration: const BoxDecoration(
        color: AppTheme.primaryDarkColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(extended: extended),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard,
                    label: 'Dashboard',
                    extended: extended,
                    selected: location.startsWith(AdminRoutes.dashboard),
                    onTap: () {
                      onTapItem?.call();
                      context.go(AdminRoutes.dashboard);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.group_outlined,
                    selectedIcon: Icons.group,
                    label: 'Users',
                    extended: extended,
                    selected: location.startsWith(AdminRoutes.users),
                    onTap: () {
                      onTapItem?.call();
                      context.go(AdminRoutes.users);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.people_outline,
                    selectedIcon: Icons.people,
                    label: 'Profiles',
                    extended: extended,
                    selected: location.startsWith(AdminRoutes.profiles),
                    onTap: () {
                      onTapItem?.call();
                      context.go(AdminRoutes.profiles);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.payments_outlined,
                    selectedIcon: Icons.payments,
                    label: 'Payments',
                    extended: extended,
                    selected: location.startsWith(AdminRoutes.payments),
                    onTap: () {
                      onTapItem?.call();
                      context.go(AdminRoutes.payments);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _SidebarItem(
                icon: Icons.logout_rounded,
                selectedIcon: Icons.logout_rounded,
                label: 'SIGN OUT',
                extended: extended,
                selected: false,
                onTap: onSignOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(extended ? 16 : 12, 16, 12, 8),
      child: Row(
        mainAxisAlignment:
            extended ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          if (extended) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mali Runanubandh',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Admin Console',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.extended,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool extended;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final bgColor = selected
        ? Colors.white.withValues(alpha: 0.18)
        : _hovered
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent;
    final fgColor = selected ? Colors.white : Colors.white.withValues(alpha: 0.85);

    final iconWidget = Icon(
      selected ? widget.selectedIcon : widget.icon,
      color: fgColor,
      size: 22,
    );

    final content = widget.extended
        ? Row(
            children: [
              SizedBox(width: 44, child: Center(child: iconWidget)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          )
        : Tooltip(
            message: widget.label,
            child: SizedBox(height: 44, child: Center(child: iconWidget)),
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: widget.extended ? 10 : 8,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      )
                    : null,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
