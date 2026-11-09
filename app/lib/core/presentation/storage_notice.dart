import 'package:flutter/material.dart';

import 'app_theme.dart';

class StorageNotice extends StatelessWidget {
  const StorageNotice({super.key, this.compact = false});

  final bool compact;

  static const String fullText =
      'Records stay only on this device. There is no account, cloud sync, '
      'backup or restore. Losing this phone, uninstalling the app, or clearing '
      'its data may permanently erase your history with no recovery in this version.';

  static const String compactText =
      'Stored only on this device. No account, sync, backup or recovery.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = compact ? compactText : fullText;
    return Semantics(
      container: true,
      label: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: compact ? 18 : 20,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Re-exported so tests can assert the 44/48 target tokens without importing
/// the theme implementation directly.
double minimumTargetFor(BuildContext context) =>
    AppTheme.minTargetFor(Theme.of(context).platform);
