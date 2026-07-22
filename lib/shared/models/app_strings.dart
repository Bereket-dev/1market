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
  String get commonCancel => _t('Cancel', 'ሰርዝ', 'Jooji');

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
  String get navSave => _t('Save', 'አስቀምጥ', 'Keydi');
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

  // ── Recommendations ─────────────────────────────────────────────────────────
  String get homeRecommendedTitle =>
      _t('Recommended for You', 'ለእርስዎ የተዘጋጀ', 'Loogu talagalay adiga');
  String get homeRecommendedEmpty => _t(
    'No recommendations yet — explore a category to get started.',
    'ምንም ምክረ-ሃሳብ የለም — ለመጀመር ምድብ ያስሱ።',
    'Wali ma jiraan talooyinkii — sahami qaybta si aad u bilowdo.',
  );
  String get detailSimilarTitle =>
      _t('Similar to This', 'ተመሳሳይ', 'La mid ah kan');
  String get detailSimilarEmpty => _t(
    'No similar items found yet.',
    'ተመሳሳይ ዕቃዎች አልተገኙም።',
    'Wax la mid ah lama helin.',
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

  /// "Browse Listings" button in empty state.
  String get savedBrowse => _t('Browse Listings', 'ዝርዝሮችን ያስሱ', 'Raadi xayaysiisyada');
  /// Shown when category filter has no results.
  String get savedFilterEmpty => _t(
    'No saved items in this category',
    'በዚህ ምድብ ምንም የተቀመጠ የለም',
    'Kuma jiraan walxo la kaydiyey qaybtan',
  );

  // ── Saved Screen category chip labels ───────────────────────────────────────
  String get savedCatAll    => _t('All',    'ሁሉም',    'Dhammaan');
  String get savedCatCars   => _t('Cars',   'መኪናዎች',  'Gawaari');
  String get savedCatHouses => _t('Houses', 'ቤቶች',    'Guryo');
  String get savedCatLand   => _t('Land',   'መሬት',    'Dhul');
  String get savedCatSkills => _t('Skills', 'ክህሎቶች',  'Xirfadaha');

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

  // ── Compare row labels ───────────────────────────────────────────────────────
  String get compareRowPrice    => _t('Price',    'ዋጋ',      'Qiimaha');
  String get compareRowLocation => _t('Location', 'ቦታ',      'Goobta');
  String get compareRowStatus   => _t('Status',   'ሁኔታ',     'Xaalad');
  String get compareRowSpec1    => _t('Spec 1',   'ዝርዝር 1', 'Sifo 1');
  String get compareRowSpec2    => _t('Spec 2',   'ዝርዝር 2', 'Sifo 2');
  String get compareRowSpec3    => _t('Spec 3',   'ዝርዝር 3', 'Sifo 3');
  String get compareRowSeller   => _t('Seller',   'ሻጭ',      'Iibiyaha');
  /// Fallback when a spec is absent.
  String get compareNa => _t('N/A', 'ምንም', 'Ma jiro');

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
  String get wizardCarsTitleHint => _t(
    'e.g. 2022 Toyota Land Cruiser Prado',
    'ለምሳሌ 2022 Toyota Land Cruiser Prado',
    'tusaale 2022 Toyota Land Cruiser Prado',
  );
  String get wizardCarsPriceLabel => _t('Asking Price', 'የመጠየቅ ዋጋ', 'Qiimaha la codsaday');
  String get wizardCarsPriceHint => _t(
    'e.g. ETB 2,800,000',
    'ለምሳሌ ETB 2,800,000',
    'tusaale ETB 2,800,000',
  );
  String get wizardHousesTitleHint => _t(
    'e.g. Modern 4-Bedroom Villa in Kebele 04',
    'ለምሳሌ 4-መኝታ ቤት በኬቤሌ 04',
    'tusaale guri 4-qol ah oo ku yaal Kebele 04',
  );
  String get wizardHousesPriceLabel => _t('Price / Rent', 'ዋጋ / ኪራይ', 'Qiimaha / Kire');
  String get wizardHousesPriceHint => _t(
    'e.g. ETB 145,000 /mo',
    'ለምሳሌ ETB 145,000 /ወር',
    'tusaale ETB 145,000 /bil',
  );
  String get wizardLandTitleHint => _t(
    'e.g. Residential Plot in Kebele 02',
    'ለምሳሌ በኬቤሌ 02 የመኖሪያ መሬት',
    'tusaale Dhul guri oo ku yaal Kebele 02',
  );
  String get wizardLandPriceLabel => _t('Asking Price', 'የመጠየቅ ዋጋ', 'Qiimaha la codsaday');
  String get wizardLandPriceHint => _t(
    'e.g. ETB 4,200,000',
    'ለምሳሌ ETB 4,200,000',
    'tusaale ETB 4,200,000',
  );
  String get wizardSkillsTitleHint => _t(
    'e.g. Hodan Ahmed – Professional Housekeeper',
    'ለምሳሌ ሆዳን አህመድ – ባለሙያ ቤት አያያዥ',
    'tusaale Hodan Ahmed – Nadiifiyihii xirfadlaha',
  );
  String get wizardSkillsPriceLabel => _t('Rate / Fee', 'ክፍያ / ክፍል', 'Kharash / Khidmad');
  String get wizardSkillsPriceHint => _t(
    'e.g. ETB 45 /hr or unlock for ETB 30',
    'ለምሳሌ ETB 45 /ሰዓት ወይም ETB 30 ለመክፈት',
    'tusaale ETB 45 /saac ama furitaanka ETB 30',
  );
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
  String get messagesNoResults => _t(
    'No chats match your search',
    'ምንም ተዛማጅ ቻት የለም',
    'Sheeko la midnaysan ma jirto',
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

  // ── Location Permission Screen ───────────────────────────────────────────────
  String get locationTitle =>
      _t('Location helps us show nearby listings', 'አቅራቢያዎን ለማሳወቅ ቦታዎን ይጠቀማሉ', 'Goobta waxay na caawisaa inaan kuu tusinno xayaysiisyada agagaarka');
  String get locationBody => _t(
    'We use your location to show you nearby listings and services. You can continue even if you deny permission.',
    'ቦታዎን ለአቅራቢያ ዝርዝሮች እና አገልግሎቶች ለማሳወቅ እንጠቀማለን። ፈቃድ ቢከለከሉም መቀጠል ይችላሉ።',
    'Goobta waxaan u isticmaalnaa in aan kuu tusno xayaysiisyada iyo adeegyada agagaarka. Waxaad sii wadi kartaa xitaa haddaad diiddo.',
  );
  String get locationRequesting => _t('Requesting...', 'በጥያቄ ላይ...', 'Codsanaya...');
  String get locationContinue => _t('Continue', 'ቀጥል', 'Sii wad');
  String get locationSkip => _t('Skip for now', 'አሁን ዝለል', 'Hadda ka bood');

  // ── Goal Selection Screen ────────────────────────────────────────────────────
  String get goalTitle => _t('What are you here to do?', 'ለምን መጡ?', 'Maxaad halkan u timid?');
  String get goalSubtitle => _t(
    'Choose one goal to get started. You can still explore all features later.',
    'ለመጀመር አንድ ግብ ይምረጡ። ሁሉንም ባህሪያት ቆይተው ማሰስ ይችላሉ።',
    'Dooro hal yool si aad u bilowdo. Waxaad baadi-goob ku samayn kartaa dhammaan astaamaha dambe.',
  );
  String get goalPostListing => _t('Post a listing', 'ማስታወቂያ ለጥፍ', 'Ku daji xayaysiis');
  String get goalHireSkilled => _t('Hire a skilled person', 'ብቃት ያለው ቅጠር', 'Shaqaale xirfadleh kiri');
  String get goalFindJob => _t('Find a job', 'ሥራ ፈልግ', 'Shaqo raadi');
  String get goalFindCar => _t('Find a car', 'መኪና ፈልግ', 'Gaari raadi');
  String get goalRentHome => _t('Rent a home', 'ቤት ተከራይ', 'Guri kiri');
  String get goalBuyLand => _t('Buy land', 'መሬት ግዛ', 'Dhul iibso');
  String get goalContinue => _t('Continue', 'ቀጥል', 'Sii wad');

  // ── Verification Prompt Screen ───────────────────────────────────────────────
  String get verifyTitle =>
      _t('Verify your account with Fayda', 'መለያዎን በፋይዳ ያረጋግጡ', 'Xaqiiji xisaabtaada Fayda');
  String get verifyBody => _t(
    'Verified accounts build trust. You can verify now, or skip and continue using the app immediately.',
    'የተረጋገጡ መለያዎች እምነት ይፈጥራሉ። አሁን ማረጋገጥ ወይም ዝለው ወዲያውኑ መጠቀም ይችላሉ።',
    'Xisaabaha la xaqiijiyey waxay dhisaan kalsoonida. Waxaad xaqiijin kartaa hadda, ama ka bood oo isla markiiba isticmaal.',
  );
  String get verifyNow => _t('Verify now', 'አሁን ያረጋግጡ', 'Hadda xaqiiji');
  String get verifySkip => _t('Skip for now', 'አሁን ዝለል', 'Hadda ka bood');

  // ── App init / loading screen ────────────────────────────────────────────────
  String get initLoading => _t('Loading…', 'በመጫን ላይ…', 'Waa la soo rarayaa…');
  String get initRetry => _t('Retry', 'እንደገና ይሞክሩ', 'Isku day mar kale');

  // ── Category Picker Sheet ────────────────────────────────────────────────────
  String get pickerTitle => _t('What would you like to post?', 'ምን ማስታወቂያ ይለጥፋሉ?', 'Maxaad rabta inaad ku dajiso?');
  String get pickerCancel => _t('Cancel', 'ሰርዝ', 'Jooji');

  // ── Recent Listing Card ──────────────────────────────────────────────────────
  String get cardTalkToSeller => _t('Talk to Seller', 'ሻጩን ያናግሩ', 'Iibiyaha la hadal');
  String get cardCallOwner => _t('Call Owner', 'ባለቤቱን ይደውሉ', 'Milkiilaha u wac');
  String get cardKmAway => _t('2.4 km away', '2.4 ኪ.ሜ ርቀት', '2.4 km fog');

  // ── Post Wizard ─────────────────────────────────────────────────────────────
  String get wizardStepOf =>
      _t('Step {step} of 4', 'ደረጃ {step} ከ 4', 'Tallaabo {step} oo ah 4');
  String get wizardStartPosting => _t('Start posting', 'ማስታወቂያ ጀምር', 'Bilow dajinta');
  String get wizardSelectType =>
      _t("Select what type of ad you'd like to list in Jigjiga.", "በጂግጂጋ ምን ዓይነት ማስታወቂያ ማስቀመጥ ይፈልጋሉ?", "Xulo nooca xayaysiiska aad rabto inaad ku dajiso Jigjiga.");
  String get wizardCatSkillsTitle => _t('Professional Service', 'ሙያዊ አገልግሎት', 'Adeeg xirfadeed');
  String get wizardCatSkillsDesc => _t('Post a skilled worker profile.', 'የብቃት ሰራተኛ መገለጫ ያስቀምጡ።', 'Ku daji xogta shaqaalaha xirfadlaha ah.');
  String get wizardCatCarsTitle => _t('Vehicles / Cars', 'ተሽከርካሪዎች / መኪናዎች', 'Baabuurta / Gawaari');
  String get wizardCatCarsDesc => _t('Sell or rent cars, motorbikes, machinery.', 'መኪናዎች፣ ሞተርሳይክሎች እና ማሽነሪ ይሸጡ ወይም ያከራዩ።', 'Iib ama kiri gawaarida, mootorada, mishiinnada.');
  String get wizardCatHousesTitle => _t('Real Estate / Houses', 'ሪል ስቴት / ቤቶች', 'Guriyaha / Dhismaha');
  String get wizardCatHousesDesc => _t('List houses, apartments, villas.', 'ቤቶች፣ አፓርትማዎች እና ቪላዎች ያስቀምጡ።', 'Ku daji guryaha, dabaqyada, villada.');
  String get wizardCatLandTitle => _t('Land / Plots', 'መሬት / ቦታዎች', 'Dhulka / Goobaha');
  String get wizardCatLandDesc => _t('Sell or lease farming fields or commercial sites.', 'የእርሻ ቦታዎችን ወይም የንግድ ቦታዎችን ይሸጡ ወይም ያከራዩ።', 'Iib ama kiri beerta beeraha ama goobaha ganacsiga.');
  String get wizardDetailsTitle => _t('Details & Title', 'ዝርዝሮች እና ርዕስ', 'Faahfaahin & Cinwaan');
  String get wizardDetailsSubtitle =>
      _t('Describe your listing with a clear title and pricing.', 'ዝርዝርዎን ግልጽ ርዕስ እና ዋጋ ያስቀምጡ።', 'Si cad uga sheeg xayaysiiskaaga cinwaan iyo qiimaha.');
  String get wizardTitleRequired => _t('Title is required', 'ርዕስ ያስፈልጋል', 'Cinwaanka waa lagama maarmaan');
  String get wizardPriceRequired => _t('Price is required', 'ዋጋ ያስፈልጋል', 'Qiimaha waa lagama maarmaan');
  String get wizardLocationZone => _t('Location Zone', 'የቦታ ዞን', 'Aagga goobta');
  String get wizardSpecsTitle => _t('Specifications', 'ዝርዝር ባህሪዎች', 'Sifooyinka');
  String get wizardSpecsSubtitle =>
      _t('Provide specs for your listing.', 'ለዝርዝርዎ ዝርዝር ባህሪዎች ያስቀምጡ።', 'Ku dar sifooyinka xayaysiiskaaga.');
  String get wizardFinalizeTitle => _t('Finalize Post', 'ማስታወቂያ ጨርስ', 'Dhamaystir dajinta');
  String get wizardFinalizeSubtitle =>
      _t('Write a detailed description and attach media.', 'ዝርዝር መግለጫ ጻፉ እና ሚዲያ ያያይዙ።', 'Qor sharaxaad faahfaahsan oo ku dar warbaahinta.');
  String get wizardDescriptionLabel => _t('Description', 'መግለጫ', 'Sharaxaad');
  String get wizardDescriptionHint =>
      _t('Briefly explain condition, location merits…', 'ሁኔታ እና የቦታ ጥቅሞች ይግለጹ…', 'Si gaaban u sharax xaalada iyo faa\'iidooyinka goobta…');
  String get wizardAttachMedia => _t('Attach media files', 'ሚዲያ ፋይሎች ያያይዙ', 'Ku dar faylalka warbaahinta');
  String get wizardAttached => _t('1 file attached', '1 ፋይል ተያይዟል', '1 fayl ayaa la daray');
  String get wizardMediaHint => _t('JPG, PNG, MP4 up to 50MB', 'JPG, PNG, MP4 እስከ 50MB', 'JPG, PNG, MP4 ilaa 50MB');

  // ── Sync Status Badge ────────────────────────────────────────────────────────
  String get syncLocal => _t('Saved on this device only', 'በዚህ መሣሪያ ብቻ ተቀምጧል', 'Kaliya ku kaydsan qalabkan');
  String get syncPending => _t('Sending', 'በመላክ ላይ', 'Waa la diraya');
  String get syncSynced => _t('Synced', 'ተመሳስሏል', 'La waafajiyey');
  String get syncFailed => _t('Retry', 'እንደገና ይሞክሩ', 'Isku day mar kale');

  // ── Messages Screen ──────────────────────────────────────────────────────────
  String get messagesRefreshed => _t('Chat list updated', 'የቻት ዝርዝር ታደሰ', 'Liiska sheekada waa la cusboonaysiiyey');
  String get messagesSearchHint => _t('Search messages...', 'መልዕክቶች ፈልግ...', 'Raadi farriimaha...');
  String get messagesFilterAll => _t('All', 'ሁሉም', 'Dhammaan');
  String get messagesFilterUnread => _t('Unread', 'ያልተነበቡ', 'aan la aqoon');
  String get messagesFilterArchived => _t('Archived', 'የተቀዱ', 'La kaydiyey');
  String get messagesJustNow => _t('Just now', 'አሁን ነው', 'Hadda ayuu ahaa');
  String get messagesNoMessages => _t('No messages yet', 'ምንም መልዕክት የለም', 'Wali farriin ma jirto');

  // ── Active Chat Screen ───────────────────────────────────────────────────────
  String get chatSharePhone => _t('Share phone number', 'ስልክ ቁጥር ያጋሩ', 'La wadaag lambarka telefoonka');
  String get chatPhoneShared => _t('Phone number shared with this contact.', 'ስልክ ቁጥር ከዚህ እውቂያ ጋር ተጋርቷል።', 'Lambarka telefoonku wuxuu la wadaagay xiriirkan.');

  // ── Profile Screen ───────────────────────────────────────────────────────────
  String get profileReviews => _t('Reviews', 'ግምገማዎች', 'Dib-u-eegisyada');
  String get profileJobsDone => _t('Jobs Done', 'የተጠናቀቁ ሥራዎች', 'Shaqooyinka la dhammeeyey');
  String get profileResponseRate => _t('Response Rate', 'የምላሽ ደረጃ', 'Heerka jawaabta');
  String get profileTabServices => _t('Services', 'አገልግሎቶች', 'Adeegyada');
  String get profileTabAbout => _t('About', 'ስለ', 'Ku saabsan');
  String get profileTabReviews => _t('Reviews', 'ግምገማዎች', 'Dib-u-eegisyada');
  String get profileNoServices => _t('No services posted yet', 'ምንም አገልግሎቶች አልተለጠፉም', 'Wali adeeg la ma dajin');
  String get profileNoServicesSub => _t(
    'Tap the central + button to publish your professional service ad instantly.',
    'ወዲያውኑ ሙያዊ አገልግሎት ማስታወቂያ ለማስቀመጥ መሃሉን + ይጫኑ።',
    'Taabo badhanka dhexe + si aad isla markiiba u daabacdo xayaysiiskaaga adeegga xirfadeed.',
  );
  String get profileProfSummary => _t('Professional Summary', 'ሙያዊ ማጠቃለያ', 'Kooban xirfadeed');
  String get profileEscrowTitle => _t('Escrow Safety Vault', 'የኤስክሮ ደህንነት ካቢኔ', 'Khisaanada Ammaan ee Escrow');
  String get profileEscrowActive => _t('Active', 'ንቁ', 'Firfircoon');
  String get profileEscrowWallet => _t('Secured Escrow Wallet', 'የተጠበቀ የኤስክሮ ዋሌት', 'Boorso Escrow oo Ammaan ah');
  String get profileSpecialties => _t('Verified Specialties', 'የተረጋገጡ ልዩ ሙያዎች', 'Takhasuusyada la Xaqiijiyey');
  String get servicesTitle => _t('Services', 'አገልግሎቶች', 'Adeegyada');
  String get servicesAddNew => _t('Add new service', 'አዲስ አገልግሎት ያክሉ', 'Ku dar adeeg cusub');
  String get servicesAvailabilityLabel => _t('Availability', 'የአገልግሎት እቃ', 'Helitaan');
  String get servicesAvailable => _t('Available', 'ነው', 'La heli karo');
  String get servicesUnavailable => _t('Unavailable', 'አይገኝም', 'Aan la heli karin');
  String get servicesToggleAvailability => _t('Toggle', 'ቅርጽ', 'Beddel');
  String get servicesCreateTitle => _t('Create Service', 'አገልግሎት ይፍጠሩ', 'Abuur Adeeg');
  String get servicesEditTitle => _t('Edit Service', 'አገልግሎት ያርትዑ', 'Wax ka beddel Adeeg');
  String get servicesTitleLabel => _t('Title', 'ርዕስ', 'Cinwaan');
  String get servicesCategoryLabel => _t('Category', 'ምድብ', 'Qayb');
  String get servicesCoverDescriptionLabel => _t('Cover summary', 'ክብ ማጠቃለያ', 'Kooban');
  String get servicesDescriptionLabel => _t('Description', 'መግለጫ', 'Sharaxaad');
  String get servicesYearsOfExperienceLabel => _t('Years of Experience', 'የልምድ ዓመታት', 'Sano khibrad ah');
  String get servicesPriceRangeLabel => _t('Price range', 'የዋጋ ክልል', 'Qiimaha');
  String get servicesLocationLabel => _t('Location', 'ቦታ', 'Goobta');
  String get servicesUploadCv => _t('Upload CV', 'የስብስ መጽሐፍ ያስገቡ', 'Soo rar CV');
  String get servicesChangeCv => _t('Change CV', 'የስብስ መጽሐፍ ይቀይሩ', 'Beddel CV');
  String get servicesCurrentCv => _t('Current CV', 'የአሁኑ ስብስ', 'CV-ga Hadda');
  String get servicesSaveButton => _t('Save service', 'አገልግሎቱን ይያዙ', 'Keydi Adeegga');
  String get servicesTitleRequired => _t('Service title is required', 'የአገልግሎት ርዕስ ያስፈልጋል', 'Cinwaanka adeegga waa lagama maarmaan');
  String get servicesTitleHint => _t('e.g. Professional Plumber', 'ለምሳሌ ባለሙያ ቧምቧ ቴክኒሻን', 'tusaale Farsamayste Biyo-gelin xirfadeed');
  String get servicesCategoryHint => _t('e.g. Plumbing, Housekeeping', 'ለምሳሌ ቧምቧ, የቤት ስራ', 'tusaale Biyo-gelin, Nadiifinta');
  String get servicesCoverDescriptionHint => _t('Short summary shown on search cards (max 120 chars)', 'ጥቂት ማጠቃለያ (ከ120 ቁምፊ በታች)', 'Koobid gaaban (ugu badan 120 xaraf)');
  String get servicesDescriptionHint => _t('Full description of your skills and experience', 'ሙሉ የክህሎቶ እና ልምድዎ ዝርዝር', 'Sharaxaad buuxda oo ku saabsan xirfadahaaga');
  String get servicesYearsOfExperienceHint => _t('e.g. 3', 'ለምሳሌ 3', 'tusaale 3');
  String get servicesPriceRangeHint => _t('e.g. ETB 500–1500 / day', 'ለምሳሌ ETB 500–1500 / ቀን', 'tusaale ETB 500–1500 / maalin');
  String get servicesLocationHint => _t('e.g. Kebele 05, Jigjiga', 'ለምሳሌ ቀበሌ 05, ጂጂጋ', 'tusaale Kebele 05, Jigjiga');
  String get servicesDeleteButton => _t('Delete service', 'አገልግሎቱን ሰርዝ', 'Tirtir adeegga');
  String get servicesDeleteConfirm => _t('Delete this service? This cannot be undone.', 'ይህን አገልግሎት ይሰርዙ? ሊቀለበስ አይችልም።', 'Tirtir adeeggan? Dib loo celin karo ma.');
  String get servicesDeleteCancel => _t('Cancel', 'ሰርዝ', 'Jooji');
  String get servicesDeleteConfirmButton => _t('Delete', 'ሰርዝ', 'Tirtir');

  // ── Service browse ───────────────────────────────────────────────────────────
  String get servicesBrowseTitle => _t('Find Services', 'አገልግሎቶች ፈልግ', 'Hel Adeegyada');
  String get servicesBrowseSearchHint => _t('Search by title or category…', 'በርዕስ ወይም ምድብ ፈልግ…', 'Raadi cinwaan ama qayb…');
  String get servicesBrowseFilterAll => _t('All', 'ሁሉም', 'Dhammaan');
  String get servicesBrowseNoResults => _t('No available services found', 'ምንም ዝግጁ አገልግሎቶች አልተገኙም', 'Adeeg la heli karo lama helin');
  String get servicesBrowseAvailableOnly => _t('Showing available services only', 'ዝግጁ አገልግሎቶች ብቻ ይታያሉ', 'Adeegyada la heli karo oo kaliya');
  String get servicesBrowseApplyAction => _t('View full profile', 'ሙሉ መገለጫ ይመልከቱ', 'Arag xogta buuxda');

  // ── Service detail ───────────────────────────────────────────────────────────
  String get servicesDetailTitle => _t('Service Details', 'የአገልግሎት ዝርዝሮች', 'Faahfaahinta Adeegga');
  String get servicesDetailCategory => _t('Category', 'ምድብ', 'Qayb');
  String get servicesDetailExperience => _t('Experience', 'ልምድ', 'Khibrad');
  String get servicesDetailExperienceYears => _t('{n} year(s)', '{n} ዓመት', '{n} sanno');
  String get servicesDetailPriceRange => _t('Price Range', 'የዋጋ ክልል', 'Xadka qiimaha');
  String get servicesDetailLocation => _t('Location', 'ቦታ', 'Goobta');
  String get servicesDetailCv => _t('CV / Document', 'ስርዝ / ሰነድ', 'CV / Dukumenti');
  String get servicesDetailCvView => _t('View CV', 'ስርዝ ይመልከቱ', 'Arag CV');
  String get servicesDetailNoCv => _t('No CV uploaded', 'ምንም ስርዝ አልተጫነም', 'CV lama soo rarin');
  String get servicesDetailApplyNote => _t(
    'To apply or hire, use the "Apply to" feature in Phase C Part 2.',
    'ለማዘዝ ወይም ለቅጠር, "Apply to" ባህሪን ይጠቀሙ.',
    'Si aad u codsato ama u kiraynayso, isticmaal "Apply to" Qaybta C Qaybta 2.',
  );

  // ── Reviews ──────────────────────────────────────────────────────────────────
  String get reviewsTitle => _t('Reviews', 'ግምገማዎች', 'Dib-u-eegisyada');
  String get reviewsEmpty => _t('No reviews yet', 'ምንም ግምገማ የለም', 'Wali dib-u-eegis ma jirto');
  String get reviewsSubmitTitle => _t('Write a review', 'ግምገማ ጻፍ', 'Qor dib-u-eegis');
  String get reviewsRatingLabel => _t('Rating', 'ደረጃ', 'Derejayn');
  String get reviewsCommentLabel => _t('Comment', 'አስተያየት', 'Faallo');
  String get reviewsCommentHint => _t('Describe your experience…', 'ልምድዎን ይግለጹ…', 'Ka sheeg khibradaadii…');
  String get reviewsSubmitButton => _t('Submit review', 'ግምገማ አስገባ', 'Gudbi dib-u-eegiska');
  String get reviewsSubmitting => _t('Submitting…', 'በማስገባ ላይ…', 'Waa la gudbinayaa…');
  String get reviewsThankYou => _t('Review submitted!', 'ግምገማ ቀረበ!', 'Dib-u-eegiska waa la gudbiyey!');
  String get reviewsGatingNote => _t(
    'TODO (Phase C Part 2): Reviews should be gated on a completed engagement. '
    'For now, any authenticated user can leave a review.',
    'TODO (Phase C Part 2): ግምገማዎች ሙሉ ሥርዓት ያለውን ስምምነት ማረጋገጥ ያስፈልጋቸዋል.',
    'TODO (Phase C Part 2): Dib-u-eegisyada waa in lagu xidaa hawl dhamaatay.',
  );
  String get reviewsAnonymousHint => _t(
    'Reviews are linked to completed job engagements in Part 2.',
    'ግምገማዎች ከጠናቀቀ ስምምነት ጋር ይያያዛሉ።',
    'Dib-u-eegisyadu waxay la xidnaanayaan hawlaha dhamaatay.',
  );
  // Relative time labels for review timestamps
  String reviewsTimeAgoYears(int n) => _t(
        '$n year(s) ago',
        'ከ$n ዓመት(ዎች) በፊት',
        '$n sanadood(dood) kahor',
      );
  String reviewsTimeAgoMonths(int n) => _t(
        '$n month(s) ago',
        'ከ$n ወር(ዎች) በፊት',
        '$n bil(bil) kahor',
      );
  String reviewsTimeAgoDays(int n) => _t(
        '$n day(s) ago',
        'ከ$n ቀን(ዎች) በፊት',
        '$n maalin(maalin) kahor',
      );
  String reviewsTimeAgoHours(int n) => _t(
        '$n hour(s) ago',
        'ከ$n ሰዓት(ዎች) በፊት',
        '$n saacadood(ood) kahor',
      );
  String get reviewsTimeAgoJustNow => _t('Just now', 'ልክ አሁን', 'Hadda ayuu ahaa');
  String get reviewsFallbackUserName => _t('User', 'ተጠቃሚ', 'Isticmaale');
  String get reviewsCommentRequired => _t(
        'Comment is required',
        'አስተያየት ያስፈልጋል',
        'Faallada waa lagama maarmaan',
      );

  // ── CV upload ────────────────────────────────────────────────────────────────
  String get servicesCvTooLarge => _t(
    'File too large — maximum 5 MB allowed',
    'ፋይሉ ትልቅ ነው — ከፍተኛ 5 MB ተፈቅዷል',
    'Faylka waа waa weyn yahay — ugu badnaan 5 MB ayaa oggolaansan',
  );
  String get servicesCvPending => _t(
    'CV queued — will upload when online',
    'CV ተሰልፏል — ሲገናኙ ይጫናል',
    'CV waa la surayaa — marka internet la helo ayaa la soo raraa',
  );

  // ── Hiring Posts ─────────────────────────────────────────────────────────────
  String get hiringTitle => _t('Hiring Posts', 'የቅጥር ልጥፎች', 'Xashiisyada Shaqada');
  String get hiringAddNew => _t('Post a job', 'ሥራ ለጥፍ', 'Xasaab shaqo');
  String get hiringEditTitle => _t('Edit job post', 'ሥራ ልጥፍ አርትዕ', 'Wax ka beddel xasaabka');
  String get hiringCreateTitle => _t('Post a job', 'ሥራ ለጥፍ', 'Xasaab shaqo');
  String get hiringTitleLabel => _t('Job title', 'የሥራ ርዕስ', 'Cinwaanka shaqada');
  String get hiringTitleHint =>
      _t('e.g. Looking for a plumber', 'ፒፓ ሰሪ እፈልጋለሁ', 'Tusaale: Waxaan raadinayaa lacagta biyo');
  String get hiringTitleRequired =>
      _t('Job title is required', 'የሥራ ርዕስ ያስፈልጋል', 'Cinwaanka shaqada waa lagama maarmaan');
  String get hiringDescriptionLabel =>
      _t('Description', 'መግለጫ', 'Sharaxaad');
  String get hiringDescriptionHint =>
      _t('Describe what you need…', 'የሚፈልጉትን ይግለጹ…', 'Ka sheeg waxa aad u baahan tahay…');
  String get hiringCategoryLabel => _t('Category', 'ምድብ', 'Qaybta');
  String get hiringCategoryHint =>
      _t('e.g. Plumbing, Cleaning, Tutoring', 'ፒፓ፣ ጽዳት፣ ትምህርት', 'Tusaale: Biyo, nadiifin');
  String get hiringLocationLabel => _t('Location', 'ቦታ', 'Goobta');
  String get hiringLocationHint =>
      _t('e.g. Kebele 04, Jigjiga', 'ቀበሌ 04፣ ጅጅጋ', 'Tusaale: Kebele 04, Jigjiga');
  String get hiringPriceRangeLabel =>
      _t('Budget (ETB)', 'በጀት (ብር)', 'Miisaaniyada (ETB)');
  String get hiringPriceRangeHint =>
      _t('e.g. 500–2000 ETB', '500–2000 ብር', 'Tusaale: 500–2000 ETB');
  String get hiringStatusLabel => _t('Status', 'ሁኔታ', 'Xaaladda');
  String get hiringStatusOpen => _t('Open', 'ክፍት', 'Furan');
  String get hiringStatusClosed => _t('Closed', 'ዝግ', 'Xiran');
  String get hiringToggleStatus => _t('Toggle open/closed', 'ክፍት/ዝግ ቀይር', 'Bedel furan/xiran');
  String get hiringSaveButton => _t('Save post', 'ልጥፍ አስቀምጥ', 'Keydi xasaabka');
  String get hiringDeleteButton =>
      _t('Delete post', 'ልጥፍ ሰርዝ', 'Tirtir xasaabka');
  String get hiringDeleteConfirm =>
      _t('Delete this hiring post?', 'ይህን ልጥፍ ይሰርዙ?', 'Ma tirtirtaa xasaabkan?');
  String get hiringDeleteCancel => _t('Cancel', 'ሰርዝ', 'Jooji');
  String get hiringDeleteConfirmButton =>
      _t('Delete', 'ሰርዝ', 'Tirtir');
  String get hiringNoPostsYet =>
      _t('No hiring posts yet', 'እስካሁን ምንም ልጥፍ የለም', 'Wali xasaab la\'ahan');
  String get hiringNoPostsSub =>
      _t('Tap "Post a job" to find skilled people', '"ሥራ ለጥፍ" ጠቅ ያድርጉ', '"Xasaab shaqo" taabo');
  String get hiringApplicantsCount =>
      _t('applicants', 'ተወዳዳሪዎች', 'codsadayaasha');
  // Plural form: 'n applicants' — {n} will be replaced.
  String hiringApplicantsBadge(int n) =>
      _t('$n applicant(s)', '$n ተወዳዳሪ(ዎች)', '$n codsade(yaal)');
  String get hiringApplicantListTitle =>
      _t('Applicants', 'ተወዳዳሪዎች', 'Codsadayaasha');
  String get hiringNoApplicantsYet =>
      _t('No applicants yet', 'እስካሁን ምንም ተወዳዳሪ የለም', 'Wali codsade la\'ahan');

  // ── Application status labels ─────────────────────────────────────────────
  String get applicationStatusSubmitted =>
      _t('Submitted', 'ቀርቧል', 'La gudbiyey');
  String get applicationStatusReviewed =>
      _t('Reviewed', 'ታይቷል', 'La xilsaaray');
  String get applicationStatusAccepted =>
      _t('Accepted', 'ተቀብሏል', 'La aqbalay');
  String get applicationStatusRejected =>
      _t('Rejected', 'ተከልክሏል', 'La diidey');
  String applicationStatusLabel(String status) {
    return switch (status) {
      'reviewed' => applicationStatusReviewed,
      'accepted' => applicationStatusAccepted,
      'rejected' => applicationStatusRejected,
      _ => applicationStatusSubmitted,
    };
  }

  // ── Apply flow ─────────────────────────────────────────────────────────────
  String get hiringBrowseTitle =>
      _t('Open job postings', 'ክፍት ሥራ ልጥፎች', 'Xashiisyada shaqada furan');
  String get hiringBrowseSearchHint =>
      _t('Search jobs…', 'ሥራ ፈልግ…', 'Raadi shaqo…');
  String get hiringBrowseFilterAll => _t('All', 'ሁሉም', 'Dhammaan');
  String get hiringBrowseNoResults =>
      _t('No open jobs match your search', 'ምንም ተዛማጅ ሥራ የለም', 'Shaqo la midnaysan ma jirto');
  String get hiringDetailTitle =>
      _t('Job details', 'የሥራ ዝርዝር', 'Faahfaahinta shaqada');
  String get hiringDetailBudget =>
      _t('Budget', 'በጀት', 'Miisaaniyada');
  String get hiringDetailPostedBy =>
      _t('Posted by', 'ያቀረበው', 'Xasaabiyey');
  String get hiringApplyButton =>
      _t('Apply now', 'አሁን ተወዳደር', 'Codso hadda');
  String get hiringAlreadyApplied =>
      _t('You have already applied to this post', 'ቀደም ሲል ተወዳድሬያለሁ', 'Horaan u codsatay xasaabkan');
  String get hiringSelectServiceTitle =>
      _t('Select your service', 'አገልግሎትዎን ይምረጡ', 'Dooro adeegga aad bixiso');
  String get hiringSelectServiceHint =>
      _t('Choose which service to apply with', 'ሊያስቀርቡ የሚፈልጉትን አገልግሎት ይምረጡ',
          'Dooro adeegga aad u codsan doonto');
  String get hiringNoServicesPrompt =>
      _t('You need to create a service profile first',
          'ቀድሞ አገልግሎት ፕሮፋይል ይፍጠሩ',
          'Marka hore samee profile adeeg');
  String get hiringNoServicesAction =>
      _t('Create a service', 'አገልግሎት ፍጠር', 'Samee adeeg');
  String get hiringApplyConfirm =>
      _t('Confirm application', 'ማመልከቻ አረጋግጥ', 'Xaqiiji codsiga');
  String get hiringApplySuccess =>
      _t('Application submitted!', 'ማመልከቻ ቀርቧል!', 'Codsigii la gudbiyey!');
  String get hiringDuplicateError =>
      _t('You\'ve already applied with this service',
          'ይህ አገልግሎት ቀድሞ ቀርቧል',
          'Adeeggan horaan u codsatay');

  // ── Applicant detail screen ───────────────────────────────────────────────
  String get applicantDetailTitle =>
      _t('Applicant Details', 'የተወዳዳሪ ዝርዝር', 'Faahfaahinta Codsadaha');
  String get applicantDetailAccept =>
      _t('Accept', 'ተቀበል', 'Aqbal');
  String get applicantDetailReject =>
      _t('Reject', 'ውድቅ አድርግ', 'Diiday');
  String get applicantDetailBackToReview =>
      _t('Back to Review', 'ወደ ግምገማ መልስ', 'Ku noqo Dib-u-Eegista');
  String get applicantDetailChat =>
      _t('Message Applicant', 'ለተወዳዳሪ ጻፍ', 'Fariin u dir Codsadaha');
  String get applicantDetailServiceSection =>
      _t('Applied Service', 'የቀረበ አገልግሎት', 'Adeegga La Codsaday');
  String get applicantDetailProfileSection =>
      _t('Applicant Profile', 'የተወዳዳሪ መገለጫ', 'Profaylka Codsadaha');
  String get applicantDetailReviewsSection =>
      _t('Service Reviews', 'የአገልግሎት ግምገማዎች', 'Dib-u-Eegisyada Adeegga');
  String get applicantDetailCvSection =>
      _t('CV / Resume', 'ሲቪ', 'CV');
  String get applicantDetailCvView =>
      _t('View CV', 'ሲቪ ይክፈቱ', 'Arag CV');
  String get applicantDetailNoCv =>
      _t('No CV uploaded', 'ሲቪ አልቀረበም', 'CV lama soo gelin');
  String get applicantDetailExperience =>
      _t('Years of experience', 'የልምድ ዓመታት', 'Sanadaha Khibradda');
  String get applicantDetailVerified =>
      _t('Verified', 'የተረጋገጠ', 'La xaqiijiyey');
  String get applicantDetailUnverified =>
      _t('Unverified', 'ያልተረጋገጠ', 'La xaqiijin');
  String get applicantDetailNoReviews =>
      _t('No reviews yet', 'ምንም ግምገማ የለም', 'Wali dib-u-eegis la\'ahan');
  String get applicantDetailSubmittedAt =>
      _t('Applied on', 'ያቀረቡበት ቀን', 'Maalinta La Codsaday');
  String get applicantDetailChatError =>
      _t('Could not open chat. Try again.', 'ውይይት መክፈት አልተቻለም።', 'Sheekada lama furi karin. Isku day mar kale.');

  // ── Applicant's grouped application view ─────────────────────────────────
  String get applicationsTitle =>
      _t('My Applications', 'ማመልከቻዎቼ', 'Codsigayga');
  String get applicationsEmpty =>
      _t('No applications yet', 'ምንም ማመልከቻ የለም', 'Wali codsad la\'ahan');
  String get applicationsServiceGroupLabel =>
      _t('Applied from', 'ከ… ቀርቧል', 'Laga codsaday');

  // ── Profile dual-role labels ──────────────────────────────────────────────
  String get profileMyHiringPosts =>
      _t('My job posts', 'የሥራ ልጥፎቼ', 'Xashiisyadayda shaqada');
  String get profileMyServices =>
      _t('My services', 'አገልግሎቶቼ', 'Adeegyadeeyda');
  String get profileMyApplications =>
      _t('My applications', 'ማመልከቻዎቼ', 'Codsigaygaa');

  // ── Notifications ─────────────────────────────────────────────────────────
  String get notificationsTitle =>
      _t('Notifications', 'ማሳወቂያዎች', 'Ogeysiisyada');
  String get notificationsEmpty =>
      _t('No notifications yet', 'ምንም ማሳወቂያ የለም', 'Wali ogeysiin la\'ahan');
  String get notificationNewApplication =>
      _t('New application received', 'አዲስ ማመልከቻ ደርሷል', 'Codsi cusub ayaa yimid');
  String get notificationStatusChanged =>
      _t('Application status updated', 'የማመልከቻ ሁኔታ ተለወጠ',
          'Xaaladda codsigaaga ayaa la beddelay');
  String get notificationMarkRead => _t('Mark as read', 'እንደተነበበ ምልክት ያድርጉ', 'Ku calaamadee akhriyay');

  // ── Settings Screen ──────────────────────────────────────────────────────────
  String get settingsAccountSection => _t('Account settings', 'የሂሳብ ቅንብሮች', 'Dejinta xisaabta');
  String get settingsProfileSubtitle =>
      _t('Change display name, bio, and photos', 'ስም፣ ባዮ እና ፎቶ ይቀይሩ', 'Beddel magaca, xogta');
  String get settingsChangePassword => _t('Change password', 'የፓስወርድ ቀይር', 'Beddel erayga sirta');
  String get settingsChangePasswordSub =>
      _t('Update your account password', 'የእርስዎን ፓስወርድ ይቀይሩ', 'Badal eraygaaga sirta');
  String get settingsPhoneVerification => _t('Phone Verification', 'ስልክ ማረጋገጫ', 'Xaqiijinta telefoonka');
  String get settingsPhoneVerified => _t('Verified', 'ተረጋግጧል', 'Xaqiijiyey');
  String get settingsPrefCategory => _t('Preferred Category', 'ተመራጭ ምድብ', 'Qaybta la doortay');
  String get settingsTrustSection => _t('Trust & Escrow Safety', 'ደህንነት እና ኤስክሮ', 'Ammaan & Escrow');
  String get settingsIdVerification => _t('ID Document Verification', 'ዋስትና ማረጋገጫ', 'Xaqiijinta aqoonsiga');
  String get settingsIdVerified => _t('Active', 'ንቁ', 'Firfircoon');
  String get settingsWallet => _t('Secure Wallet Account', 'የኤስክሮ ዋሌት', 'Xisaabta Escrow');
  String get settingsWalletSub =>
      _t('Configure payout banks & escrow conditions', 'የክፍያ ባንኮችን ያዋቅሩ', 'Habaynta bangiga');
  String get settingsSystemSection => _t('System preferences', 'የስርዓት ቅንብሮች', 'Doorashada nidaamka');
  String get settingsLogOut => _t('Log Out Account', 'ከሂሳብ ውጣ', 'Ka bax xisaabta');

  // ── Saved Screen ─────────────────────────────────────────────────────────────
  String get savedEmptySubAlt => _t(
    'Bookmark listings while browsing',
    'ዝርዝሮችን ሲያስሱ ምልክት ያድርጉባቸው',
    'Calaamadee xayaysiisyada',
  );
  String get savedCompareInfo =>
      _t('Select up to 2 items to compare. ({count}/2 selected)', 'ለማወዳደር እስከ 2 ዕቃዎች ይምረጡ። ({count}/2 ተመርጠዋል)', 'Dooro ilaa 2 shay si aad u barbardhigto. ({count}/2 la doortay)');
  String get savedSelectedCount =>
      _t('{count} items selected', '{count} ዕቃዎች ተመርጠዋል', '{count} shay la doortay');
  String get savedChooseOne => _t('Choose 1 more item', '1 ተጨማሪ ዕቃ ይምረጡ', 'Dooro 1 shay oo kale');
  String get savedReadyAnalyse => _t('Ready to analyse', 'ለመተንተን ዝግጁ', 'Diyaar u baadhibaadh');

  // ── Compare Overlay ──────────────────────────────────────────────────────────
  String get compareClose => _t('Close Comparison', 'ንጽጽር ዝጋ', 'Xidhiidhka xir');
  String get compareStatus => _t('Status', 'ሁኔታ', 'Xaalad');
  String get compareSeller => _t('Seller', 'ሻጭ', 'Iibiyaha');

  // ── Auth Screen errors ───────────────────────────────────────────────────────
  String get authSupabaseUnavailable =>
      _t('Supabase is not available. Check configuration.', 'Supabase አልተገኘም። ቅንብሮቹን ያረጋግጡ።', 'Supabase ma heli karto. Hubi dejinta.');
  String get authGoogleCancelled =>
      _t('Google sign-in was cancelled.', 'የGoogle ግቤት ተሰርዟል።', 'Galitaanka Google waa la joojiyey.');

  // ── Change / Reset Password Screens ─────────────────────────────────────────
  String get changePasswordTitle => _t('Change password', 'የፓስወርድ ቀይር', 'Beddel erayga sirta');
  String get changePasswordLabel => _t('New password', 'አዲስ የይለፍ ቃል', 'Erayga sirta cusub');
  String get changePasswordMin => _t('Minimum 6 characters', 'ቢያንስ 6 ቁምፊ', 'Ugu yaraan 6 xaraf');
  String get changePasswordButton => _t('Change password', 'ፓስወርድ ቀይር', 'Beddel erayga sirta');
  String get changePasswordSaving => _t('Saving…', 'በማስቀመጥ ላይ…', 'Waa la kaydiyaa…');
  String get changePasswordSuccess => _t('Password updated', 'ፓስወርድ ተቀይሯል', 'Erayga sirta waa la cusboonaysiiyey');
  String get supabaseNotConfigured => _t('Supabase not configured', 'Supabase አልተዋቀረም', 'Supabase lama dejin');

  String get resetPasswordTitle => _t('Reset password', 'ፓስወርድ ዳግም ቀይር', 'Dib u deji erayga sirta');
  String get resetPasswordEmailSent => _t('Password reset email sent', 'የፓስወርድ ዳግም ማስጀመሪያ ኢሜይል ተልኳል', 'Iimaylka dib-u-dejisku waa la diray');
  String get resetPasswordButton => _t('Send reset email', 'ዳግም ማስጀመሪያ ኢሜይል ላክ', 'Dir iimaylka dib-u-dejinta');
  String get resetPasswordSending => _t('Sending…', 'በመላክ ላይ…', 'Waa la diraya…');
  String get resetPasswordEmailHint => _t('Enter email', 'ኢሜይል ያስገቡ', 'Geli iimayl');

  // ── Edit Profile Screen ──────────────────────────────────────────────────────
  String get editProfileTitle => _t('Edit Profile', 'መገለጫ ያርትዑ', 'Wax ka beddel xogta');
  String get editProfileDisplayName => _t('Display name', 'ስም', 'Magaca la muujinayo');
  String get editProfileBio => _t('Bio', 'ባዮ', 'Xog gaaban');
  String get editProfileDisplayNameRequired => _t('Display name is required', 'ስም ያስፈልጋል', 'Magaca waa lagama maarmaan');
  String get editProfileSaving => _t('Saving...', 'በማስቀመጥ ላይ...', 'Waa la kaydiyaa...');
  String get editProfileSaveButton => _t('Save changes', 'ለውጦችን አስቀምጥ', 'Keydi isbeddelada');
  String get editProfileChangePhoto => _t('Change profile photo', 'የፕሮፋይል ፎቶ ቀይር', 'Beddel sawirka xogta');
  String get editProfileChangeBanner => _t('Change background image', 'የዳራ ምስል ቀይር', 'Beddel sawirka asalka');
  String get editProfilePhotoUploading => _t('Uploading photo...', 'ፎቶ በመስቀል ላይ...', 'Sawirka waa la raraa...');
  String get editProfilePhotoError => _t('Failed to upload photo', 'ፎቶ ለማስቀምጫ አልተቻለም', 'Waxaa dhacay khalad sawirka');
  String get editProfileEditName => _t('Edit name', 'ስም ያርትዑ', 'Wax ka beddel magaca');
  String get editProfileNameLabel => _t('Display name', 'ስም', 'Magaca la muujinayo');
  String get editProfileNameSave => _t('Save', 'አስቀምጥ', 'Keydi');
  String get editProfilePhotoSection => _t('Photos', 'ፎቶዎች', 'Sawirrada');
  String get editProfilePrefCategory => _t('Preferred category', 'ተመራጭ ምድብ', 'Qaybta la doortay');
  String get editProfilePrefCategoryHint => _t('Select a category', 'ምድብ ምረጥ', 'Dooro qaybta');
  String get editProfilePrefCategoryNone => _t('None', 'የለም', 'Midna');
  String get editProfilePhone => _t('Phone number', 'ስልክ ቁጥር', 'Lambarka telefoonka');
  String get editProfileCity => _t('City', 'ከተማ', 'Magaalada');
  String get editProfilePhotoQueued => _t('Photo will upload when you reconnect', 'ፎቶ ሲገናኙ ይጫናል', 'Sawirku wuxuu rarmi doonaa marka aad ku xidnaatid');

  // ── Listing Detail Screen ────────────────────────────────────────────────────
  String get detailLinkShared => _t('Link shared!', 'ሊንክ ተጋርቷል!', 'Xiriirka la wadaagay!');
  String get detailLocationLabel => _t('Location', 'ቦታ', 'Goobta');
  String get detailOpenMaps => _t('Open in Maps', 'በካርታ ክፈት', 'Ku fur khariidadda');
  String get detailOpeningMaps => _t('Opening Google Maps...', 'Google Maps እየከፈቱ...', 'Waa la furaya Google Maps...');
  String get detailContactDetailsTitle => _t('Contact Details', 'የእውቂያ ዝርዝሮች', 'Faahfaahinta xiriirka');
  String get detailContactHidden => _t(
    'Contact details are shared after 3 messages are exchanged, or when either party taps "Share phone number" in the chat.',
    'የእውቂያ ዝርዝሮች ከ3 መልዕክቶች ልውውጥ በኋላ ወይም ማንኛውም ወገን "ስልክ ቁጥር ያጋሩ" ሲጫን ይጋራሉ።',
    'Faahfaahinta xiriirka waxaa la wadaagaa ka dib 3 farriin oo is-dhaafsiisan, ama marka mid ka mid ah labada dhinac uu garaaco "La wadaag lambarka telefoonka" sheekada.',
  );
  String get detailGoToChat => _t('Go to chat', 'ወደ ቻት ሂድ', 'U tag sheekada');
  String get detailStartChat => _t('Start chat', 'ቻት ጀምር', 'Bilow sheekada');
  String get detailRequestLogged => _t('Request logged. Partner notified!', 'ጥያቄ ተመዝግቧል። አጋር ተነግሯቸዋል!', 'Codsiga waa la diiwaan galiyey. Iskaashiga ayaa la ogeysiiyey!');

  // ── Viewing Request Bottom Sheet ────────────────────────────────────────────
  String get viewingSheetTitle =>
      _t('Schedule a Visit', 'ጉብኝት ያቅዱ', 'Jadweli booqasho');
  String get viewingSheetSubtitle => _t(
    'Pick a date and time to visit this property. A message will be sent to the owner.',
    'ይህን ሪል እስቴት ለመጎብኘት ቀን እና ሰዓት ይምረጡ። ለባለቤቱ መልእክት ይላካል።',
    'Dooro taariikh iyo waqti si aad u booqato hantidan. Fariin ayaa loo diri doonaa milkiilaha.',
  );
  String get viewingSelectDate =>
      _t('Select Date', 'ቀን ይምረጡ', 'Dooro taariikh');
  String get viewingSelectTime =>
      _t('Select Time', 'ሰዓት ይምረጡ', 'Dooro waqtiga');
  String get viewingConfirmButton =>
      _t('Send Visit Request', 'ጥያቄ ይላኩ', 'Dir codsi booqasho');
  String get viewingRequestSent => _t(
    'Visit request sent to the owner!',
    'ጥያቄ ለባለቤቱ ተልኳል!',
    'Codsi booqasho ayaa loo diray milkiilaha!',
  );
  String get viewingRequestFailed => _t(
    'Could not send request. Please try again.',
    'ጥያቄ መላክ አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
    'Codsi la diray ma ahayn. Fadlan isku day mar kale.',
  );
  String get viewingMessageTemplate => _t(
    '📅 Visit Request\nDate: {date}\nTime: {time}\n\nI would like to visit this property. Please confirm.',
    '📅 የጉብኝት ጥያቄ\nቀን: {date}\nሰዓት: {time}\n\nይህን ሪል እስቴት ለመጎብኘት እፈልጋለሁ። እባክዎ ያረጋግጡ።',
    '📅 Codsi Booqasho\nTaariikh: {date}\nWaqtiga: {time}\n\nWaxaan jeclaan lahaa inaan booqdo hantidan. Fadlan xaqiiji.',
  );
  String get viewingNeedLoginToast => _t(
    'Sign in to send a visit request',
    'ጥያቄ ለመላክ ይግቡ',
    'Gal si aad codsi u dirtid',
  );
  String get detailVerifiedListing => _t('Verified Listing', 'የተረጋገጠ ዝርዝር', 'Xayaysiis la xaqiijiyey');
  String get detailVerifiedPro => _t('Verified Skilled Professional', 'የተረጋገጠ ባለሙያ', 'Xirfadle la xaqiijiyey');

  // ── Category List Screen ─────────────────────────────────────────────────────
  String get catNoMatchingListings => _t('No matching listings found', 'ተዛማጅ ዝርዝሮች አልተገኙም', 'Xayaysiis ku habboon ma helin');
  String get catClearFilters => _t('Try clearing your query filters', 'ማጣሪያዎቹን ለማጽዳት ይሞክሩ', 'Isku day nadiifi shaandhaynta');
  String get catResultsIn => _t('results in Jigjiga', 'ውጤቶች በጂግጂጋ', 'natiijo Jigjiga');

  // ── Compare Overlay rows (dynamic) ──────────────────────────────────────────
  String get compareSpec1 => _t('Spec 1', 'መስፈርት 1', 'Sifo 1');
  String get compareSpec2 => _t('Spec 2', 'መስፈርት 2', 'Sifo 2');
  String get compareSpec3 => _t('Spec 3', 'መስፈርት 3', 'Sifo 3');
  String get compareConditionLabel => _t('Condition', 'ሁኔታ', 'Xaalad');

  // ── Category List Screen filter chips ────────────────────────────────────────
  String get catRentBuy => _t('Rent / Buy', 'ለኪራይ / ለሽያጭ', 'Kiradda / Iib');
  String get catPriceRange => _t('Price Range', 'የዋጋ ክልል', 'Xadka qiimaha');
  String get catBedrooms => _t('Bedrooms', 'አልጋ ቤቶች', 'Qolalka jiifka');
  String get catLandUse => _t('Land-use', 'የመሬት አጠቃቀም', 'Isticmaalka dhulka');
  String get catMore => _t('More', 'ተጨማሪ', 'Wax dheeraad ah');
  String get catListView => _t('List', 'ዝርዝር', 'Liis');
  String get catMapView => _t('Map', 'ካርታ', 'Khariidad');
  String get catSearchHint => _t('Search', 'ፈልግ', 'Raadi');
  String get catResultsCount => _t('{count} results in Jigjiga', '{count} ውጤቶች በጂግጂጋ', '{count} natiijo Jigjiga');

  // Filter option labels
  String get catFilterAll  => _t('All',      'ሁሉም',    'Dhammaan');
  String get catFilterSale => _t('For Sale', 'ለሽያጭ',  'Iib');
  String get catFilterRent => _t('For Rent', 'ለኪራይ',  'Kiradda');
  String get catFilterNew  => _t('New only', 'አዲስ ብቻ', 'Cusub oo kaliya');
  // Grid / compact layout toggle
  String get catGridView   => _t('Grid', 'ግሪድ', 'Shabag');
  // Sort
  String get catSortLabel    => _t('Sort', 'አስቀምጥ', 'Kala sooc');
  String get catSortNewest   => _t('Newest', 'አዲሱ', 'Cusub');
  String get catSortPriceAsc => _t('Price: Low→High', 'ዋጋ: ዝቅ→ከፍ', 'Qiimaha: Hoose→Sareeye');
  String get catSortPriceDsc => _t('Price: High→Low', 'ዋጋ: ከፍ→ዝቅ', 'Qiimaha: Sareeye→Hoose');
  // Legacy alias kept for compatibility
  String get catSortPrice  => catSortPriceAsc;
  // Price range sheet labels
  String get catPriceMin   => _t('Min price', 'ዝቅተኛ ዋጋ', 'Qiimaha ugu hooseeya');
  String get catPriceMax   => _t('Max price', 'ከፍተኛ ዋጋ', 'Qiimaha ugu sarreeya');
  String get catApply      => _t('Apply', 'ተግብር', 'Codso');
  String get catReset      => _t('Reset', 'ዳግም ጀምር', 'Dib u dejiso');
  // Bedroom options
  String get catBed1Plus   => _t('1+', '1+', '1+');
  String get catBed2Plus   => _t('2+', '2+', '2+');
  String get catBed3Plus   => _t('3+', '3+', '3+');
  String get catBed4Plus   => _t('4+', '4+', '4+');
  // Land-use options
  String get catLandResidential  => _t('Residential',  'መኖሪያ',    'Deganaanshaha');
  String get catLandAgricultural => _t('Agricultural', 'ግብርና',    'Beeraha');
  String get catLandCommercial   => _t('Commercial',   'ንግዳዊ',    'Ganacsi');
  // Car-specific filter labels
  String get catCarFuelType     => _t('Fuel Type',     'የነዳጅ አይነት',  'Nooca shidaalka');
  String get catCarTransmission => _t('Transmission',  'ማስተላለፊያ',    'Wareejinta');
  String get catCarYearRange    => _t('Year',          'ዓ.ም.',        'Sannadka');
  // Year range sheet from/to labels
  String get catYearFrom        => _t('From',          'ከ',           'Laga bilaabo');
  String get catYearTo          => _t('To',            'እስከ',         'Ilaa');
  // Fuel-type options
  String get catFuelPetrol   => _t('Petrol',   'ቤንዚን',   'Petrol');
  String get catFuelDiesel   => _t('Diesel',   'ዲዘል',    'Diesel');
  String get catFuelHybrid   => _t('Hybrid',   'ሃይብሪድ',  'Hybrid');
  String get catFuelElectric => _t('Electric', 'ኤሌክትሪክ', 'Korontada');
  // Transmission options
  String get catTransAuto   => _t('Automatic', 'አውቶማቲክ', 'Otomaatig');
  String get catTransManual => _t('Manual',    'ማኑዋል',    'Gacanta');

  // ── Home screen trust badge cards ─────────────────────────────────────────────
  String get homeTrustHomeowner => _t(
    'A homeowner in Kebele 03 just got verified',
    'የቀበሌ 03 ቤት ባለቤት አሁን ተረጋገጠ',
    'Milkiile guriga Kebele 03 ayaa la xaqiijiyey',
  );
  String get homeTrustDriver => _t(
    'A security professional driver just joined',
    'የደህንነት ባለሙያ ሾፌር ለቀላቀለ',
    'Wadaad xirfadleh oo ammaaneed ayaa ku biirtay',
  );

  // ── Post Wizard step 2/3 hints (English-only data; structural, not translatable) ──
  // These are placeholder hints for form fields — they describe data format,
  // not UI chrome, so they intentionally remain in English.
  // (e.g. 'e.g. 2022 Toyota Land Cruiser Prado')

  // ── Post Wizard step 2 — name/title label for skills ─────────────────────────
  String get wizardNameTitleLabel => _t('Your Name / Title', 'ስምዎ / ርዕስ', 'Magacaaga / Cinwaanka');

  // ── Translation indicator ─────────────────────────────────────────────────────
  String get translatedBadge => _t('Translated', 'ተተርጉሟል', 'La turjumay');
  String get translatedTooltip => _t(
    'This content was machine-translated from the original language.',
    'ይህ ይዘት ከዋናው ቋንቋ በማሽን ተተርጉሟል።',
    'Qoraalkan waxaa turjumay mashiin ka ah luqadda asalka ah.',
  );

  // ── Fayda ID Verification Screen ─────────────────────────────────────────────
  String get faydaTitle =>
      _t('Verify with Fayda ID', 'በፋይዳ መታወቂያ ያረጋግጡ', 'Xaqiiji Fayda ID');
  String get faydaSubtitle => _t(
    'Fayda is Ethiopia\'s national digital ID. Verified accounts get a trust badge and higher ranking in Koolan.',
    'ፋይዳ የኢትዮጵያ ሀገራዊ ዲጂታል መታወቂያ ነው። የተረጋገጡ መለያዎች የእምነት ምልክት እና ከፍተኛ ደረጃ ያገኛሉ።',
    'Fayda waa aqoonsiga dhijitaalka qaranka Itoobiya. Xisaabaha la xaqiijiyey waxay helaan calaamadda kalsoonida iyo darajada sare.',
  );
  String get faydaIdLabel =>
      _t('Fayda ID Number', 'የፋይዳ መታወቂያ ቁጥር', 'Lambarka Fayda ID');
  String get faydaIdHint =>
      _t('Enter your 14-digit Fayda ID', 'የ14-ቁጥር ፋይዳ መታወቂያ ያስገቡ', 'Geli Fayda ID-kaaga 14-lambar');
  String get faydaIdRequired =>
      _t('Fayda ID is required', 'የፋይዳ መታወቂያ ያስፈልጋል', 'Fayda ID waa lagama maarmaan');
  String get faydaIdInvalid => _t(
    'Enter a valid 14-digit Fayda ID',
    'ትክክለኛ 14-ቁጥር ፋይዳ መታወቂያ ያስገቡ',
    'Geli Fayda ID 14-lambar oo sax ah',
  );
  String get faydaOtpTitle =>
      _t('Enter verification code', 'የማረጋገጫ ኮድ ያስገቡ', 'Geli koodhka xaqiijinta');
  String get faydaOtpSubtitle => _t(
    'A 6-digit code was sent to your registered phone number.',
    'ለተመዘገበ ስልክዎ 6-ቁጥር ኮድ ተልኳል።',
    'Koodh 6-lambar ah ayaa loo diray lambarka telefoonka diiwaan gashan.',
  );
  String get faydaOtpLabel =>
      _t('Verification Code', 'የማረጋገጫ ኮድ', 'Koodhka Xaqiijinta');
  String get faydaOtpHint =>
      _t('Enter 6-digit code', '6-ቁጥር ኮድ ያስገቡ', 'Geli koodh 6-lambar');
  String get faydaOtpRequired =>
      _t('Verification code is required', 'የማረጋገጫ ኮድ ያስፈልጋል', 'Koodhka xaqiijinta waa lagama maarmaan');
  String get faydaOtpInvalid =>
      _t('Enter the 6-digit code', '6-ቁጥር ኮድ ያስገቡ', 'Geli koodh 6-lambar');
  String get faydaResendCode =>
      _t('Resend code', 'ኮድ እንደገና ላክ', 'Dib u dir koodhka');
  String get faydaVerifyButton =>
      _t('Verify Identity', 'ማንነት ያረጋግጡ', 'Xaqiiji Aqoonsiga');
  String get faydaSubmitButton =>
      _t('Confirm Code', 'ኮድ አረጋግጥ', 'Xaqiiji Koodhka');
  String get faydaVerifying =>
      _t('Verifying…', 'በማረጋገጥ ላይ…', 'Waa la xaqiijinayaa…');
  String get faydaSuccess => _t(
    'Identity verified successfully!',
    'ማንነቱ በተሳካ ሁኔታ ተረጋግጧል!',
    'Aqoonsiga si guul leh ayaa loo xaqiijiyey!',
  );
  String get faydaSuccessSubtitle => _t(
    'Your account now has a Fayda Verified badge. Buyers and sellers will see you as a trusted member.',
    'መለያዎ አሁን የፋይዳ ማረጋገጫ ምልክት አለው። ገዢዎች እና ሻጮች እርስዎን እንደ ታማኝ አባል ያዩዎታል።',
    'Xisaabtaada hadda waxay leedahay calaamadda Fayda Xaqiijiyey. Iibiyayaasha iyo iibsadeyaashu waxay kugu arki doonaan xubin la믿aha ah.',
  );
  String get faydaContinue =>
      _t('Continue to Koolan', 'ወደ ኩላን ቀጥል', 'U gudub Koolan');
  String get faydaSkip =>
      _t('Skip for now', 'አሁን ዝለል', 'Hadda ka bood');
  String get faydaTrustBadge =>
      _t('Fayda Verified', 'ፋይዳ ተረጋግጧል', 'Fayda Xaqiijiyey');
  String get faydaBenefitsTitle =>
      _t('Benefits of verification', 'የማረጋገጫ ጥቅሞች', 'Faa\'iidooyinka xaqiijinta');
  String get faydaBenefit1 =>
      _t('Trusted badge on your profile', 'የሚተማመን ምልክት', 'Calaamadda kalsoonida');
  String get faydaBenefit2 =>
      _t('Higher search ranking', 'ከፍተኛ የፍለጋ ደረጃ', 'Darajada raadinta ee sare');
  String get faydaBenefit3 =>
      _t('Access to escrow payments', 'ወደ escrow ክፍያዎች ይድረሱ', 'Gelitaanka lacag-bixinta escrow');
  String get faydaErrorGeneric => _t(
    'Verification failed. Please try again.',
    'ማረጋገጥ አልተሳካም። እባክዎ እንደገና ይሞክሩ።',
    'Xaqiijintu fashilantay. Fadlan isku day mar kale.',
  );
  String get faydaErrorNetwork => _t(
    'Network error. Check your connection and retry.',
    'የአውታረ መረብ ስህተት። ግንኙነትዎን ያረጋግጡ እና እንደገና ይሞክሩ።',
    'Khalad shabakadeed. Hubi xiriirkaaga oo isku day mar kale.',
  );
  String get faydaStep1of2 => _t('Step 1 of 2', 'ደረጃ 1 ከ 2', 'Tallaabo 1 oo ah 2');
  String get faydaStep2of2 => _t('Step 2 of 2', 'ደረጃ 2 ከ 2', 'Tallaabo 2 oo ah 2');
  String get faydaWhatIsFayda => _t(
    'What is Fayda ID?',
    'ፋይዳ መታወቂያ ምንድን ነው?',
    'Maxaa ah Fayda ID?',
  );
  String get faydaWhatIsFaydaBody => _t(
    'Fayda is the Ethiopian National ID system. Your 14-digit ID number is printed on your national ID card.',
    'ፋይዳ የኢትዮጵያ ሀገራዊ መታወቂያ ስርዓት ነው። 14-ቁጥር መታወቂያ ቁጥርዎ በሀገራዊ መታወቂያ ካርድዎ ላይ ይታያል።',
    'Fayda waa nidaamka aqoonsiga qaranka Itoobiya. Lambarka aqoonsigaaga 14-lambar ah waxaa lagu daabacay kaadhkaaga aqoonsiga qaranka.',
  );
}
