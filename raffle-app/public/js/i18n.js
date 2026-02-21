/**
 * i18n.js – Lightweight 3-language support for buyer-facing pages.
 * Supported languages: ht (Haitian Creole, default), fr (French), en (English)
 *
 * Usage:
 *   <script src="/js/i18n.js"></script>
 *   <!-- place i18n switcher anywhere with id="lang-switcher" -->
 *   <!-- add data-i18n="key" to translatable elements -->
 *   <!-- for placeholders: data-i18n-placeholder="key" -->
 *   <!-- call applyTranslations() after dynamic DOM changes -->
 */

(function () {
  'use strict';

  var STORAGE_KEY = 'grate_genyen_lang';
  var DEFAULT_LANG = 'ht';
  var _supportedLocales = { ht: true, fr: true, en: true };

  var translations = {
    // Welcome overlay
    welcome_line1: { ht: 'Byenvini nan', fr: 'Bienvenue sur', en: 'Welcome to' },
    welcome_line2: { ht: 'Grate Genyen', fr: 'Grate Genyen', en: 'Grate Genyen' },

    // Header
    header_title: { ht: '🎟️ Pòtay Achetè', fr: '🎟️ Portail Acheteurs', en: '🎟️ Buyers Portal' },
    back_home: { ht: '← Retounen', fr: '← Retour', en: '← Back to Home' },

    // Global error banner
    critical_error: { ht: '⚠️ Erè Kritik', fr: '⚠️ Erreur Critique', en: '⚠️ Critical Error' },
    retry: { ht: '🔄 Eseye Ankò', fr: '🔄 Réessayer', en: '🔄 Retry' },

    // Tabs
    tab_raffle_info: { ht: '📋 Tiraj Info', fr: '📋 Info Tirage', en: '📋 Raffle Info' },
    tab_purchase: { ht: '💳 Achte Tikè', fr: '💳 Acheter des billets', en: '💳 Purchase Tickets' },
    tab_scratch: { ht: '🎰 Graten & Genyen', fr: '🎰 Gratter & Gagner', en: '🎰 Scratch & Win' },
    tab_my_tickets: { ht: '👤 Tikè Mwen', fr: '👤 Mes billets', en: '👤 My Tickets' },
    tab_verify: { ht: '✅ Verifye Tikè', fr: '✅ Vérifier le billet', en: '✅ Verify Ticket' },

    // Raffle info tab
    raffle_info_title: { ht: 'Enfòmasyon Tiraj Aktyèl', fr: 'Informations sur le tirage actuel', en: 'Current Raffle Information' },
    loading_raffle: { ht: 'Chajman enfòmasyon tiraj...', fr: 'Chargement des informations...', en: 'Loading raffle information...' },

    // Purchase tab
    purchase_title: { ht: '💳 Achte Tikè Tiraj', fr: '💳 Acheter des billets de tirage', en: '💳 Purchase Raffle Tickets' },
    purchase_subtitle: { ht: 'Chwazi metòd peman ou pou achte tikè tiraj. Nou sipòte plizyè opsyon peman pou konveniyans ou.', fr: 'Sélectionnez votre mode de paiement préféré pour acheter des billets de tirage.', en: 'Select your preferred payment method below to purchase raffle tickets. We support multiple payment options for your convenience.' },
    step1_title: { ht: '📝 Etap 1: Enfòmasyon Ou', fr: '📝 Étape 1: Vos informations', en: '📝 Step 1: Your Information' },
    label_full_name: { ht: 'Non Konplè *', fr: 'Nom complet *', en: 'Full Name *' },
    placeholder_full_name: { ht: 'Antre non konplè ou', fr: 'Entrez votre nom complet', en: 'Enter your full name' },
    label_phone: { ht: 'Nimewo Telefòn *', fr: 'Numéro de téléphone *', en: 'Phone Number *' },
    phone_sms_hint: { ht: 'Ou pral resevwa SMS sou acha ou', fr: 'Vous recevrez des SMS sur votre achat', en: "You'll receive SMS updates about your purchase" },
    label_department: { ht: 'Depatman *', fr: 'Département *', en: 'Department *' },
    select_department: { ht: 'Chwazi depatman ou...', fr: 'Choisissez votre département...', en: 'Select your department...' },
    department_hint: { ht: 'Ki depatman ou soti?', fr: 'De quel département venez-vous?', en: 'Which department are you from?' },
    label_email: { ht: 'Adrès Imèl', fr: 'Adresse e-mail', en: 'Email Address' },
    email_optional_hint: { ht: 'Opsyonèl: Pou resi imèl', fr: 'Optionnel : Pour les reçus par e-mail', en: 'Optional: For email receipts' },
    label_category: { ht: 'Kategori Tikè *', fr: 'Catégorie de billet *', en: 'Ticket Category *' },
    select_category: { ht: 'Chwazi yon kategori...', fr: 'Choisissez une catégorie...', en: 'Select a category...' },
    label_quantity: { ht: 'Kantite Tikè *', fr: 'Nombre de billets *', en: 'Number of Tickets *' },
    max_tickets_hint: { ht: 'Maksimòm 10 tikè pa tranzaksyon', fr: 'Maximum 10 billets par transaction', en: 'Maximum 10 tickets per transaction' },
    total_amount: { ht: 'Montan Total:', fr: 'Montant total:', en: 'Total Amount:' },
    continue_payment: { ht: 'Kontinye ak Peman →', fr: 'Continuer le paiement →', en: 'Continue to Payment →' },
    back_to_info: { ht: '← Retounen nan Enfòmasyon', fr: '← Retour aux informations', en: '← Back to Information' },
    step2_title: { ht: '💳 Etap 2: Chwazi Metòd Peman', fr: '💳 Étape 2: Choisir le mode de paiement', en: '💳 Step 2: Choose Payment Method' },
    loading_payment: { ht: 'Chajman metòd peman...', fr: 'Chargement des modes de paiement...', en: 'Loading payment methods...' },
    back_to_payment: { ht: '← Retounen nan Metòd Peman', fr: '← Retour aux modes de paiement', en: '← Back to Payment Methods' },

    // My Tickets tab
    my_tickets_title: { ht: 'Chèche Tikè Mwen', fr: 'Rechercher mes billets', en: 'Look Up My Tickets' },
    my_tickets_subtitle: { ht: 'Antre imèl, nimewo telefòn, oswa kòd achetè ou pou wè tikè ou achte.', fr: 'Entrez votre e-mail, numéro de téléphone ou code acheteur pour voir vos billets achetés.', en: 'Enter your email, phone number, or buyer code to view your purchased tickets.' },
    label_email_lookup: { ht: 'Adrès Imèl', fr: 'Adresse e-mail', en: 'Email Address' },
    email_lookup_hint: { ht: 'Antre imèl ou te itilize lè ou te achte tikè', fr: "Entrez l'e-mail utilisé lors de l'achat des billets", en: 'Enter the email address used when purchasing tickets' },
    label_phone_lookup: { ht: 'Nimewo Telefòn', fr: 'Numéro de téléphone', en: 'Phone Number' },
    phone_lookup_hint: { ht: 'Antre nimewo telefòn nan nenpòt fòma (ex: 123-456-7890 oswa 1234567890)', fr: 'Entrez le numéro de téléphone dans n\'importe quel format', en: 'Enter phone number in any format (e.g., 123-456-7890 or 1234567890)' },
    label_buyer_code: { ht: 'Kòd Achetè (soti nan resi)', fr: "Code acheteur (du reçu)", en: 'Buyer Code (from receipt)' },
    buyer_code_hint: { ht: 'Jwenn kòd inik achetè ou sou resi tikè oswa imèl konfirmasyon ou', fr: 'Trouvez votre code acheteur unique sur votre reçu ou e-mail de confirmation', en: 'Find your unique buyer code on your ticket receipt or confirmation email' },
    find_my_tickets: { ht: '🔍 Jwenn Tikè Mwen', fr: '🔍 Trouver mes billets', en: '🔍 Find My Tickets' },

    // Verify tab
    verify_title: { ht: 'Verifye Estati Tikè', fr: 'Vérifier le statut du billet', en: 'Verify Ticket Status' },
    verify_subtitle: { ht: 'Tcheke si nimewo tikè oswa bawkòd valid epi wè estati aktyèl li.', fr: 'Vérifiez si un numéro de billet ou un code-barres est valide et voyez son statut actuel.', en: 'Check if a ticket number or barcode is valid and see its current status.' },
    label_ticket_number: { ht: 'Nimewo Tikè oswa Bawkòd', fr: 'Numéro de billet ou code-barres', en: 'Ticket Number or Barcode' },
    ticket_number_hint: { ht: 'Antre nimewo tikè oswa eskane bawkòd pou verifye estati li', fr: 'Entrez le numéro de billet ou scannez le code-barres pour vérifier son statut', en: 'Enter the ticket number or scan the barcode to verify its status' },
    verify_btn: { ht: '✅ Verifye Tikè', fr: '✅ Vérifier le billet', en: '✅ Verify Ticket' },

    // Scratch tab
    scratch_title: { ht: '🎰 GRATE GENYEN - Graten & Genyen!', fr: '🎰 GRATE GENYEN - Gratter & Gagner!', en: '🎰 GRATE GENYEN - Scratch & Win!' },
  };

  /**
   * Detect locale from browser, falling back to DEFAULT_LANG.
   * Only 'ht' and 'fr' are recognized from the browser; everything else → 'ht'.
   */
  function detectLocale() {
    var nav = (navigator.language || navigator.userLanguage || '').toLowerCase();
    if (nav.startsWith('fr')) return 'fr';
    if (nav.startsWith('ht')) return 'ht';
    return DEFAULT_LANG;
  }

  /**
   * Return the active language code.
   */
  function getLocale() {
    var saved = localStorage.getItem(STORAGE_KEY);
    if (saved && _supportedLocales[saved]) return saved;
    return detectLocale();
  }

  /**
   * Translate a key, returning the translation for the current locale.
   */
  function t(key) {
    var lang = getLocale();
    var entry = translations[key];
    if (!entry) return key;
    return entry[lang] || entry[DEFAULT_LANG] || key;
  }

  /**
   * Apply translations to all data-i18n and data-i18n-placeholder elements.
   */
  function applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var key = el.getAttribute('data-i18n');
      var value = t(key);
      el.textContent = value;
    });

    document.querySelectorAll('[data-i18n-placeholder]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-placeholder');
      el.placeholder = t(key);
    });

    // Update lang switcher active state
    var lang = getLocale();
    document.querySelectorAll('.lang-btn').forEach(function (btn) {
      btn.classList.toggle('lang-btn-active', btn.dataset.lang === lang);
    });
  }

  /**
   * Set the active language and re-apply translations.
   */
  function setLocale(lang) {
    if (!_supportedLocales[lang]) return;
    localStorage.setItem(STORAGE_KEY, lang);
    applyTranslations();
  }

  /**
   * Inject the language switcher into any element with id="lang-switcher".
   */
  function injectSwitcher() {
    var container = document.getElementById('lang-switcher');
    if (!container) return;
    var lang = getLocale();
    container.innerHTML = '';

    [
      { code: 'ht', label: 'Kreyòl' },
      { code: 'fr', label: 'FR' },
      { code: 'en', label: 'EN' },
    ].forEach(function (item) {
      var btn = document.createElement('button');
      btn.className = 'lang-btn' + (item.code === lang ? ' lang-btn-active' : '');
      btn.dataset.lang = item.code;
      btn.textContent = item.label;
      btn.addEventListener('click', function () { setLocale(item.code); });
      container.appendChild(btn);
    });
  }

  // Public API
  window.i18n = {
    t: t,
    setLocale: setLocale,
    getLocale: getLocale,
    applyTranslations: applyTranslations,
  };

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      injectSwitcher();
      applyTranslations();
    });
  } else {
    injectSwitcher();
    applyTranslations();
  }
})();
