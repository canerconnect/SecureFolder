import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool showAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onActionPressed,
    this.showAction = false,
  });

  factory EmptyState.noFiles({
    Key? key,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.folder_open,
      title: 'Keine Dateien vorhanden',
      description: 'Laden Sie Ihre erste Datei hoch, um zu beginnen.',
      actionText: actionText ?? 'Datei hochladen',
      onActionPressed: onActionPressed,
      showAction: true,
    );
  }

  factory EmptyState.noSearchResults({
    Key? key,
    String searchQuery = '',
  }) {
    return EmptyState(
      key: key,
      icon: Icons.search_off,
      title: 'Keine Ergebnisse gefunden',
      description: searchQuery.isNotEmpty
          ? 'Keine Dateien für "$searchQuery" gefunden.'
          : 'Versuchen Sie einen anderen Suchbegriff.',
    );
  }

  factory EmptyState.noUploads({
    Key? key,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.cloud_upload,
      title: 'Keine Uploads',
      description: 'Wählen Sie Dateien aus, um sie hochzuladen.',
      actionText: actionText ?? 'Dateien auswählen',
      onActionPressed: onActionPressed,
      showAction: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.headlineSmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (showAction && actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              
              // Action button
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}