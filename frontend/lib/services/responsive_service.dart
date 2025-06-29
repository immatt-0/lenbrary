import 'package:flutter/material.dart';

class ResponsiveService {
  static late MediaQueryData _mediaQueryData;
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _pixelRatio;
  static late double _statusBarHeight;
  static late double _bottomBarHeight;
  static late double _textScaleFactor;
  static late double _devicePixelRatio;
  static late Orientation _orientation;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _screenWidth = _mediaQueryData.size.width;
    _screenHeight = _mediaQueryData.size.height;
    _pixelRatio = _mediaQueryData.devicePixelRatio;
    _statusBarHeight = _mediaQueryData.padding.top;
    _bottomBarHeight = _mediaQueryData.padding.bottom;
    _textScaleFactor = _mediaQueryData.textScaleFactor;
    _devicePixelRatio = _mediaQueryData.devicePixelRatio;
    _orientation = _mediaQueryData.orientation;
  }

  // Screen dimensions
  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static double get pixelRatio => _pixelRatio;
  static double get statusBarHeight => _statusBarHeight;
  static double get bottomBarHeight => _bottomBarHeight;
  static double get textScaleFactor => _textScaleFactor;
  static double get devicePixelRatio => _devicePixelRatio;
  static Orientation get orientation => _orientation;

  // Responsive scaling factors - improved for small screens
  static double get scaleFactor {
    // More aggressive scaling for very small screens
    if (_screenWidth < 280) return 0.65; // Very very small phones
    if (_screenWidth < 320) return 0.75; // Very small phones
    if (_screenWidth < 360) return 0.8; // Small phones
    if (_screenWidth < 400) return 0.85; // Medium-small phones
    if (_screenWidth < 480) return 0.9; // Medium phones
    if (_screenWidth < 600) return 0.95; // Large phones
    return 1.0; // Very large phones/tablets
  }

  // Responsive font sizes
  static double getFontSize(double baseSize) {
    return baseSize * scaleFactor;
  }

  // Responsive padding/margin
  static double getSpacing(double baseSpacing) {
    return baseSpacing * scaleFactor;
  }

  // Responsive icon sizes
  static double getIconSize(double baseSize) {
    return baseSize * scaleFactor;
  }

  // Screen size categories - improved for small screens
  static bool get isVerySmallPhone => _screenWidth < 280;
  static bool get isSmallPhone => _screenWidth < 360;
  static bool get isMediumPhone => _screenWidth >= 360 && _screenWidth < 480;
  static bool get isLargePhone => _screenWidth >= 480 && _screenWidth < 600;
  static bool get isTablet => _screenWidth >= 600;

  // Orientation helpers
  static bool get isPortrait => _orientation == Orientation.portrait;
  static bool get isLandscape => _orientation == Orientation.landscape;

  // Responsive breakpoints
  static bool get isCompactLayout => _screenWidth < 400;
  static bool get isStandardLayout => _screenWidth >= 400 && _screenWidth < 600;
  static bool get isExpandedLayout => _screenWidth >= 600;

  // Adaptive card dimensions - improved for small screens
  static double get cardMaxWidth {
    if (isVerySmallPhone) return _screenWidth * 0.98;
    if (isSmallPhone) return _screenWidth * 0.95;
    if (isMediumPhone) return _screenWidth * 0.9;
    if (isLargePhone) return _screenWidth * 0.85;
    return 600; // Max width for tablets
  }

  // Adaptive button sizes - improved for small screens
  static double get buttonHeight {
    if (isVerySmallPhone) return 36;
    if (isSmallPhone) return 40;
    if (isMediumPhone) return 44;
    if (isLargePhone) return 48;
    return 52;
  }

  // Adaptive text field heights - improved for small screens
  static double get textFieldHeight {
    if (isVerySmallPhone) return 40;
    if (isSmallPhone) return 45;
    if (isMediumPhone) return 48;
    if (isLargePhone) return 52;
    return 56;
  }

  // Adaptive dialog sizes - improved for small screens
  static double get dialogWidth {
    if (isVerySmallPhone) return _screenWidth * 0.95;
    if (isSmallPhone) return _screenWidth * 0.9;
    if (isMediumPhone) return _screenWidth * 0.85;
    if (isLargePhone) return _screenWidth * 0.8;
    return 500;
  }

  static double get dialogHeight {
    if (isVerySmallPhone) return _screenHeight * 0.65;
    if (isSmallPhone) return _screenHeight * 0.7;
    if (isMediumPhone) return _screenHeight * 0.75;
    if (isLargePhone) return _screenHeight * 0.8;
    return 600;
  }

  // Additional helpers for very small screens
  static double get minTouchTarget => isVerySmallPhone ? 32 : 44;
  static double get minSpacing => isVerySmallPhone ? 4 : 8;
  static double get maxSpacing => isVerySmallPhone ? 12 : 16;
}

// Responsive widget mixin
mixin ResponsiveWidget {
  double getResponsiveFontSize(double baseSize) {
    return ResponsiveService.getFontSize(baseSize);
  }

  double getResponsiveSpacing(double baseSpacing) {
    return ResponsiveService.getSpacing(baseSpacing);
  }

  double getResponsiveIconSize(double baseSize) {
    return ResponsiveService.getIconSize(baseSize);
  }

  EdgeInsets getResponsivePadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left != null ? getResponsiveSpacing(left) : (horizontal ?? all ?? 0),
      top: top != null ? getResponsiveSpacing(top) : (vertical ?? all ?? 0),
      right: right != null ? getResponsiveSpacing(right) : (horizontal ?? all ?? 0),
      bottom: bottom != null ? getResponsiveSpacing(bottom) : (vertical ?? all ?? 0),
    );
  }

  BorderRadius getResponsiveBorderRadius(double radius) {
    return BorderRadius.circular(getResponsiveSpacing(radius));
  }
}

// Responsive text styles
class ResponsiveTextStyles {
  static TextStyle getResponsiveTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: ResponsiveService.getFontSize(fontSize),
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  static TextStyle getResponsiveTitleStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return getResponsiveTextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }

  static TextStyle getResponsiveBodyStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return getResponsiveTextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }
} 