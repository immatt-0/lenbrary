import 'package:flutter/material.dart';
import '../services/responsive_service.dart';

class ResponsiveDialog extends StatelessWidget with ResponsiveWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool barrierDismissible;
  final Color? backgroundColor;
  final EdgeInsets? contentPadding;

  const ResponsiveDialog({
    Key? key,
    required this.child,
    this.title,
    this.actions,
    this.barrierDismissible = true,
    this.backgroundColor,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Dialog(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: getResponsiveBorderRadius(20),
      ),
      child: Container(
        width: ResponsiveService.dialogWidth,
        constraints: BoxConstraints(
          maxHeight: ResponsiveService.dialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Section
            if (title != null) ...[
              Container(
                padding: getResponsivePadding(all: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: getResponsiveBorderRadius(20).topLeft,
                    topRight: getResponsiveBorderRadius(20).topRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: ResponsiveTextStyles.getResponsiveTitleStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: getResponsiveIconSize(24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Content Section
            Flexible(
              child: SingleChildScrollView(
                padding: contentPadding ?? getResponsivePadding(all: 20),
                child: child,
              ),
            ),
            
            // Actions Section
            if (actions != null && actions!.isNotEmpty) ...[
              Container(
                padding: getResponsivePadding(all: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.only(
                    bottomLeft: getResponsiveBorderRadius(20).bottomLeft,
                    bottomRight: getResponsiveBorderRadius(20).bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!.map((action) {
                    return Padding(
                      padding: EdgeInsets.only(left: getResponsiveSpacing(8)),
                      child: action,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Responsive Alert Dialog
class ResponsiveAlertDialog extends StatelessWidget with ResponsiveWidget {
  final String title;
  final String content;
  final List<Widget>? actions;
  final IconData? icon;
  final Color? iconColor;

  const ResponsiveAlertDialog({
    Key? key,
    required this.title,
    required this.content,
    this.actions,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: getResponsiveBorderRadius(20),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
              size: getResponsiveIconSize(24),
            ),
            SizedBox(width: getResponsiveSpacing(12)),
          ],
          Expanded(
            child: Text(
              title,
              style: ResponsiveTextStyles.getResponsiveTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: ResponsiveTextStyles.getResponsiveBodyStyle(
          fontSize: 14,
        ),
      ),
      actions: actions,
    );
  }
}

// Responsive Bottom Sheet
class ResponsiveBottomSheet extends StatelessWidget with ResponsiveWidget {
  final Widget child;
  final String? title;
  final bool isScrollControlled;
  final bool enableDrag;
  final Color? backgroundColor;

  const ResponsiveBottomSheet({
    Key? key,
    required this.child,
    this.title,
    this.isScrollControlled = false,
    this.enableDrag = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: getResponsiveBorderRadius(20).topLeft,
          topRight: getResponsiveBorderRadius(20).topRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: getResponsiveSpacing(12)),
            width: getResponsiveSpacing(40),
            height: getResponsiveSpacing(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: getResponsiveBorderRadius(2),
            ),
          ),
          
          // Title Section
          if (title != null) ...[
            Padding(
              padding: getResponsivePadding(all: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: ResponsiveTextStyles.getResponsiveTitleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: getResponsiveIconSize(24),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Content Section
          Flexible(
            child: SingleChildScrollView(
              padding: getResponsivePadding(all: 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
} 