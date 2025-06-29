import 'package:flutter/material.dart';
import '../services/responsive_service.dart';

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isLoading;
  final bool isOutlined;

  const ResponsiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.isLoading = false,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? ResponsiveService.buttonHeight;
    final buttonWidth = width ?? double.infinity;
    
    // Adjust padding for very small screens
    final horizontalPadding = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getSpacing(8) 
        : ResponsiveService.getSpacing(16);
    
    final verticalPadding = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getSpacing(6) 
        : ResponsiveService.getSpacing(12);

    final fontSize = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getFontSize(14) 
        : ResponsiveService.getFontSize(16);

    final iconSize = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getIconSize(18) 
        : ResponsiveService.getIconSize(20);

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          )
        else if (icon != null)
          Icon(
            icon,
            size: iconSize,
            color: textColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        if ((icon != null || isLoading) && text.isNotEmpty)
          SizedBox(width: ResponsiveService.getSpacing(8)),
        if (text.isNotEmpty)
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor ?? Theme.of(context).colorScheme.onPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );

    if (isOutlined) {
      return Container(
        width: buttonWidth,
        height: buttonHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: backgroundColor ?? Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(12)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(12)),
            onTap: onPressed,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(child: buttonContent),
            ),
          ),
        ),
      );
    }

    return Container(
      width: buttonWidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? Theme.of(context).colorScheme.primary,
            backgroundColor?.withOpacity(0.8) ?? Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(12)),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.3),
            blurRadius: ResponsiveService.getSpacing(8),
            offset: Offset(0, ResponsiveService.getSpacing(2)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(12)),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );
  }
}

class ResponsiveIconButton extends StatelessWidget with ResponsiveWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;
  final EdgeInsets? padding;

  const ResponsiveIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    final buttonSize = size ?? getResponsiveSpacing(48);
    final iconSize = getResponsiveIconSize(24);
    
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: getResponsiveBorderRadius(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: getResponsiveSpacing(4),
                  offset: Offset(0, getResponsiveSpacing(2)),
                ),
              ],
            )
          : null,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
          size: iconSize,
        ),
        tooltip: tooltip,
        padding: padding ?? EdgeInsets.all(getResponsiveSpacing(12)),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: getResponsiveBorderRadius(12),
          ),
        ),
      ),
    );
  }
}

class ResponsiveFloatingActionButton extends StatelessWidget with ResponsiveWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;

  const ResponsiveFloatingActionButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    final buttonSize = size ?? getResponsiveSpacing(56);
    final iconSize = getResponsiveIconSize(24);
    
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      tooltip: tooltip,
      child: Icon(
        icon,
        size: iconSize,
      ),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: getResponsiveBorderRadius(16),
      ),
    );
  }
} 