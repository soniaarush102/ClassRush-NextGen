import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups_rounded),
      label: 'Classes',
    ),
    NavigationDestination(
      icon: Icon(Icons.video_library_outlined),
      selectedIcon: Icon(Icons.video_library_rounded),
      label: 'Recordings',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final pages = [
      _DashboardContent(
        onCreateClass: _showCreateClass,
        onJoinClass: _showJoinClass,
      ),
      const _PlaceholderPage(
        icon: Icons.groups_rounded,
        title: 'Your classes',
        subtitle: 'Classes you create or join will appear here.',
      ),
      const _PlaceholderPage(
        icon: Icons.video_library_rounded,
        title: 'Class recordings',
        subtitle: 'Saved lesson recordings will appear here.',
      ),
      const _PlaceholderPage(
        icon: Icons.settings_rounded,
        title: 'Settings',
        subtitle: 'Account, appearance and classroom preferences.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) =>
                    setState(() => _selectedIndex = value),
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: _BrandMark(),
                ),
                destinations: _destinations
                    .map((item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ))
                    .toList(),
              ),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) =>
                  setState(() => _selectedIndex = value),
              destinations: _destinations,
            ),
    );
  }

  void _showCreateClass() {
    _showMessage('Class creation will be connected to the classroom service.');
  }

  void _showJoinClass() {
    _showMessage('Class joining will be connected to classroom IDs and links.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.onCreateClass,
    required this.onJoinClass,
  });

  final VoidCallback onCreateClass;
  final VoidCallback onJoinClass;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(compact ? 20 : 40, 24, compact ? 20 : 40, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  if (compact) const _BrandMark(),
                  if (compact) const SizedBox(width: 12),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFFFFE4D1),
                    child: Icon(Icons.person, color: AppTheme.brandOrange),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Text(
                'Your classroom,\nwithout boundaries.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Teach, collaborate and learn together in real time.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              _QuickActions(
                onCreateClass: onCreateClass,
                onJoinClass: onJoinClass,
              ),
              const SizedBox(height: 32),
              Text(
                'Your workspace',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w750,
                    ),
              ),
              const SizedBox(height: 14),
              const _WorkspaceCard(),
              const SizedBox(height: 28),
              Text(
                'Coming into focus',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w750,
                    ),
              ),
              const SizedBox(height: 14),
              const _FeatureGrid(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCreateClass,
    required this.onJoinClass,
  });

  final VoidCallback onCreateClass;
  final VoidCallback onJoinClass;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: onCreateClass,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create a class'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onJoinClass,
          icon: const Icon(Icons.meeting_room_outlined),
          label: const Text('Join with a code'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.brandOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.draw_rounded,
                color: AppTheme.brandOrange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collaborative classroom',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text('A shared space for live lessons and ideas.'),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.draw_outlined, 'Live whiteboard', 'Write and solve together'),
      (Icons.video_call_outlined, 'Live classroom', 'Face-to-face lessons'),
      (Icons.picture_as_pdf_outlined, 'PDF & slides', 'Present and annotate'),
      (Icons.forum_outlined, 'Class chat', 'Keep every discussion close'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final feature = features[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(feature.$1, color: AppTheme.brandOrange, size: 25),
                    const SizedBox(height: 12),
                    Text(feature.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      feature.$3,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppTheme.brandOrange),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.brandOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'CR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'CLASSRUSH',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
      ],
    );
  }
}
