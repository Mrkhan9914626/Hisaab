import 'dart:math' as math;

import 'package:expense_tracker/core/presentation/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('light tokens meet text and non-text contrast', () {
    expect(
      _contrast(AppTheme.lightText, AppTheme.lightSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppTheme.lightMuted, AppTheme.lightBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppTheme.lightPrimary, AppTheme.lightSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppTheme.lightOutline, AppTheme.lightSurface),
      greaterThanOrEqualTo(3.0),
    );
    expect(
      _contrast(AppTheme.lightError, AppTheme.lightSurface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('dark tokens meet text and non-text contrast', () {
    expect(
      _contrast(AppTheme.darkText, AppTheme.darkBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppTheme.darkMuted, AppTheme.darkBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppTheme.darkPrimary, AppTheme.darkSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppTheme.darkOutline, AppTheme.darkSurface),
      greaterThanOrEqualTo(3.0),
    );
    expect(
      _contrast(AppTheme.darkError, AppTheme.darkSurface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('uses the platform minimum touch targets', () {
    expect(AppTheme.minTargetFor(TargetPlatform.iOS), 44);
    expect(AppTheme.minTargetFor(TargetPlatform.android), 48);
  });
}
