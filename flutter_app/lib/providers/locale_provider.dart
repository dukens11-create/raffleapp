import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'selected_language';
  static const List<String> supportedLocales = ['ht', 'fr', 'en'];
  static const _defaultLocale = 'ht';

  String _currentLocale = _defaultLocale;

  String get currentLocale => _currentLocale;

  static const Map<String, Map<String, String>> _translations = {
    // Navigation/tabs
    'nav_home': {'ht': 'Akèy', 'fr': 'Accueil', 'en': 'Home'},
    'nav_tickets': {'ht': 'Tikè', 'fr': 'Billets', 'en': 'Tickets'},
    'nav_my_tickets': {'ht': 'Achte', 'fr': 'Mes achats', 'en': 'My Purchases'},

    // Home screen
    'welcome_title': {
      'ht': 'Byenvini nan Grate Genyen!',
      'fr': 'Bienvenue sur Grate Genyen!',
      'en': 'Welcome to Grate Genyen!',
    },
    'draw_date': {'ht': 'Tiraj', 'fr': 'Date du tirage', 'en': 'Draw Date'},
    'stat_total': {'ht': 'Total Tikè', 'fr': 'Total Billets', 'en': 'Total Tickets'},
    'stat_available': {'ht': 'Disponib', 'fr': 'Disponible', 'en': 'Available'},
    'stat_sold': {'ht': 'Vandi', 'fr': 'Vendus', 'en': 'Sold'},
    'categories_title': {
      'ht': 'Kategori Tikè Disponib',
      'fr': 'Catégories de billets disponibles',
      'en': 'Available Ticket Categories',
    },
    'category_available': {'ht': 'Disponib', 'fr': 'Disponible', 'en': 'Available'},
    'category_sold_out': {'ht': 'EPUIZE', 'fr': 'ÉPUISÉ', 'en': 'SOLD OUT'},
    'quick_actions': {'ht': 'Aksyon Rapid', 'fr': 'Actions rapides', 'en': 'Quick Actions'},
    'buy_tickets': {'ht': 'Achte Tikè', 'fr': 'Acheter des billets', 'en': 'Buy Tickets'},
    'buy_tickets_sub': {
      'ht': 'Chwazi epi peye tikè w',
      'fr': 'Choisissez et payez votre billet',
      'en': 'Choose and pay for your ticket',
    },
    'my_tickets': {'ht': 'Wè Tikè Mwen', 'fr': 'Voir mes billets', 'en': 'View My Tickets'},
    'my_tickets_sub': {
      'ht': 'Tcheke tikè ou achte',
      'fr': 'Vérifier les billets achetés',
      'en': 'Check purchased tickets',
    },
    'scan_qr': {'ht': 'Skane Kòd QR', 'fr': 'Scanner le code QR', 'en': 'Scan QR Code'},
    'scan_qr_sub': {
      'ht': 'Verifye tikè ak kòd QR',
      'fr': 'Vérifier le billet avec QR',
      'en': 'Verify ticket with QR code',
    },
    'loading': {
      'ht': 'Chajman enfòmasyon...',
      'fr': 'Chargement des informations...',
      'en': 'Loading information...',
    },
    'no_active_raffle': {
      'ht': 'Pa gen tiraj aktif',
      'fr': 'Pas de tirage actif',
      'en': 'No active raffle',
    },
    'come_back_later': {
      'ht': 'Tanpri, retounen pi ta',
      'fr': 'Veuillez revenir plus tard',
      'en': 'Please come back later',
    },

    // Tickets list screen
    'available_tickets': {
      'ht': 'Tikè Disponib',
      'fr': 'Billets disponibles',
      'en': 'Available Tickets',
    },
    'loading_tickets': {
      'ht': 'Chajman tikè...',
      'fr': 'Chargement des billets...',
      'en': 'Loading tickets...',
    },
    'no_tickets': {
      'ht': 'Pa gen tikè disponib',
      'fr': 'Pas de billets disponibles',
      'en': 'No tickets available',
    },
    'try_another': {
      'ht': 'Tanpri eseye yon lòt kategori',
      'fr': 'Essayez une autre catégorie',
      'en': 'Please try another category',
    },
    'all_categories': {'ht': 'Tout', 'fr': 'Tous', 'en': 'All'},
    'end_of_list': {
      'ht': 'Ou wè tout tikè yo',
      'fr': 'Vous avez vu tous les billets',
      'en': "You've seen all tickets",
    },
    'filter_tickets': {
      'ht': 'Filtre Tikè',
      'fr': 'Filtrer les billets',
      'en': 'Filter Tickets',
    },
    'choose_category': {
      'ht': 'Chwazi kategori:',
      'fr': 'Choisir une catégorie:',
      'en': 'Choose category:',
    },
    'all_categories_option': {
      'ht': 'Tout Kategori',
      'fr': 'Toutes les catégories',
      'en': 'All Categories',
    },
    'close': {'ht': 'Fèmen', 'fr': 'Fermer', 'en': 'Close'},
    'ticket_details': {
      'ht': 'Detay Tikè',
      'fr': 'Détails du billet',
      'en': 'Ticket Details',
    },
    'ticket_number': {
      'ht': 'Nimewo Tikè',
      'fr': 'Numéro de billet',
      'en': 'Ticket Number',
    },
    'category': {'ht': 'Kategori', 'fr': 'Catégorie', 'en': 'Category'},
    'price': {'ht': 'Pri', 'fr': 'Prix', 'en': 'Price'},
    'status': {'ht': 'Estati', 'fr': 'Statut', 'en': 'Status'},
    'department': {'ht': 'Depatman', 'fr': 'Département', 'en': 'Department'},

    // My tickets screen
    'my_tickets_title': {'ht': 'Tikè Mwen', 'fr': 'Mes billets', 'en': 'My Tickets'},
    'enter_phone': {
      'ht': 'Antre Nimewo Telefòn Ou',
      'fr': 'Entrez votre numéro de téléphone',
      'en': 'Enter Your Phone Number',
    },
    'phone_subtitle': {
      'ht': 'Antre nimewo telefòn ou te itilize pou achte tikè yo',
      'fr': "Entrez le numéro de téléphone utilisé pour acheter les billets",
      'en': 'Enter the phone number used to buy tickets',
    },
    'phone_label': {
      'ht': 'Nimewo Telefòn',
      'fr': 'Numéro de téléphone',
      'en': 'Phone Number',
    },
    'phone_hint': {
      'ht': '509-XXXX-XXXX',
      'fr': '509-XXXX-XXXX',
      'en': '509-XXXX-XXXX',
    },
    'search_my_tickets': {
      'ht': 'Chèche Tikè Mwen',
      'fr': 'Chercher mes billets',
      'en': 'Search My Tickets',
    },
    'phone_required': {
      'ht': 'Tanpri antre yon nimewo telefòn',
      'fr': 'Veuillez entrer un numéro de téléphone',
      'en': 'Please enter a phone number',
    },
    'change': {'ht': 'Chanje', 'fr': 'Changer', 'en': 'Change'},
    'all_tickets_filter': {
      'ht': 'Tout Tikè',
      'fr': 'Tous les billets',
      'en': 'All Tickets',
    },
    'sold_tickets_filter': {
      'ht': 'Tikè Vandi',
      'fr': 'Billets vendus',
      'en': 'Sold Tickets',
    },
    'no_tickets_phone': {'ht': 'Pa gen tikè', 'fr': 'Pas de billet', 'en': 'No Tickets'},
    'no_tickets_phone_sub': {
      'ht': 'Ou poko achte tikè ak nimewo sa a',
      'fr': "Vous n'avez pas encore acheté de billet avec ce numéro",
      'en': "You haven't bought tickets with this number",
    },
    'try_another_number': {
      'ht': 'Eseye yon lòt nimewo',
      'fr': 'Essayer un autre numéro',
      'en': 'Try Another Number',
    },
    'loading_my_tickets': {
      'ht': 'Chajman tikè ou yo...',
      'fr': 'Chargement de vos billets...',
      'en': 'Loading your tickets...',
    },
    'show_qr': {'ht': 'Montre QR', 'fr': 'Afficher QR', 'en': 'Show QR'},
    'qr_coming_soon': {
      'ht': 'Kòd QR ap vini byento',
      'fr': 'Code QR bientôt disponible',
      'en': 'QR Code coming soon',
    },
    'ticket_count_label': {'ht': 'Tikè', 'fr': 'Billets', 'en': 'Tickets'},
    'purchase_date': {
      'ht': 'Dat Acha',
      'fr': "Date d'achat",
      'en': 'Purchase Date',
    },
    'buyer_name': {'ht': 'Non', 'fr': 'Nom', 'en': 'Name'},
    'buyer_phone': {'ht': 'Telefòn', 'fr': 'Téléphone', 'en': 'Phone'},

    // Payment screen
    'buy_tickets_title': {
      'ht': 'Achte Tikè',
      'fr': 'Acheter des billets',
      'en': 'Buy Tickets',
    },
    'payment_info': {
      'ht':
          'Ranpli fòmilè a pou achte tikè ou. Ou pral redirije nan MonCash pou peye.',
      'fr':
          'Remplissez le formulaire pour acheter votre billet. Vous serez redirigé vers MonCash pour le paiement.',
      'en':
          'Fill the form to buy your ticket. You will be redirected to MonCash for payment.',
    },
    'no_raffle_available': {
      'ht': 'Pa gen tiraj disponib',
      'fr': 'Pas de tirage disponible',
      'en': 'No raffle available',
    },
    'come_back_later_raffle': {
      'ht': 'Tanpri retounen pi ta',
      'fr': 'Veuillez revenir plus tard',
      'en': 'Please come back later',
    },
    'payment_initiated': {
      'ht': 'Peman Inisye!',
      'fr': 'Paiement initié!',
      'en': 'Payment Initiated!',
    },
    'reference': {'ht': 'Referans', 'fr': 'Référence', 'en': 'Reference'},
    'your_tickets': {'ht': 'Tikè ou yo:', 'fr': 'Vos billets:', 'en': 'Your tickets:'},
    'continue_payment': {
      'ht': 'Kontinye ak Peman',
      'fr': 'Continuer le paiement',
      'en': 'Continue to Payment',
    },
    'processing': {
      'ht': 'Trete peman...',
      'fr': 'Traitement du paiement...',
      'en': 'Processing payment...',
    },
    'payment_success': {
      'ht': 'Peman ou te inisye avèk siksè!',
      'fr': 'Votre paiement a été initié avec succès!',
      'en': 'Your payment was successfully initiated!',
    },
    'return_back': {'ht': 'Retounen', 'fr': 'Retour', 'en': 'Return'},
    'moncash_dialog_info': {
      'ht':
          'Nan yon aplikasyon reyèl, ou ta louvri lyen peman sa a nan yon navigatè oswa WebView:',
      'fr':
          'Dans une vraie application, vous ouvrirez ce lien de paiement dans un navigateur ou WebView:',
      'en':
          'In a real app, you would open this payment link in a browser or WebView:',
    },

    // Language switcher
    'language_ht': {'ht': 'Kreyòl', 'fr': 'Kreyòl', 'en': 'Kreyòl'},
    'language_fr': {'ht': 'Français', 'fr': 'Français', 'en': 'Français'},
    'language_en': {'ht': 'English', 'fr': 'English', 'en': 'English'},
  };

  String translate(String key) {
    return _translations[key]?[_currentLocale] ??
        _translations[key]?[_defaultLocale] ??
        key;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && supportedLocales.contains(saved)) {
      _currentLocale = saved;
    } else {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final langCode = deviceLocale.languageCode;
      if (langCode == 'ht' || langCode == 'fr') {
        _currentLocale = langCode;
      } else {
        _currentLocale = _defaultLocale;
      }
      await prefs.setString(_prefKey, _currentLocale);
    }
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    if (!supportedLocales.contains(langCode)) return;
    _currentLocale = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
    notifyListeners();
  }
}
