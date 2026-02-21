import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/locale_provider.dart';

/// A compact language switcher widget showing Kreyòl / FR / EN buttons.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, locale, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangButton(code: 'ht', label: 'Kreyòl', current: locale.currentLocale),
            const SizedBox(width: 4),
            _LangButton(code: 'fr', label: 'FR', current: locale.currentLocale),
            const SizedBox(width: 4),
            _LangButton(code: 'en', label: 'EN', current: locale.currentLocale),
          ],
        );
      },
    );
  }
}

class _LangButton extends StatelessWidget {
  final String code;
  final String label;
  final String current;

  const _LangButton({
    required this.code,
    required this.label,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = code == current;
    return GestureDetector(
      onTap: () => context.read<LocaleProvider>().setLocale(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.green[800] : Colors.white,
          ),
        ),
      ),
    );
  }
}
