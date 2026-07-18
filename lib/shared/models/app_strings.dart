/// Localised strings for English, Amharic, and Somali.
class AppStrings {
  final String locale;
  const AppStrings(this.locale);

  bool get isAmharic => locale == 'am';
  bool get isSomali => locale == 'so';

  String _t(String en, String am, String so) => locale == 'am'
      ? am
      : locale == 'so'
      ? so
      : en;

  // ── App-wide ────────────────────────────────────────────────────────────────
  String get appName => _t('Koolan', 'ኩላን', 'Koolan');
  String get commonRetry => _t('Retry', 'እንደገና ይሞክሩ', 'Isku day mar kale');
  String get commonLoading => _t('Loading…', 'በመጫን ላይ…', 'Waa la soo rarayaa…');

  // ── Auth / Onboarding ───────────────────────────────────────────────────────
  String get authTitle =>
      _t('Welcome to Koolan', 'እንኳን ወደ ኩላን በደህና መጡ', 'Ku soo dhawow Koolan');
  String get authSubtitle => _t(
    'Sign in to browse, post, and chat in Jigjiga.',
    'በጂግጂጋ ለማስላት፣ ለመለጠፍ እና ለመወያየት ይግቡ።',
    'Gal si aad u baarto, u dajiso, oo aad ula sheekaysato Jigjiga.',
  );
  String get authSignIn => _t('Sign In', 'ግባ', 'Gal');
  String get authSignUp => _t('Sign Up', 'ተመዝገብ', 'Is diiwaangeli');
  String get authEmail => _t('Email', 'ኢሜይል', 'Iimaylka');
  String get authEmailRequired =>
      _t('Email is required', 'ኢሜይል ያስፈልጋል', 'Iimaylka waa lagama maarmaan');
  String get authEmailInvalid =>
      _t('Enter a valid email', 'ትክክለኛ ኢሜይል ያስገቡ', 'Geli iimayl sax ah');
  String get authPassword => _t('Password', 'የይለፍ ቃል', 'Furaha sirta ah');
  String get authPasswordMin =>
      _t('At least 6 characters', 'ቢያንስ 6 ቁምፊ', 'Ugu yaraan 6 xaraf');
  String get authConfirmationRequired => _t(
    'Email confirmation is required. Please verify your email to continue.',
    'የኢሜይል ማረጋገጫ ያስፈልጋል። የኢሜይልዎን እቃ እባክዎን ያረጋግጡ።',
    'Xaqiijinta iimaylka waa loo baahan yahay. Fadlan xaqiiji iimaylkaaga si aad u sii wadato.',
  );
  String get authForgotPassword =>
      _t('Forgot password?', 'የፓስወርድ ይዘው አርጉ?', 'Ilaawi erayga sirta?');
  String get authPleaseWait => _t('Please wait…', 'እባክዎ ይጠብቁ…', 'Fadlan sug…');
  String get authCreateAccount =>
      _t('Create Account', 'መለያ ፍጠር', 'Samee akoon');
  String get authContinue => _t('Continue', 'ቀጥል', 'Sii wad');
  String get authOrContinue =>
      _t('or continue with', 'ወይም በ', 'ama ku sii wad');
  String get authGoogle =>
      _t('Continue with Google', 'በ Google ግባ', 'Google ku sii wad');
  String get authFacebook =>
      _t('Continue with Facebook', 'በ Facebook ግባ', 'Facebook ku sii wad');

  // ── Language onboarding ───────────────────────────────────────────────────────
  String get languageTitle =>
      _t('Choose your language', 'ቋንቋዎን ይምረጡ', 'Dooro luqaddaada');
  String get languageSubtitle => _t(
    'You can change this anytime in Settings.',
    'በቅንብሮች ውስጥ በማንኛውም ጊዜ መቀየር ይችላሉ።',
    'Waxaad beddeli kartaa wakhti kasta Dejinta.',
  );
  String get languageEnglish => _t('English', 'English', 'English');
  String get languageAmharic => _t('Amharic', 'አማርኛ', 'Amharic');
  String get languageSomali => _t('Somali', 'Somali', 'Somali');
  String get languageContinue =>
      _t('Continue to Koolan', 'ወደ ኩላን ቀጥል', 'U gudub Koolan');

  // ── Listing ─────────────────────────────────────────────────────────────────
  String get listingNotFound =>
      _t('Listing not found', 'ዝርዝር አልተገኘም', 'Xayaysiiska lama helin');
  String get listingMyAd => _t('My Ad', 'የኔ ማስታወቂያ', 'Xayaysiiskayga');

  // ── Bottom Navigation ───────────────────────────────────────────────────────
  String get navHome => _t('Home', 'ዋና ገጽ', 'Guriga');
  String get navSaved => _t('Saved', 'የተቀመጡ', 'La kaydiyey');
  String get navPost => _t('Post', 'አስተዋውቅ', 'Ku daji');
  String get navMessages => _t('Messages', 'መልዕክቶች', 'Farriimaha');
  String get navProfile => _t('Profile', 'መገለጫ', 'Xogta');

  // ── Home Screen ─────────────────────────────────────────────────────────────
  String get homeGreeting =>
      _t('Find what you need', 'የሚፈልጉትን ያግኙ', 'Hel waxa aad u baahan tahay');
  String get homeCategoryCars => _t('Cars', 'መኪናዎች', 'Gawaarida');
  String get homeCategoryHouses => _t('Houses', 'ቤቶች', 'Guryaha');
  String get homeCategoryLand => _t('Land', 'መሬት', 'Dhul');
  String get homeCategorySkills => _t('Skills', 'ችሎታዎች', 'Xirfadlayaasha');
  String get homeSearchHint =>
      _t('Search listings...', 'ዝርዝሮችን ፈልግ...', 'Raadi xayaysiisyada...');
  String get homeRecentlyAdded =>
      _t('Recently Added Near You', 'በአቅራቢያዎ አዲስ የተጨመሩ', 'Dhawaan lagu daray');
  String get homeViewAll => _t(
    'View All Recent Listings',
    'ሁሉንም ዝርዝሮች ይመልከቱ',
    'Arag dhammaan xayaysiisyada',
  );
  String get homeTrustTitle =>
      _t('Trusted Community', 'ታመነ ማህበረሰብ', 'Bulshada la믿aha ah');
  String get homeVerifiedStats => _t(
    '98% verified listings in Jigjiga',
    '98% የተረጋገጡ ዝርዝሮች',
    '98% xayaysiis xaqiijiyey',
  );
  String get homeSeeStats => _t('See stats', 'ስታቲስቲክስ ይመልከቱ', 'Arag tirooyin');
  String get homeNoNotifications => _t(
    'No new notifications',
    'አዲስ ማሳወቂያ የለም',
    'Wax ogeysiis cusub ma jiraan',
  );

  // ── Category List Screen ────────────────────────────────────────────────────
  String get catVerifiedOnly =>
      _t('Verified only', 'የተረጋገጡ ብቻ', 'Kuwa xaqiijiyey oo kaliya');
  String get catAll => _t('All', 'ሁሉም', 'Dhammaan');
  String get catForSale => _t('For Sale', 'ለሽያጭ', 'Iib');
  String get catForRent => _t('For Rent', 'ለኪራይ', 'Kiradda');
  String get catNewOnly => _t('New only', 'አዲስ ብቻ', 'Cusub oo kaliya');

  // ── Listing Detail Screen ───────────────────────────────────────────────────
  String get detailSeller => _t('Seller', 'ሻጭ', 'Iibiyaha');
  String get detailContact => _t('Contact', 'ያግኙ', 'La xiriir');
  String get detailChat => _t('Chat', 'ቻት', 'Sheekeyso');
  String get detailViewProfile =>
      _t('View Profile', 'መገለጫ ይመልከቱ', 'Arag xogta');
  String get detailRequestHire => _t('Request Hire', 'ቅጠር ጠይቅ', 'Dalbo shaqo');
  String get detailViewProperty =>
      _t('View Property', 'ሪል እስቴት ይመልከቱ', 'Arag hantida');
  String get detailDescription => _t('Description', 'መግለጫ', 'Sharaxaad');
  String get detailSpecs => _t('Specifications', 'ዝርዝሮች', 'Sifooyinka');
  String get detailVerified => _t('Verified', 'የተረጋገጠ', 'Xaqiijiyey');
  String get detailReviews => _t('reviews', 'ግምገማዎች', 'dib-u-eegis');
  String get detailProfileVerified => _t(
    'Full profile verification: OK',
    'ሙሉ የመገለጫ ማረጋገጫ: ተሳካ',
    'Xaqiijinta xogta: OK',
  );

  // ── Saved Screen ────────────────────────────────────────────────────────────
  String get savedTitle =>
      _t('Saved Listings', 'የተቀመጡ ዝርዝሮች', 'Liiska la kaydiyey');
  String get savedEmpty =>
      _t('Nothing saved yet', 'ምንም አልተቀመጠም', 'Wax la kaydin ma jiro');
  String get savedEmptySub => _t(
    'Bookmark listings while browsing',
    'ዝርዝሮችን ሲያስሱ ምልክት ያድርጉባቸው',
    'Calaamadee xayaysiisyada',
  );
  String get savedCompare => _t('Compare', 'ያወዳድሩ', 'Is-bar-bar dhig');
  String get savedDone => _t('Done', 'ተጠናቋል', 'Dhammaatay');
  String get savedSelectTwo => _t(
    'Select up to 2 listings',
    'እስከ 2 ዝርዝሮች ይምረጡ',
    'Dooro ilaa 2 xayaysiis',
  );
  String get savedCompareButton => _t('Compare', 'ያወዳድሩ', 'Is-bar-bar dhig');

  // ── Compare Overlay ─────────────────────────────────────────────────────────
  String get compareTitle =>
      _t('Side-by-side Compare', 'ጎን ለጎን ያወዳድሩ', 'Is-bar-bar dhigga');
  String get compareFeature => _t('Feature', 'ባህሪ', 'Astaamaha');
  String get comparePrice => _t('Price', 'ዋጋ', 'Qiimaha');
  String get compareLocation => _t('Location', 'ቦታ', 'Goobta');
  String get compareCondition => _t('Condition', 'ሁኔታ', 'Xaalad');
  String get compareVerified => _t('Verified', 'የተረጋገጠ', 'Xaqiijiyey');
  String get compareYes => _t('Yes ✓', 'አዎ ✓', 'Haa ✓');
  String get compareNo => _t('No', 'አይደለም', 'Maya');

  // ── Post Wizard ─────────────────────────────────────────────────────────────
  String get wizardTitle =>
      _t('Post a Listing', 'ዝርዝር ያስቀምጡ', 'Ku daji xayaysiis');
  String get wizardStep1 => _t('Choose Category', 'ምድብ ይምረጡ', 'Dooro qeybta');
  String get wizardStep2 => _t('Your Info', 'የእርስዎ መረጃ', 'Macluumaadkaaga');
  String get wizardStep3 => _t('Details', 'ዝርዝሮች', 'Faahfaahinta');
  String get wizardStep4 =>
      _t('Review & Submit', 'ይገምግሙ እና ያስቀምጡ', 'Dib u eeg oo gudbi');
  String get wizardNext => _t('Next', 'ቀጣይ', 'Xiga');
  String get wizardBack => _t('Back', 'ተመለስ', 'Dib u noqo');
  String get wizardSubmit =>
      _t('Submit Listing', 'ዝርዝር ያስቀምጡ', 'Gudbi xayaysiiska');
  String get wizardPhotoAttach => _t('Attach Photo', 'ፎቶ ያያይዙ', 'Ku dar sawir');
  String get wizardPhotoAttached =>
      _t('Photo attached ✓', 'ፎቶ ተያይዟል ✓', 'Sawirka la daray ✓');
  String get wizardTitleLabel => _t('Title', 'ርዕስ', 'Cinwaan');
  String get wizardPriceLabel => _t('Price', 'ዋጋ', 'Qiimaha');
  String get wizardDescLabel => _t('Description', 'መግለጫ', 'Sharaxaad');
  String get wizardLocationLabel => _t('Location', 'ቦታ', 'Goobta');
  String get wizardAddressLabel =>
      _t('Physical Address', 'አካላዊ አድራሻ', 'Cinwaanka jireed');
  String get wizardPhotoMock => _t(
    'Mock photo attached successfully!',
    'ሞክ ፎቶ ተያይዟል!',
    'Sawirada si guul leh ayaa loo daray!',
  );
  String get wizardPosted => _t(
    'Your listing has been posted!',
    'ዝርዝርዎ ተለጠፈ!',
    'Xayaysiiskaagu waa la daabacay!',
  );

  // ── Messages Screen ─────────────────────────────────────────────────────────
  String get messagesTitle => _t('Messages', 'መልዕክቶች', 'Farriimaha');
  String get messagesEmpty => _t(
    'No active chats yet',
    'ምንም ንቁ ቻት የለም',
    'Ma jiraan sheekooyin firfircoon',
  );

  // ── Active Chat Screen ──────────────────────────────────────────────────────
  String get chatInputHint =>
      _t('Type a message...', 'መልዕክት ይጻፉ...', 'Qor fariin...');
  String get chatSend => _t('Send', 'ላክ', 'Dir');
  String get chatReplied => _t(
    "Sounds good, what do you think?",
    'ደህና ነው, ምን ያስቡ ነበር?',
    'Waa hagaagsan tahay, maxaad u maleynaysaa?',
  );

  // ── Settings / Profile Screen ───────────────────────────────────────────────
  String get settingsTitle => _t('Settings', 'ቅንብሮች', 'Dejinta');
  String get settingsProfile =>
      _t('Edit Profile', 'መገለጫ ያርትዑ', 'Wax ka beddel xogta');
  String get settingsNotifications =>
      _t('Notifications', 'ማሳወቂያዎች', 'Ogeysiisyada');
  String get settingsPushEnabled =>
      _t('Push Notifications', 'ፑሽ ማሳወቂያዎች', 'Ogeysiisyada push');
  String get settingsNewMessages =>
      _t('New Messages', 'አዲስ መልዕክቶች', 'Farriimaha cusub');
  String get settingsPriceAlerts =>
      _t('Price Alerts', 'የዋጋ ማስጠንቀቂያዎች', 'Digniin qiimeed');
  String get settingsTheme => _t('Theme', 'ገጽታ', 'Muuqaalka');
  String get settingsDarkMode => _t('Dark Mode', 'ጨለማ ሁነታ', 'Habeennimo');
  String get settingsLanguage => _t('Language', 'ቋንቋ', 'Luqadda');
  String get settingsSave =>
      _t('Save Changes', 'ለውጦችን አስቀምጥ', 'Keydi isbeddelada');
  String get settingsSaved => _t('Saved!', 'ተቀምጧል!', 'La kaydiyey!');
  String get settingsNameLabel => _t('Full Name', 'ሙሉ ስም', 'Magaca buuxa');
  String get settingsPhoneLabel => _t('Phone', 'ስልክ', 'Telefoonka');
  String get settingsCityLabel => _t('City', 'ከተማ', 'Magaalada');
}
