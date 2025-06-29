import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/responsive_service.dart';

class ResponsiveTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final EdgeInsets? contentPadding;

  const ResponsiveTextField({
    Key? key,
    this.labelText,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Adjust sizes for very small screens
    final fieldHeight = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.textFieldHeight * 0.9 
        : ResponsiveService.textFieldHeight;
    
    final fontSize = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getFontSize(14) 
        : ResponsiveService.getFontSize(16);
    
    final labelFontSize = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getFontSize(12) 
        : ResponsiveService.getFontSize(14);
    
    final hintFontSize = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getFontSize(13) 
        : ResponsiveService.getFontSize(15);

    final iconSize = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getIconSize(18) 
        : ResponsiveService.getIconSize(20);

    final borderRadius = ResponsiveService.isVerySmallPhone 
        ? ResponsiveService.getSpacing(8) 
        : ResponsiveService.getSpacing(12);

    final defaultContentPadding = ResponsiveService.isVerySmallPhone
        ? EdgeInsets.symmetric(
            horizontal: ResponsiveService.getSpacing(12),
            vertical: ResponsiveService.getSpacing(8),
          )
        : EdgeInsets.symmetric(
            horizontal: ResponsiveService.getSpacing(16),
            vertical: ResponsiveService.getSpacing(12),
          );

    return Container(
      height: fieldHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: ResponsiveService.getSpacing(8),
            offset: Offset(0, ResponsiveService.getSpacing(2)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        maxLines: maxLines,
        maxLength: maxLength,
        enabled: enabled,
        readOnly: readOnly,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        textInputAction: textInputAction,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: hintFontSize,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          prefixIcon: prefixIcon != null
              ? Container(
                  margin: EdgeInsets.all(ResponsiveService.getSpacing(8)),
                  padding: EdgeInsets.all(ResponsiveService.getSpacing(6)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveService.getSpacing(8)),
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      size: iconSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: prefixIcon!,
                  ),
                )
              : null,
          suffixIcon: suffixIcon != null
              ? Container(
                  margin: EdgeInsets.all(ResponsiveService.getSpacing(8)),
                  child: IconTheme(
                    data: IconThemeData(
                      size: iconSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: suffixIcon!,
                  ),
                )
              : null,
          contentPadding: contentPadding ?? defaultContentPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          counterText: '', // Hide character counter for small screens
        ),
      ),
    );
  }
}

class ResponsiveSearchField extends StatelessWidget with ResponsiveWidget {
  final String? hintText;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;
  final IconData? prefixIcon;
  final Color? backgroundColor;
  final EdgeInsets? contentPadding;

  const ResponsiveSearchField({
    Key? key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onClear,
    this.showClearButton = true,
    this.prefixIcon,
    this.backgroundColor,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: getResponsiveBorderRadius(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: getResponsiveSpacing(8),
            offset: Offset(0, getResponsiveSpacing(2)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: ResponsiveTextStyles.getResponsiveTextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText ?? 'Caută...',
          hintStyle: ResponsiveTextStyles.getResponsiveTextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: prefixIcon != null
              ? Container(
                  margin: EdgeInsets.all(getResponsiveSpacing(8)),
                  padding: EdgeInsets.all(getResponsiveSpacing(10)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: getResponsiveBorderRadius(12),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: Theme.of(context).colorScheme.primary,
                    size: getResponsiveIconSize(20),
                  ),
                )
              : null,
          suffixIcon: showClearButton && controller?.text.isNotEmpty == true
              ? Container(
                  margin: EdgeInsets.all(getResponsiveSpacing(8)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: getResponsiveBorderRadius(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: getResponsiveIconSize(18),
                    ),
                    onPressed: onClear ?? () => controller?.clear(),
                  ),
                )
              : null,
          contentPadding: contentPadding ?? EdgeInsets.symmetric(
            horizontal: getResponsiveSpacing(20),
            vertical: getResponsiveSpacing(16),
          ),
          border: OutlineInputBorder(
            borderRadius: getResponsiveBorderRadius(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: getResponsiveBorderRadius(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: getResponsiveBorderRadius(25),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

class ResponsiveDropdownField<T> extends StatelessWidget with ResponsiveWidget {
  final String? labelText;
  final String? hintText;
  final T? value;
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final bool enabled;

  const ResponsiveDropdownField({
    Key? key,
    this.labelText,
    this.hintText,
    this.value,
    required this.items,
    required this.itemToString,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemToString(item),
            style: ResponsiveTextStyles.getResponsiveTextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: ResponsiveTextStyles.getResponsiveTextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        hintStyle: ResponsiveTextStyles.getResponsiveTextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        prefixIcon: prefixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: getResponsiveSpacing(16),
          vertical: getResponsiveSpacing(12),
        ),
        border: OutlineInputBorder(
          borderRadius: getResponsiveBorderRadius(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: getResponsiveBorderRadius(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: getResponsiveBorderRadius(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.primary,
        size: getResponsiveIconSize(24),
      ),
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: ResponsiveTextStyles.getResponsiveTextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
} 