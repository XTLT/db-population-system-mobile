import 'package:flutter/material.dart';


class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}


class QuickActionsWidget extends StatelessWidget {
  final List<QuickAction> actions;
  final String? title;

  const QuickActionsWidget({
    super.key,
    required this.actions,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions.map((action) => _buildActionChip(context, action)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, QuickAction action) {
    return ActionChip(
      avatar: Icon(
        action.icon,
        size: 20,
        color: action.color ?? Theme.of(context).colorScheme.primary,
      ),
      label: Text(action.label),
      onPressed: action.onTap,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        color: action.color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}


class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;
  final int crossAxisCount;
  final double childAspectRatio;

  const QuickActionsGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildGridItem(context, action);
      },
    );
  }

  Widget _buildGridItem(BuildContext context, QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              size: 32,
              color: action.color ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
