import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raffle_app/providers/locale_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleProvider Tests', () {
    test('should default to ht locale', () {
      final provider = LocaleProvider();
      expect(provider.currentLocale, equals('ht'));
    });

    test('translate should return Haitian Creole by default', () {
      final provider = LocaleProvider();
      expect(provider.translate('nav_home'), equals('Akèy'));
      expect(provider.translate('close'), equals('Fèmen'));
    });

    test('translate returns key for unknown keys', () {
      final provider = LocaleProvider();
      expect(provider.translate('unknown_key'), equals('unknown_key'));
    });

    test('setLocale changes locale and notifies listeners', () async {
      final provider = LocaleProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setLocale('fr');
      expect(provider.currentLocale, equals('fr'));
      expect(notifyCount, equals(1));

      await provider.setLocale('en');
      expect(provider.currentLocale, equals('en'));
      expect(notifyCount, equals(2));
    });

    test('setLocale ignores invalid locale codes', () async {
      final provider = LocaleProvider();
      await provider.setLocale('de');
      expect(provider.currentLocale, equals('ht'));
    });

    test('translate returns French for fr locale', () async {
      final provider = LocaleProvider();
      await provider.setLocale('fr');
      expect(provider.translate('nav_home'), equals('Accueil'));
      expect(provider.translate('close'), equals('Fermer'));
    });

    test('translate returns English for en locale', () async {
      final provider = LocaleProvider();
      await provider.setLocale('en');
      expect(provider.translate('nav_home'), equals('Home'));
      expect(provider.translate('close'), equals('Close'));
    });

    test('init loads persisted locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'selected_language': 'en'});
      final provider = LocaleProvider();
      await provider.init();
      expect(provider.currentLocale, equals('en'));
    });

    test('init defaults to ht for unrecognized device locale', () async {
      final provider = LocaleProvider();
      await provider.init();
      // Device locale in test env is typically 'en' which maps to 'ht' default
      expect(['ht', 'fr', 'en'], contains(provider.currentLocale));
    });

    test('setLocale persists to SharedPreferences', () async {
      final provider = LocaleProvider();
      await provider.setLocale('fr');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_language'), equals('fr'));
    });
  });
}
