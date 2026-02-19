import 'package:flutter/material.dart';
import 'accessibility_utils.dart';

/// Accessible button widget with proper semantics and touch targets
class AccessibleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? semanticLabel;
  final String? semanticHint;
  final bool isLoading;
  final EdgeInsets? padding;

  const AccessibleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
    this.semanticHint,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonText = text;
    final label = semanticLabel ?? buttonText;
    final hint = semanticHint ?? (onPressed == null ? 'Button is disabled' : null);

    return Semantics(
      label: AccessibilityUtils.buttonLabel(label, hint: hint),
      button: true,
      enabled: onPressed != null && !isLoading,
      child: AccessibilityUtils.ensureMinTouchTarget(
        ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            minimumSize: Size(
              AccessibilityUtils.minTouchTargetSize,
              AccessibilityUtils.minTouchTargetSize,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon),
                      const SizedBox(width: 8),
                    ],
                    Text(buttonText),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Accessible icon button with proper semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final Color? color;
  final double? size;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityUtils.buttonLabel(semanticLabel, hint: semanticHint),
      button: true,
      enabled: onPressed != null,
      child: AccessibilityUtils.ensureMinTouchTarget(
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: color,
          iconSize: size ?? 24,
          tooltip: semanticLabel,
        ),
      ),
    );
  }
}

/// Accessible text button
class AccessibleTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticHint;

  const AccessibleTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityUtils.buttonLabel(
        semanticLabel ?? text,
        hint: semanticHint,
      ),
      button: true,
      enabled: onPressed != null,
      child: AccessibilityUtils.ensureMinTouchTarget(
        TextButton(
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }
}

/// Accessible checkbox
class AccessibleCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final String? semanticHint;

  const AccessibleCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    required this.label,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: semanticHint,
      checked: value,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
