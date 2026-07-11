import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const KoolanApp());
}

// ==========================================
// DESIGN SYSTEM TOKENS (PREMIUM COLOR PALETTE)
// ==========================================
const Color kPrimary = Color(0xFF00288E);
const Color kOnPrimary = Color(0xFFFFFFFF);
const Color kPrimaryContainer = Color(0xFF1E40AF);
const Color kOnPrimaryContainer = Color(0xFFA8B8FF);

const Color kSecondary = Color(0xFF0058BE);
const Color kOnSecondary = Color(0xFFFFFFFF);
const Color kSecondaryContainer = Color(0xFF2170E4);
const Color kOnSecondaryContainer = Color(0xFFFEFCFF);

const Color kTertiary = Color(0xFF003564);
const Color kOnTertiary = Color(0xFFFFFFFF);
const Color kTertiaryContainer = Color(0xFF004C8B);
const Color kOnTertiaryContainer = Color(0xFF8FBEFF);

const Color kError = Color(0xFFBA1A1A);
const Color kOnError = Color(0xFFFFFFFF);
const Color kErrorContainer = Color(0xFFFFDAD6);
const Color kOnErrorContainer = Color(0xFF93000A);

const Color kBackground = Color(0xFFF9F9FF);
const Color kOnBackground = Color(0xFF111C2D);

const Color kSurface = Color(0xFFF9F9FF);
const Color kOnSurface = Color(0xFF111C2D);
const Color kSurfaceVariant = Color(0xFFD8E3FB);
const Color kOnSurfaceVariant = Color(0xFF444653);

const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color kSurfaceContainerLow = Color(0xFFF0F3FF);
const Color kSurfaceContainer = Color(0xFFE7EEFF);
const Color kSurfaceContainerHigh = Color(0xFFDEE8FF);
const Color kSurfaceContainerHighest = Color(0xFFD8E3FB);

const Color kOutline = Color(0xFF757684);
const Color kOutlineVariant = Color(0xFFC4C5D5);

const Color kVerifiedColor = Color(0xFF1F8A5C);
const Color kVerifiedBackground = Color(0xFFE8F5E9);

// ==========================================
// CORE DATA MODELS
// ==========================================
class Listing {
  final int id;
  final String category; // CARS, HOUSES, LAND, SKILLS
  final String title;
  final String price;
  final String imageUrl;
  final String location;
  final bool verified;
  final bool isSaved;
  final String conditionOrStatus;
  final String sellerName;
  final String sellerImage;
  final double sellerRating;
  final int sellerReviewsCount;
  final String description;
  final String? spec1Label;
  final String? spec1Value;
  final String? spec2Label;
  final String? spec2Value;
  final String? spec3Label;
  final String? spec3Value;
  final String? spec4Label;
  final String? spec4Value;
  final bool isCustom;

  Listing({
    required this.id,
    required this.category,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.location,
    this.verified = false,
    this.isSaved = false,
    required this.conditionOrStatus,
    required this.sellerName,
    this.sellerImage = '',
    this.sellerRating = 4.8,
    this.sellerReviewsCount = 12,
    this.description = '',
    this.spec1Label,
    this.spec1Value,
    this.spec2Label,
    this.spec2Value,
    this.spec3Label,
    this.spec3Value,
    this.spec4Label,
    this.spec4Value,
    this.isCustom = false,
  });

  Listing copyWith({
    int? id,
    String? category,
    String? title,
    String? price,
    String? imageUrl,
    String? location,
    bool? verified,
    bool? isSaved,
    String? conditionOrStatus,
    String? sellerName,
    String? sellerImage,
    double? sellerRating,
    int? sellerReviewsCount,
    String? description,
    String? spec1Label,
    String? spec1Value,
    String? spec2Label,
    String? spec2Value,
    String? spec3Label,
    String? spec3Value,
    String? spec4Label,
    String? spec4Value,
    bool? isCustom,
  }) {
    return Listing(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      verified: verified ?? this.verified,
      isSaved: isSaved ?? this.isSaved,
      conditionOrStatus: conditionOrStatus ?? this.conditionOrStatus,
      sellerName: sellerName ?? this.sellerName,
      sellerImage: sellerImage ?? this.sellerImage,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerReviewsCount: sellerReviewsCount ?? this.sellerReviewsCount,
      description: description ?? this.description,
      spec1Label: spec1Label ?? this.spec1Label,
      spec1Value: spec1Value ?? this.spec1Value,
      spec2Label: spec2Label ?? this.spec2Label,
      spec2Value: spec2Value ?? this.spec2Value,
      spec3Label: spec3Label ?? this.spec3Label,
      spec3Value: spec3Value ?? this.spec3Value,
      spec4Label: spec4Label ?? this.spec4Label,
      spec4Value: spec4Value ?? this.spec4Value,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final String timestamp;
  final bool isMe;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatSession {
  final String partnerName;
  final String partnerAvatar;
  final String listingTitle;
  final List<ChatMessage> messages;
  final int unreadCount;

  ChatSession({
    required this.partnerName,
    required this.partnerAvatar,
    required this.listingTitle,
    required this.messages,
    this.unreadCount = 0,
  });

  ChatSession copyWith({
    String? partnerName,
    String? partnerAvatar,
    String? listingTitle,
    List<ChatMessage>? messages,
    int? unreadCount,
  }) {
    return ChatSession(
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      listingTitle: listingTitle ?? this.listingTitle,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// ==========================================
// LOCALIZATION — ENGLISH, AMHARIC & SOMALI
// ==========================================
class AppStrings {
  final String locale;
  const AppStrings(this.locale);

  bool get isAmharic => locale == "am";
  bool get isSomali  => locale == "so";

  String _t(String en, String am, String so) =>
      locale == "am" ? am : locale == "so" ? so : en;

  // App-wide
  String get appName => _t("Koolan", "ኩላን", "Koolan");

  // Bottom Navigation
  String get navHome     => _t("Home",     "ዋና ገጽ",    "Guriga");
  String get navSaved    => _t("Saved",    "የተቀመጡ",   "La kaydiyey");
  String get navPost     => _t("Post",     "አስተዋውቅ",  "Ku daji");
  String get navMessages => _t("Messages", "መልዕክቶች",  "Farriimaha");
  String get navProfile  => _t("Profile",  "መገለጫ",    "Xogta");

  // Home Screen
  String get homeGreeting       => _t("Find what you need",             "የሚፈልጉትን ያግኙ",           "Hel waxa aad u baahan tahay");
  String get homeCategoryCars   => _t("Cars",                           "መኪናዎች",                  "Gawaarida");
  String get homeCategoryHouses => _t("Houses",                         "ቤቶች",                    "Guryaha");
  String get homeCategoryLand   => _t("Land",                           "መሬት",                    "Dhul");
  String get homeCategorySkills => _t("Skills",                         "ችሎታዎች",                 "Xirfadlayaasha");
  String get homeSearchHint     => _t("Search listings...",             "ዝርዝሮችን ፈልግ...",         "Raadi xayaysiisyada...");
  String get homeRecentlyAdded  => _t("Recently Added Near You",        "በአቅራቢያዎ አዲስ የተጨመሩ",     "Dhawaan lagu daray");
  String get homeViewAll        => _t("View All Recent Listings",       "ሁሉንም ዝርዝሮች ይመልከቱ",     "Arag dhammaan xayaysiisyada");
  String get homeTrustTitle     => _t("Trusted Community",              "ታመነ ማህበረሰብ",            "Bulshada la믿aha ah");
  String get homeVerifiedStats  => _t("98% verified listings in Jigjiga","98% የተረጋገጡ ዝርዝሮች",    "98% xayaysiis xaqiijiyey");
  String get homeSeeStats       => _t("See stats",                      "ስታቲስቲክስ ይመልከቱ",        "Arag tirooyin");
  String get homeNoNotifications=> _t("No new notifications",           "አዲስ ማሳወቂያ የለም",          "Wax ogeysiis cusub ma jiraan");

  // Category List Screen
  String get catVerifiedOnly => _t("Verified only", "የተረጋገጡ ብቻ",  "Kuwa xaqiijiyey oo kaliya");
  String get catAll          => _t("All",           "ሁሉም",         "Dhammaan");
  String get catForSale      => _t("For Sale",      "ለሽያጭ",        "Iib");
  String get catForRent      => _t("For Rent",      "ለኪራይ",        "Kiradda");
  String get catNewOnly      => _t("New only",      "አዲስ ብቻ",      "Cusub oo kaliya");

  // Listing Detail Screen
  String get detailSeller          => _t("Seller",                           "ሻጭ",                      "Iibiyaha");
  String get detailContact         => _t("Contact",                          "ያግኙ",                     "La xiriir");
  String get detailChat            => _t("Chat",                             "ቻት",                      "Sheekeyso");
  String get detailViewProfile     => _t("View Profile",                     "መገለጫ ይመልከቱ",             "Arag xogta");
  String get detailUnlockContact   => _t("Unlock Contact",                   "ግንኙነት ይክፈቱ",             "Fur xiriirka");
  String get detailRequestHire     => _t("Request Hire",                     "ቅጠር ጠይቅ",                "Dalbo shaqo");
  String get detailViewProperty    => _t("View Property",                    "ሪል እስቴት ይመልከቱ",          "Arag hantida");
  String get detailDescription     => _t("Description",                      "መግለጫ",                    "Sharaxaad");
  String get detailSpecs           => _t("Specifications",                   "ዝርዝሮች",                   "Sifooyinka");
  String get detailVerified        => _t("Verified",                         "የተረጋገጠ",                  "Xaqiijiyey");
  String get detailReviews         => _t("reviews",                          "ግምገማዎች",                  "dib-u-eegis");
  String get detailContactUnlocked => _t("Contact unlocked! Phone: +251-XXX-XXXX", "ግንኙነት ተከፍቷል! ስልክ: +251-XXX-XXXX", "Xiriirka la furay! Tel: +251-XXX-XXXX");
  String get detailProfileVerified => _t("Full profile verification: OK",    "ሙሉ የመገለጫ ማረጋገጫ: ተሳካ",  "Xaqiijinta xogta: OK");

  // Saved Screen
  String get savedTitle         => _t("Saved Listings",              "የተቀመጡ ዝርዝሮች",           "Liiska la kaydiyey");
  String get savedEmpty         => _t("Nothing saved yet",           "ምንም አልተቀመጠም",            "Wax la kaydin ma jiro");
  String get savedEmptySub      => _t("Bookmark listings while browsing", "ዝርዝሮችን ሲያስሱ ምልክት ያድርጉባቸው", "Calaamadee xayaysiisyada");
  String get savedCompare       => _t("Compare",                     "ያወዳድሩ",                   "Is-bar-bar dhig");
  String get savedDone          => _t("Done",                        "ተጠናቋል",                   "Dhammaatay");
  String get savedSelectTwo     => _t("Select up to 2 listings",     "እስከ 2 ዝርዝሮች ይምረጡ",       "Dooro ilaa 2 xayaysiis");
  String get savedCompareButton => _t("Compare",                     "ያወዳድሩ",                   "Is-bar-bar dhig");

  // Compare Overlay
  String get compareTitle     => _t("Side-by-side Compare", "ጎን ለጎን ያወዳድሩ",  "Is-bar-bar dhigga");
  String get compareFeature   => _t("Feature",              "ባህሪ",             "Astaamaha");
  String get comparePrice     => _t("Price",                "ዋጋ",              "Qiimaha");
  String get compareLocation  => _t("Location",             "ቦታ",              "Goobta");
  String get compareCondition => _t("Condition",            "ሁኔታ",             "Xaalad");
  String get compareVerified  => _t("Verified",             "የተረጋገጠ",          "Xaqiijiyey");
  String get compareYes       => _t("Yes ✓",                "አዎ ✓",            "Haa ✓");
  String get compareNo        => _t("No",                   "አይደለም",           "Maya");

  // Post Wizard
  String get wizardTitle        => _t("Post a Listing",              "ዝርዝር ያስቀምጡ",             "Ku daji xayaysiis");
  String get wizardStep1        => _t("Choose Category",             "ምድብ ይምረጡ",                "Dooro qeybta");
  String get wizardStep2        => _t("Your Info",                   "የእርስዎ መረጃ",               "Macluumaadkaaga");
  String get wizardStep3        => _t("Details",                     "ዝርዝሮች",                   "Faahfaahinta");
  String get wizardStep4        => _t("Review & Submit",             "ይገምግሙ እና ያስቀምጡ",          "Dib u eeg oo gudbi");
  String get wizardNext         => _t("Next",                        "ቀጣይ",                     "Xiga");
  String get wizardBack         => _t("Back",                        "ተመለስ",                    "Dib u noqo");
  String get wizardSubmit       => _t("Submit Listing",              "ዝርዝር ያስቀምጡ",             "Gudbi xayaysiiska");
  String get wizardPhotoAttach  => _t("Attach Photo",                "ፎቶ ያያይዙ",                 "Ku dar sawir");
  String get wizardPhotoAttached=> _t("Photo attached ✓",            "ፎቶ ተያይዟል ✓",             "Sawirka la daray ✓");
  String get wizardTitleLabel   => _t("Title",                       "ርዕስ",                     "Cinwaan");
  String get wizardPriceLabel   => _t("Price",                       "ዋጋ",                      "Qiimaha");
  String get wizardDescLabel    => _t("Description",                 "መግለጫ",                    "Sharaxaad");
  String get wizardLocationLabel=> _t("Location",                    "ቦታ",                      "Goobta");
  String get wizardAddressLabel => _t("Physical Address",            "አካላዊ አድራሻ",               "Cinwaanka jireed");
  String get wizardPhotoMock    => _t("Mock photo attached successfully!", "ሞክ ፎቶ ተያይዟል!",    "Sawirada si guul leh ayaa loo daray!");
  String get wizardPosted       => _t("Your listing has been posted!", "ዝርዝርዎ ተለጠፈ!",         "Xayaysiiskaagu waa la daabacay!");

  // Messages Screen
  String get messagesTitle => _t("Messages",           "መልዕክቶች",  "Farriimaha");
  String get messagesEmpty => _t("No active chats yet","ምንም ንቁ ቻት የለም", "Ma jiraan sheekooyin firfircoon");

  // Active Chat Screen
  String get chatInputHint => _t("Type a message...",         "መልዕክት ይጻፉ...",          "Qor fariin...");
  String get chatSend      => _t("Send",                      "ላክ",                     "Dir");
  String get chatReplied   => _t("Sounds good, what do you think?", "ደህና ነው, ምን ያስቡ ነበር?", "Waa hagaagsan tahay, maxaad u maleynaysaa?");

  // Settings / Profile Screen
  String get settingsTitle        => _t("Settings",            "ቅንብሮች",                  "Dejinta");
  String get settingsProfile      => _t("Edit Profile",        "መገለጫ ያርትዑ",             "Wax ka beddel xogta");
  String get settingsNotifications=> _t("Notifications",       "ማሳወቂያዎች",               "Ogeysiisyada");
  String get settingsPushEnabled  => _t("Push Notifications",  "ፑሽ ማሳወቂያዎች",            "Ogeysiisyada push");
  String get settingsNewMessages  => _t("New Messages",        "አዲስ መልዕክቶች",             "Farriimaha cusub");
  String get settingsPriceAlerts  => _t("Price Alerts",        "የዋጋ ማስጠንቀቂያዎች",          "Digniin qiimeed");
  String get settingsTheme        => _t("Theme",               "ገጽታ",                    "Muuqaalka");
  String get settingsDarkMode     => _t("Dark Mode",           "ጨለማ ሁነታ",               "Habeennimo");
  String get settingsLanguage     => _t("Language",            "ቋንቋ",                    "Luqadda");
  String get settingsSave         => _t("Save Changes",        "ለውጦችን አስቀምጥ",           "Keydi isbeddelada");
  String get settingsSaved        => _t("Saved!",              "ተቀምጧል!",                 "La kaydiyey!");
  String get settingsNameLabel    => _t("Full Name",           "ሙሉ ስም",                  "Magaca buuxa");
  String get settingsPhoneLabel   => _t("Phone",               "ስልክ",                    "Telefoonka");
  String get settingsCityLabel    => _t("City",                "ከተማ",                    "Magaalada");
}

// ==========================================
// NAVIGATION SYSTEM (SEALED CLASS PORT)
// ==========================================
abstract class KoolanScreen {}

class HomeScreenRoute extends KoolanScreen {}

class SavedScreenRoute extends KoolanScreen {}

class MessagesScreenRoute extends KoolanScreen {}

class ProfileScreenRoute extends KoolanScreen {}

class CategoryListScreenRoute extends KoolanScreen {
  final String category;
  CategoryListScreenRoute(this.category);
}

class ListingDetailScreenRoute extends KoolanScreen {
  final int listingId;
  ListingDetailScreenRoute(this.listingId);
}

class PostWizardScreenRoute extends KoolanScreen {}

class ActiveChatScreenRoute extends KoolanScreen {
  final int sessionIndex;
  ActiveChatScreenRoute(this.sessionIndex);
}

class SettingsScreenRoute extends KoolanScreen {}

// ==========================================
// APPLICATION STATE MANAGEMENT (VIEWMODEL PORT)
// ==========================================
class KoolanAppState extends ChangeNotifier {
  // Navigation stack
  final List<KoolanScreen> navigationStack = [HomeScreenRoute()];

  // Locale — "en" (English) or "am" (Amharic)
  String locale = "en";
  AppStrings get s => AppStrings(locale);

  void toggleLocale() {
    locale = locale == "en" ? "am" : locale == "am" ? "so" : "en";
    notifyListeners();
  }

  // Filter & Queries
  String selectedCategory = "ALL";
  String searchQuery = "";

  // Comparison State
  bool compareModeEnabled = false;
  Set<int> selectedCompareIds = {};

  // Database of listings
  List<Listing> allListings = [];

  // Active Chats
  List<ChatSession> chatSessions = [];

  // Wizard state
  int postStep = 1;
  String postCategory = "CARS";
  String postTitle = "";
  String postPrice = "";
  String postDescription = "";
  String postLocation = "Kebele 06";
  String postPhysicalAddress = "";
  bool postMainPhotoAttached = false;

  String postSpec1 = "";
  String postSpec2 = "";
  String postSpec3 = "";
  String postSpec4 = "";

  KoolanAppState() {
    _prepopulate();
  }

  void _prepopulate() {
    allListings = [
      // LAND LISTINGS
      Listing(
        id: 1,
        category: "LAND",
        title: "Residential Plot in Kebele 02",
        price: "ETB 4,200,000",
        imageUrl: "https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=500&q=80",
        location: "Kebele 02, Jigjiga, Somali Region",
        verified: true,
        isSaved: false,
        conditionOrStatus: "For Sale",
        sellerName: "Ahmed Mohammed",
        sellerRating: 4.9,
        sellerReviewsCount: 124,
        sellerImage: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80",
        description: "A wide angle high-resolution photograph of a vast, flat residential land plot in Jigjiga under a clear blue sky. The soil is rich and reddish-brown, typical of the Somali region. In the background, modern low-rise buildings and local acacia trees define the horizon. The lighting is bright and crisp, emphasizing the expansive development potential of the property. Located in the popular and rapidly developing Kebele 02 neighborhood of Jigjiga, perfect for family homes or commercial development.",
        spec1Label: "Size",
        spec1Value: "1000 sqm",
        spec2Label: "Land Use",
        spec2Value: "Residential",
        spec3Label: "Title Deed",
        spec3Value: "Available",
        spec4Label: "Road Access",
        spec4Value: "Yes (12m)"
      ),
      Listing(
        id: 2,
        category: "LAND",
        title: "Agricultural Plot in Tuli-Guled",
        price: "\$28,500",
        imageUrl: "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=500&q=80",
        location: "Tuli-Guled, Fafan",
        verified: false,
        isSaved: false,
        conditionOrStatus: "For Sale",
        sellerName: "Ahmed Nur",
        sellerRating: 4.8,
        sellerReviewsCount: 31,
        sellerImage: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80",
        description: "A lush green agricultural plot at golden hour, featuring neat rows of tilled soil and a small modern storage shed. The lighting is warm and cinematic, highlighting the rich texture of the earth. Perfect fertile land in the Fafan zone with rich soil and reliable irrigation options.",
        spec1Label: "Size",
        spec1Value: "2.5 hectares",
        spec2Label: "Land Use",
        spec2Value: "Agricultural",
        spec3Label: "Title Deed",
        spec3Value: "Pending",
        spec4Label: "Road Access",
        spec4Value: "Yes"
      ),
      Listing(
        id: 3,
        category: "LAND",
        title: "Commercial Highway Plot",
        price: "\$450,000",
        imageUrl: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=500&q=80",
        location: "Qabribayah Road, Jigjiga",
        verified: true,
        isSaved: false,
        conditionOrStatus: "For Sale",
        sellerName: "Ahmed Mohammed",
        sellerRating: 4.9,
        sellerReviewsCount: 124,
        sellerImage: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80",
        description: "A wide-angle photograph of a level commercial plot located next to a paved modern highway in a growing urban area. Bright, midday daylight creates deep contrast and a sense of transparency. Outstanding visibility, ideal for gas stations, logistics, warehouses or multi-story commercial facilities.",
        spec1Label: "Size",
        spec1Value: "4,800 sqm",
        spec2Label: "Land Use",
        spec2Value: "Commercial",
        spec3Label: "Title Deed",
        spec3Value: "Available",
        spec4Label: "Road Access",
        spec4Value: "Direct Highway"
      ),

      // CAR LISTINGS
      Listing(
        id: 4,
        category: "CARS",
        title: "2022 Toyota Land Cruiser Prado",
        price: "\$42,500",
        imageUrl: "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80",
        location: "Downtown, Jigjiga",
        verified: true,
        isSaved: false,
        conditionOrStatus: "For Sale",
        sellerName: "Ahmed Nur",
        sellerRating: 4.9,
        sellerReviewsCount: 124,
        sellerImage: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80",
        description: "A sleek, metallic charcoal gray luxury SUV Toyota Land Cruiser Prado TXL in mint condition. Ideal for Somali terrain. Fully loaded with modern options, dual zone A/C, leather seats, and high clearance.",
        spec1Label: "Year",
        spec1Value: "2022",
        spec2Label: "Mileage",
        spec2Value: "12,400 km",
        spec3Label: "Transmission",
        spec3Value: "Automatic",
        spec4Label: "Fuel Type",
        spec4Value: "Petrol"
      ),
      Listing(
        id: 5,
        category: "CARS",
        title: "2021 Hyundai Sonata Limited",
        price: "\$28,900",
        imageUrl: "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=500&q=80",
        location: "Airport Rd, Jigjiga",
        verified: true,
        isSaved: false,
        conditionOrStatus: "For Sale",
        sellerName: "Ahmed Nur",
        sellerRating: 4.8,
        sellerReviewsCount: 31,
        sellerImage: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80",
        description: "A pristine white executive sedan with panorama sunroof, smart adaptive cruise control, lane assist and luxurious driving ergonomics. Fuel efficient and comfortable.",
        spec1Label: "Year",
        spec1Value: "2021",
        spec2Label: "Mileage",
        spec2Value: "28,000 km",
        spec3Label: "Transmission",
        spec3Value: "Automatic",
        spec4Label: "Fuel Type",
        spec4Value: "Petrol"
      ),
      Listing(
        id: 6,
        category: "CARS",
        title: "2021 Toyota Hilux 2.8 GD-6 Raider",
        price: "\$42,500",
        imageUrl: "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80",
        location: "Jigjiga Central, Somali Region",
        verified: true,
        isSaved: false,
        conditionOrStatus: "Good Condition",
        sellerName: "Ahmed Nur",
        sellerRating: 4.9,
        sellerReviewsCount: 124,
        sellerImage: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80",
        description: "Extremely well-maintained 2021 Toyota Hilux. Single owner since new, full service history at certified Toyota dealers. This Raider edition comes with a premium leather interior, advanced safety features, and a high-performance diesel engine. Perfect for both urban commuting and rugged terrain. Recently serviced at 42k km. No accidents, original paint.",
        spec1Label: "Year",
        spec1Value: "2021",
        spec2Label: "Mileage",
        spec2Value: "45,000 km",
        spec3Label: "Transmission",
        spec3Value: "Automatic",
        spec4Label: "Fuel Type",
        spec4Value: "Diesel"
      ),

      // HOUSES LISTINGS
      Listing(
        id: 7,
        category: "HOUSES",
        title: "Modern 4-Bedroom Villa",
        price: "\$145,000",
        imageUrl: "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=500&q=80",
        location: "Kebele 04, Jigjiga",
        verified: true,
        isSaved: false,
        conditionOrStatus: "For Sale",
        sellerName: "Ahmed Abdullahi",
        sellerRating: 4.8,
        sellerReviewsCount: 124,
        sellerImage: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80",
        description: "A stunning ultra-modern villa in Jigjiga with clean white geometric lines, large floor-to-ceiling glass windows, and a lush private courtyard. The scene is shot during golden hour with warm sunlight hitting the facade, creating long shadows. High-end architectural photography, luxury finishes.",
        spec1Label: "Bedrooms",
        spec1Value: "4 Bed",
        spec2Label: "Bathrooms",
        spec2Value: "3 Bath",
        spec3Label: "Area",
        spec3Value: "350 m²",
        spec4Label: "Security",
        spec4Value: "24/7"
      ),
      Listing(
        id: 8,
        category: "HOUSES",
        title: "Elite Studio Loft",
        price: "\$450 /mo",
        imageUrl: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=500&q=80",
        location: "City Center, Jigjiga",
        verified: true,
        isSaved: false,
        conditionOrStatus: "For Rent",
        sellerName: "Ahmed Abdullahi",
        sellerRating: 4.8,
        sellerReviewsCount: 124,
        sellerImage: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80",
        description: "A minimalist luxury studio apartment interior in a high-rise building in Jigjiga. Polished concrete floors, elegant contemporary furniture in shades of charcoal and deep blue, and a large window overlooking the city skyline.",
        spec1Label: "Bedrooms",
        spec1Value: "1 Bed",
        spec2Label: "Bathrooms",
        spec2Value: "1 Bath",
        spec3Label: "Area",
        spec3Value: "65 m²",
        spec4Label: "Security",
        spec4Value: "24/7"
      ),

      // SKILLS LISTINGS (WORKERS)
      Listing(
        id: 9,
        category: "SKILLS",
        title: "Marcus Chen",
        price: "\$45 /hr",
        imageUrl: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=500&q=80",
        location: "Silver Valley • 1.2 km away",
        verified: true,
        isSaved: false,
        conditionOrStatus: "Available",
        sellerName: "Marcus Chen",
        sellerRating: 4.9,
        sellerReviewsCount: 120,
        sellerImage: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=150&q=80",
        description: "A professional male electrician with over 5 years of experience. He is dedicated to thorough residential wiring, appliance setups, testing, and trouble-shooting.",
        spec1Label: "Category",
        spec1Value: "Electrician",
        spec2Label: "Experience",
        spec2Value: "5 years",
        spec3Label: "Skills",
        spec3Value: "Wiring, Troubleshooting",
        spec4Label: "Verified",
        spec4Value: "Yes"
      ),
      Listing(
        id: 10,
        category: "SKILLS",
        title: "Hodan Ahmed",
        price: "Unlock for 30 ETB",
        imageUrl: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=500&q=80",
        location: "Kebele 03, Jigjiga",
        verified: true,
        isSaved: false,
        conditionOrStatus: "Available",
        sellerName: "Hodan Ahmed",
        sellerRating: 5.0,
        sellerReviewsCount: 48,
        sellerImage: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80",
        description: "Dedicated and thorough professional specializing in comprehensive household management. Known for attention to detail, punctuality, and a trust-first approach in every home I serve in Jigjiga.",
        spec1Label: "Category",
        spec1Value: "House Help",
        spec2Label: "Experience",
        spec2Value: "2 years",
        spec3Label: "Skills",
        spec3Value: "Deep Cleaning, Cooking, Laundry, Organization",
        spec4Label: "Verified",
        spec4Value: "Koolan Verified"
      )
    ];

    chatSessions = [
      ChatSession(
        partnerName: "Ahmed Nur",
        partnerAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80",
        listingTitle: "2021 Toyota Hilux 2.8 GD-6 Raider",
        messages: [
          ChatMessage(sender: "Ahmed Nur", text: "Hello, are you still interested in the Toyota Hilux?", timestamp: "09:30 AM", isMe: false),
          ChatMessage(sender: "Me", text: "Yes! Is the price negotiable?", timestamp: "09:32 AM", isMe: true),
          ChatMessage(sender: "Ahmed Nur", text: "We can discuss a small discount. Are you available for viewing today?", timestamp: "09:33 AM", isMe: false)
        ],
        unreadCount: 1
      ),
      ChatSession(
        partnerName: "Ahmed Mohammed",
        partnerAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80",
        listingTitle: "Residential Plot in Kebele 02",
        messages: [
          ChatMessage(sender: "Ahmed Mohammed", text: "Welcome! The land deed is fully verified with the local authorities.", timestamp: "Yesterday", isMe: false)
        ],
        unreadCount: 0
      )
    ];
  }

  // Navigation actions
  void pushScreen(KoolanScreen screen) {
    navigationStack.add(screen);
    notifyListeners();
  }

  void popScreen() {
    if (navigationStack.size > 1) {
      navigationStack.removeLast();
      notifyListeners();
    }
  }

  void switchTab(KoolanScreen rootTab) {
    navigationStack.clear();
    navigationStack.add(HomeScreenRoute()); // Home is our anchor
    if (rootTab is! HomeScreenRoute) {
      navigationStack.add(rootTab);
    }
    notifyListeners();
  }

  // Filter actions
  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  List<Listing> getFilteredListings() {
    return allListings.where((listing) {
      final matchesCategory = selectedCategory == "ALL" || listing.category == selectedCategory;
      final matchesQuery = searchQuery.isEmpty ||
          listing.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          listing.location.toLowerCase().contains(searchQuery.toLowerCase()) ||
          listing.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Listing> getSavedListings() {
    return allListings.where((listing) => listing.isSaved).toList();
  }

  // Save / Bookmark
  void toggleSaveListing(int listingId) {
    final index = allListings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      final listing = allListings[index];
      allListings[index] = listing.copyWith(isSaved: !listing.isSaved);
      notifyListeners();
    }
  }

  // Comparison logic
  void toggleCompareMode() {
    compareModeEnabled = !compareModeEnabled;
    if (!compareModeEnabled) {
      selectedCompareIds.clear();
    }
    notifyListeners();
  }

  void toggleCompareSelection(int id) {
    if (selectedCompareIds.contains(id)) {
      selectedCompareIds.remove(id);
    } else {
      if (selectedCompareIds.length < 2) {
        selectedCompareIds.add(id);
      }
    }
    notifyListeners();
  }

  // Chat logic
  void sendChatMessage(int sessionIndex, String text) {
    if (text.trim().isEmpty) return;
    final session = chatSessions[sessionIndex];
    final updatedMsgs = List<ChatMessage>.from(session.messages)
      ..add(ChatMessage(sender: "Me", text: text, timestamp: "Just now", isMe: true));
    chatSessions[sessionIndex] = session.copyWith(messages: updatedMsgs, unreadCount: 0);
    notifyListeners();
  }

  // Wizard logic
  void resetWizard() {
    postStep = 1;
    postTitle = "";
    postPrice = "";
    postDescription = "";
    postPhysicalAddress = "";
    postMainPhotoAttached = false;
    postSpec1 = "";
    postSpec2 = "";
    postSpec3 = "";
    postSpec4 = "";
    notifyListeners();
  }

  void submitPost() {
    final titleStr = postTitle.trim().isEmpty ? "Untitled $postCategory Listing" : postTitle.trim();
    final priceStr = postPrice.trim().isEmpty ? "Contact for price" : (postPrice.startsWith("ETB") || postPrice.startsWith("\$") ? postPrice.trim() : "ETB ${postPrice.trim()}");
    final descStr = postDescription.trim().isEmpty ? "No description provided." : postDescription.trim();

    final imageStr = postCategory == "CARS"
        ? "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80"
        : postCategory == "HOUSES"
            ? "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=500&q=80"
            : postCategory == "LAND"
                ? "https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=500&q=80"
                : "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=500&q=80";

    final l1 = postCategory == "CARS" ? "Year" : postCategory == "HOUSES" ? "Bedrooms" : postCategory == "LAND" ? "Size" : "Category";
    final v1 = postSpec1.trim().isEmpty ? (postCategory == "CARS" ? "2023" : postCategory == "HOUSES" ? "3 Bed" : postCategory == "LAND" ? "500 sqm" : "Worker") : postSpec1.trim();

    final l2 = postCategory == "CARS" ? "Mileage" : postCategory == "HOUSES" ? "Bathrooms" : postCategory == "LAND" ? "Land Use" : "Experience";
    final v2 = postSpec2.trim().isEmpty ? (postCategory == "CARS" ? "5,000 km" : postCategory == "HOUSES" ? "2 Bath" : postCategory == "LAND" ? "Residential" : "3 years") : postSpec2.trim();

    final l3 = postCategory == "CARS" ? "Transmission" : postCategory == "HOUSES" ? "Area" : postCategory == "LAND" ? "Title Deed" : "Skills";
    final v3 = postSpec3.trim().isEmpty ? (postCategory == "CARS" ? "Automatic" : postCategory == "HOUSES" ? "150m²" : postCategory == "LAND" ? "Available" : "General Support") : postSpec3.trim();

    final l4 = postCategory == "CARS" ? "Fuel Type" : postCategory == "HOUSES" ? "Security" : postCategory == "LAND" ? "Road Access" : "Status";
    final v4 = postSpec4.trim().isEmpty ? (postCategory == "CARS" ? "Petrol" : postCategory == "HOUSES" ? "24/7" : postCategory == "LAND" ? "Yes" : "Verified") : postSpec4.trim();

    final newListing = Listing(
      id: allListings.length + 1,
      category: postCategory,
      title: titleStr,
      price: priceStr,
      imageUrl: imageStr,
      location: "${postLocation.trim()}, Jigjiga",
      verified: true,
      isSaved: false,
      conditionOrStatus: "Available",
      sellerName: "Hodan Ahmed (Me)",
      sellerRating: 5.0,
      sellerReviewsCount: 1,
      sellerImage: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80",
      description: descStr,
      spec1Label: l1,
      spec1Value: v1,
      spec2Label: l2,
      spec2Value: v2,
      spec3Label: l3,
      spec3Value: v3,
      spec4Label: l4,
      spec4Value: v4,
      isCustom: true,
    );

    allListings.insert(0, newListing);
    resetWizard();
    selectedCategory = postCategory; // open the category list

    // Clear route and push CategoryList
    navigationStack.clear();
    navigationStack.add(HomeScreenRoute());
    navigationStack.add(CategoryListScreenRoute(postCategory));
    notifyListeners();
  }
}

// Helper to make it accessible everywhere in the tree
class KoolanAppStateScope extends InheritedNotifier<KoolanAppState> {
  const KoolanAppStateScope({
    super.key,
    required KoolanAppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static KoolanAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<KoolanAppStateScope>();
    assert(scope != null, "No KoolanAppStateScope found in context");
    return scope!.notifier!;
  }
}

// Extension for list utilities
extension ListSize<E> on List<E> {
  int get size => length;
}

// ==========================================
// CORE APP ENTRY
// ==========================================
class KoolanApp extends StatelessWidget {
  const KoolanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koolan - Jigjiga Marketplace',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
          primary: kPrimary,
          onPrimary: kOnPrimary,
          primaryContainer: kPrimaryContainer,
          onPrimaryContainer: kOnPrimaryContainer,
          secondary: kSecondary,
          onSecondary: kOnSecondary,
          secondaryContainer: kSecondaryContainer,
          onSecondaryContainer: kOnSecondaryContainer,
          tertiary: kTertiary,
          onTertiary: kOnTertiary,
          tertiaryContainer: kTertiaryContainer,
          onTertiaryContainer: kOnTertiaryContainer,
          error: kError,
          onError: kOnError,
          errorContainer: kErrorContainer,
          onErrorContainer: kOnErrorContainer,
          background: kBackground,
          onBackground: kOnBackground,
          surface: kSurface,
          onSurface: kOnSurface,
          surfaceVariant: kSurfaceVariant,
          onSurfaceVariant: kOnSurfaceVariant,
          outline: kOutline,
          outlineVariant: kOutlineVariant,
        ),
        fontFamily: 'Inter',
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late KoolanAppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = KoolanAppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KoolanAppStateScope(
      notifier: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          final currentScreen = _appState.navigationStack.last;
          final hideBottomBar = currentScreen is PostWizardScreenRoute || currentScreen is ActiveChatScreenRoute;

          // Responsive Framing: Center app in a clean card on wider screens (Desktop Web)
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final appWidget = Scaffold(
                bottomNavigationBar: hideBottomBar
                    ? null
                    : KoolanBottomNavBar(
                        currentScreen: currentScreen,
                        onTabSelect: (target) {
                          _appState.switchTab(target);
                        },
                        onPostFABClick: () {
                          _appState.pushScreen(PostWizardScreenRoute());
                        },
                      ),
                body: SafeArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildScreenWidget(currentScreen),
                  ),
                ),
              );

              if (isWide) {
                return Container(
                  color: const Color(0xFFE2E8F0),
                  alignment: Alignment.center,
                  child: Container(
                    width: 480,
                    height: 850,
                    decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: appWidget,
                  ),
                );
              }

              return appWidget;
            },
          );
        },
      ),
    );
  }

  Widget _buildScreenWidget(KoolanScreen screen) {
    if (screen is HomeScreenRoute) {
      return HomeScreen(key: const ValueKey('home'));
    } else if (screen is SavedScreenRoute) {
      return SavedScreen(key: const ValueKey('saved'));
    } else if (screen is MessagesScreenRoute) {
      return MessagesScreen(key: const ValueKey('messages'));
    } else if (screen is ProfileScreenRoute) {
      return ProfileScreen(key: const ValueKey('profile'));
    } else if (screen is CategoryListScreenRoute) {
      return CategoryListScreen(categoryName: screen.category, key: ValueKey('cat_${screen.category}'));
    } else if (screen is ListingDetailScreenRoute) {
      return ListingDetailScreen(listingId: screen.listingId, key: ValueKey('detail_${screen.listingId}'));
    } else if (screen is PostWizardScreenRoute) {
      return PostWizardScreen(key: const ValueKey('wizard'));
    } else if (screen is ActiveChatScreenRoute) {
      return ActiveChatScreen(sessionIndex: screen.sessionIndex, key: ValueKey('chat_${screen.sessionIndex}'));
    } else if (screen is SettingsScreenRoute) {
      return SettingsScreen(key: const ValueKey('settings'));
    }
    return const SizedBox();
  }
}

// ==========================================
// BOTTOM NAVIGATION BAR
// ==========================================
class KoolanBottomNavBar extends StatelessWidget {
  final KoolanScreen currentScreen;
  final Function(KoolanScreen) onTabSelect;
  final VoidCallback onPostFABClick;

  const KoolanBottomNavBar({
    super.key,
    required this.currentScreen,
    required this.onTabSelect,
    required this.onPostFABClick,
  });

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final items = [
      _BottomItem(state.s.navHome, Icons.home_outlined, Icons.home, HomeScreenRoute()),
      _BottomItem(state.s.navSaved, Icons.bookmark_border, Icons.bookmark, SavedScreenRoute()),
      _BottomItem(state.s.navPost, Icons.add, Icons.add, PostWizardScreenRoute(), isFAB: true),
      _BottomItem(state.s.navMessages, Icons.chat_bubble_outline, Icons.chat_bubble, MessagesScreenRoute()),
      _BottomItem(state.s.navProfile, Icons.person_outline, Icons.person, ProfileScreenRoute()),
    ];

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: kSurfaceContainerLowest,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final isSelected = _checkSelected(item.route);

          if (item.isFAB) {
            return InkWell(
              onTap: onPostFABClick,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: kPrimaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            );
          }

          return Expanded(
            child: InkWell(
              onTap: () => onTabSelect(item.route),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.unselectedIcon,
                    color: isSelected ? kPrimary : kOnSurfaceVariant.withOpacity(0.6),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? kPrimary : kOnSurfaceVariant.withOpacity(0.6),
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _checkSelected(KoolanScreen route) {
    if (route is HomeScreenRoute) {
      return currentScreen is HomeScreenRoute || currentScreen is CategoryListScreenRoute;
    }
    if (route is SavedScreenRoute) {
      return currentScreen is SavedScreenRoute;
    }
    if (route is MessagesScreenRoute) {
      return currentScreen is MessagesScreenRoute || currentScreen is ActiveChatScreenRoute;
    }
    if (route is ProfileScreenRoute) {
      return currentScreen is ProfileScreenRoute || currentScreen is SettingsScreenRoute;
    }
    return false;
  }
}

class _BottomItem {
  final String label;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final KoolanScreen route;
  final bool isFAB;

  _BottomItem(this.label, this.unselectedIcon, this.selectedIcon, this.route, {this.isFAB = false});
}

// ==========================================
// SCREEN 1: HOME SCREEN
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kOutlineVariant),
                        image: const DecorationImage(
                          image: NetworkImage("https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Koolan",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: kOnSurfaceVariant),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.s.homeNoNotifications)),
                        );
                      },
                    ),
                    // ── Language Toggle Pill ──────────────────────────
                    GestureDetector(
                      onTap: state.toggleLocale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 34,
                        decoration: BoxDecoration(
                          color: kSurfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kOutlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LangPillSegment(
                              label: "EN",
                              isActive: state.locale == "en",
                            ),
                            _LangPillSegment(
                              label: "አማ",
                              isActive: state.locale == "am",
                            ),
                            _LangPillSegment(
                              label: "SO",
                              isActive: state.locale == "so",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Find what you need ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.s.homeGreeting,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: kOnSurface,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2×2 compact category grid
                        Row(
                          children: [
                            Expanded(
                              child: _CompactCategoryCard(
                                title: state.s.homeCategoryCars,
                                subtitle: state.s.isSomali ? "Gawaarida" : "Gawaarida",
                                icon: Icons.directions_car_filled,
                                color: const Color(0xFF1E40AF),
                                onTap: () => state.pushScreen(CategoryListScreenRoute("CARS")),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CompactCategoryCard(
                                title: state.s.homeCategoryHouses,
                                subtitle: "Guryaha",
                                icon: Icons.home_rounded,
                                color: const Color(0xFF0F766E),
                                onTap: () => state.pushScreen(CategoryListScreenRoute("HOUSES")),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactCategoryCard(
                                title: state.s.homeCategoryLand,
                                subtitle: "Dhul",
                                icon: Icons.landscape_rounded,
                                color: const Color(0xFF92400E),
                                onTap: () => state.pushScreen(CategoryListScreenRoute("LAND")),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CompactCategoryCard(
                                title: state.s.homeCategorySkills,
                                subtitle: "Xirfadlayaasha",
                                icon: Icons.construction_rounded,
                                color: const Color(0xFF6D28D9),
                                onTap: () => state.pushScreen(CategoryListScreenRoute("SKILLS")),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Koolan Promo Carousel ────────────────────────────
                  const SizedBox(height: 20),
                  const _PromoCarousel(),

                  // Search Simulator Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: InkWell(
                      onTap: () => state.pushScreen(CategoryListScreenRoute("ALL")),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: kSurfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kOutlineVariant.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: kOnSurfaceVariant),
                            const SizedBox(width: 12),
                            Text(
                              state.s.homeSearchHint,
                              style: TextStyle(
                                fontSize: 14,
                                color: kOnSurfaceVariant.withOpacity(0.6),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Trust strip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.s.homeTrustTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kOnSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(state.s.homeVerifiedStats)),
                                );
                              },
                              child: Text(state.s.homeSeeStats, style: const TextStyle(color: kPrimary)),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _TrustBadgeCard(
                              icon: Icons.home,
                              text: "A homeowner in Kebele 03 just got verified",
                            ),
                            const SizedBox(width: 16),
                            _TrustBadgeCard(
                              icon: Icons.person,
                              text: "A security professional driver just joined",
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  // Recently Added feed
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.s.homeRecentlyAdded,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kOnSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: math.min(state.allListings.length, 3),
                          separatorBuilder: (c, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final listing = state.allListings[index];
                            return _RecentListingCard(
                              listing: listing,
                              onTap: () => state.pushScreen(ListingDetailScreenRoute(listing.id)),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => state.pushScreen(CategoryListScreenRoute("ALL")),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: kOutlineVariant),
                          ),
                          child: Text(state.s.homeViewAll, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show bottom sheet
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return _CategoryPickerSheet(
                onSelect: (cat) {
                  Navigator.pop(context);
                  state.postCategory = cat;
                  state.pushScreen(PostWizardScreenRoute());
                },
              );
            },
          );
        },
        backgroundColor: kPrimaryContainer,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Language pill segment (EN / አማ) ──────────────────────────────────────
class _LangPillSegment extends StatelessWidget {
  final String label;
  final bool isActive;

  const _LangPillSegment({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? kPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive ? kOnPrimary : kOnSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Compact category pill card ──────────────────────────────────────────────
class _CompactCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CompactCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color.withValues(alpha: 1.0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: kOnSurfaceVariant.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Koolan Promo Carousel ───────────────────────────────────────────────────
class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _ctrl = PageController(viewportFraction: 0.88);
  int _page = 0;

  static const _slides = [
    _PromoSlide(
      headline: "Jigjiga's #1\nMarketplace",
      sub: "Buy, sell, and hire in your city — all in one place.",
      accent: Color(0xFF00288E),
      accentLight: Color(0xFF1E40AF),
      icon: Icons.storefront_rounded,
      imageUrl: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=600&q=80",
    ),
    _PromoSlide(
      headline: "Trusted &\nVerified Sellers",
      sub: "Every listing is reviewed. Real IDs, real people.",
      accent: Color(0xFF0F766E),
      accentLight: Color(0xFF14B8A6),
      icon: Icons.verified_user_rounded,
      imageUrl: "https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=600&q=80",
    ),
    _PromoSlide(
      headline: "Post a Listing\nin 60 Seconds",
      sub: "Cars, houses, land or skills — post for free today.",
      accent: Color(0xFF6D28D9),
      accentLight: Color(0xFF8B5CF6),
      icon: Icons.add_circle_rounded,
      imageUrl: "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80",
    ),
    _PromoSlide(
      headline: "Safe Escrow\nPayments",
      sub: "Pay only when you're satisfied. Koolan protects your money.",
      accent: Color(0xFF92400E),
      accentLight: Color(0xFFF59E0B),
      icon: Icons.lock_rounded,
      imageUrl: "https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=600&q=80",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_page + 1) % _slides.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return AnimatedScale(
                scale: _page == index ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _PromoSlideCard(slide: slide),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _page == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _page == i ? kPrimary : kOutlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoSlide {
  final String headline;
  final String sub;
  final Color accent;
  final Color accentLight;
  final IconData icon;
  final String imageUrl;

  const _PromoSlide({
    required this.headline,
    required this.sub,
    required this.accent,
    required this.accentLight,
    required this.icon,
    required this.imageUrl,
  });
}

class _PromoSlideCard extends StatelessWidget {
  final _PromoSlide slide;
  const _PromoSlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo
          Image.network(
            slide.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: slide.accent),
          ),
          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  slide.accent.withValues(alpha: 0.92),
                  slide.accent.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left text block
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(slide.icon, color: Colors.white, size: 13),
                            const SizedBox(width: 5),
                            const Text(
                              "KOOLAN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        slide.headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slide.sub,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Right: decorative icon badge
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Icon(slide.icon, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadgeCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustBadgeCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: kPrimary, size: 18),
              ),
              const Positioned(
                bottom: -2,
                right: -2,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: kVerifiedColor,
                  child: Icon(Icons.check, size: 10, color: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }
}

class _RecentListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _RecentListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      listing.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[300]),
                    ),
                  ),
                  if (listing.verified)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: kVerifiedColor,
                        child: Icon(Icons.check, size: 11, color: Colors.white),
                      ),
                    )
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kOnSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          listing.price,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kPrimary),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: kOutline, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: const TextStyle(fontSize: 12, color: kOutline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                listing.category == "SKILLS" ? "Talk to Seller" : "Call Owner",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kPrimary),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                listing.category == "SKILLS" ? Icons.chat_bubble : Icons.call,
                                color: kPrimary,
                                size: 11,
                              )
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final Function(String) onSelect;

  const _CategoryPickerSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      _PickerOption("Cars", Icons.directions_car, "CARS"),
      _PickerOption("Houses", Icons.home, "HOUSES"),
      _PickerOption("Land", Icons.landscape, "LAND"),
      _PickerOption("Skills", Icons.construction, "SKILLS"),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kOutlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "What would you like to post?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final opt = options[index];
              return Card(
                color: kSurfaceContainerLow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                child: InkWell(
                  onTap: () => onSelect(opt.key),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: kPrimary.withOpacity(0.1),
                        child: Icon(opt.icon, color: kPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(opt.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: kOnSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _PickerOption {
  final String label;
  final IconData icon;
  final String key;
  _PickerOption(this.label, this.icon, this.key);
}

// ==========================================
// SCREEN 2: CATEGORY LIST SCREEN
// ==========================================
class CategoryListScreen extends StatefulWidget {
  final String categoryName;
  const CategoryListScreen({super.key, required this.categoryName});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool verifiedOnly = false;
  String rentBuySelected = "Buy";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = KoolanAppStateScope.of(context);
      state.selectedCategory = widget.categoryName;
      state.searchQuery = "";
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final results = state.getFilteredListings().where((l) => !verifiedOnly || l.verified).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          state.postCategory = widget.categoryName == "ALL" ? "CARS" : widget.categoryName;
          state.pushScreen(PostWizardScreenRoute());
        },
        backgroundColor: kPrimaryContainer,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: kPrimary),
                  onPressed: () => state.popScreen(),
                ),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: kSurfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        state.setSearchQuery(val);
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Search ${widget.categoryName.toLowerCase()}...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // List / Map Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kSurfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text("List", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Text("Map", style: TextStyle(color: kOnSurfaceVariant, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                    // Verified Toggle
                    Row(
                      children: [
                        Text(state.s.catVerifiedOnly, style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant)),
                        const SizedBox(width: 8),
                        Switch(
                          value: verifiedOnly,
                          activeColor: kPrimary,
                          onChanged: (val) {
                            setState(() {
                              verifiedOnly = val;
                            });
                          },
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),

                // Scrolling filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: state.s.isAmharic ? "${state.s.catForRent} / ${state.s.catForSale}" : state.s.isSomali ? "${state.s.catForRent} / ${state.s.catForSale}" : "Rent / Buy",
                        selected: rentBuySelected != "Buy",
                        onTap: () {
                          setState(() {
                            rentBuySelected = rentBuySelected == "Buy" ? "Rent" : "Buy";
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(label: state.s.isAmharic ? "የዋጋ ክልል" : state.s.isSomali ? "Xadka qiimaha" : "Price Range"),
                      const SizedBox(width: 8),
                      if (widget.categoryName == "HOUSES" || widget.categoryName == "ALL") ...[
                        _FilterChip(label: state.s.isAmharic ? "አልጋ ቤቶች" : state.s.isSomali ? "Qolalka jiifka" : "Bedrooms"),
                        const SizedBox(width: 8),
                      ],
                      if (widget.categoryName == "LAND" || widget.categoryName == "ALL") ...[
                        _FilterChip(label: state.s.isAmharic ? "የመሬት አጠቃቀም" : state.s.isSomali ? "Isticmaalka dhulka" : "Land-use"),
                        const SizedBox(width: 8),
                      ],
                      _FilterChip(label: state.s.isAmharic ? "ተጨማሪ" : state.s.isSomali ? "Wax dheeraad ah" : "More"),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Count Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              "${results.length} results in Jigjiga",
              style: TextStyle(fontSize: 12, color: kOnSurfaceVariant.withOpacity(0.6)),
            ),
          ),

          // Feed List
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: kOnSurfaceVariant.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text("No matching listings found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Try clearing your query filters", style: TextStyle(fontSize: 13, color: kOnSurfaceVariant.withOpacity(0.6))),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: results.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return _PremiumClassifiedCard(
                        listing: item,
                        onSaveToggle: () => state.toggleSaveListing(item.id),
                        onTap: () => state.pushScreen(ListingDetailScreenRoute(item.id)),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterChip({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimaryContainer : kSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.transparent : kOutlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : kOnSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: selected ? Colors.white : kOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _PremiumClassifiedCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const _PremiumClassifiedCard({
    required this.listing,
    required this.onSaveToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    listing.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (listing.verified) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified, color: kVerifiedColor, size: 14),
                                    SizedBox(width: 4),
                                    Text("Verified", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: kPrimaryContainer.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(24)),
                              child: Text(
                                listing.conditionOrStatus,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            )
                          ],
                        ),

                        // Bookmark
                        InkWell(
                          onTap: onSaveToggle,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Icon(
                              listing.isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: listing.isSaved ? Colors.red : kOnSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.price,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPrimary),
                      ),
                      if (listing.isCustom)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text("My Ad", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kOnSurface),
                  ),
                  const SizedBox(height: 12),

                  // Specs Row
                  Row(
                    children: [
                      if (listing.spec1Label != null && listing.spec1Value != null) ...[
                        _SpecIconLabel(label: listing.spec1Value!, icon: _getIconForLabel(listing.spec1Label!)),
                        const SizedBox(width: 16),
                      ],
                      if (listing.spec2Label != null && listing.spec2Value != null) ...[
                        _SpecIconLabel(label: listing.spec2Value!, icon: _getIconForLabel(listing.spec2Label!)),
                        const SizedBox(width: 16),
                      ],
                      if (listing.spec3Label != null && listing.spec3Value != null) ...[
                        _SpecIconLabel(label: listing.spec3Value!, icon: _getIconForLabel(listing.spec3Label!)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F3F9)),
                  const SizedBox(height: 12),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: kOutline, size: 16),
                          const SizedBox(width: 4),
                          Text(listing.location.split(',')[0], style: const TextStyle(fontSize: 13, color: kOnSurfaceVariant)),
                        ],
                      ),
                      const Text("2.4 km away", style: TextStyle(fontSize: 11, color: kSecondary, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SpecIconLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SpecIconLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kOnSurfaceVariant.withOpacity(0.5), size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant)),
      ],
    );
  }
}

IconData _getIconForLabel(String label) {
  switch (label.toLowerCase()) {
    case 'year':
    case 'calendar':
      return Icons.calendar_today;
    case 'mileage':
    case 'speed':
      return Icons.speed;
    case 'transmission':
      return Icons.settings;
    case 'fuel type':
    case 'gas':
      return Icons.local_gas_station;
    case 'bedrooms':
    case 'bed':
      return Icons.bed;
    case 'bathrooms':
    case 'bath':
      return Icons.bathtub;
    case 'area':
    case 'size':
      return Icons.square_foot;
    case 'security':
      return Icons.security;
    case 'land use':
      return Icons.foundation;
    case 'title deed':
      return Icons.description;
    default:
      return Icons.info;
  }
}

// ==========================================
// SCREEN 3: SAVED SCREEN & COMPARISON MODE
// ==========================================
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool showCompareOverlay = false;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final savedListings = state.getSavedListings();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.s.savedTitle,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.compare_arrows, color: kPrimary),
                      onPressed: () => state.toggleCompareMode(),
                      style: IconButton.styleFrom(
                        backgroundColor: state.compareModeEnabled ? kPrimary.withOpacity(0.1) : Colors.transparent,
                      ),
                    )
                  ],
                ),
              ),

              if (savedListings.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: kSurfaceContainerLow,
                            child: Icon(Icons.bookmark_border, size: 48, color: kOnSurfaceVariant.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 16),
                          Text(state.s.savedEmpty, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            "Tap the bookmark icon on any item you love to save it here and keep track of your favorites.",
                            style: TextStyle(fontSize: 13, color: kOnSurfaceVariant.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                if (state.compareModeEnabled)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Select up to 2 items to compare side-by-side. (${state.selectedCompareIds.length}/2 selected)",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: savedListings.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = savedListings[index];
                      final isChosen = state.selectedCompareIds.contains(item.id);

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isChosen && state.compareModeEnabled ? kPrimary : Colors.transparent,
                                width: isChosen && state.compareModeEnabled ? 3 : 0,
                              ),
                            ),
                            child: _PremiumClassifiedCard(
                              listing: item,
                              onSaveToggle: () => state.toggleSaveListing(item.id),
                              onTap: () {
                                if (state.compareModeEnabled) {
                                  state.toggleCompareSelection(item.id);
                                } else {
                                  state.pushScreen(ListingDetailScreenRoute(item.id));
                                }
                              },
                            ),
                          ),
                          if (isChosen && state.compareModeEnabled)
                            const Positioned(
                              top: 12,
                              right: 12,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: kPrimary,
                                child: Icon(Icons.check, size: 16, color: Colors.white),
                              ),
                            )
                        ],
                      );
                    },
                  ),
                )
              ]
            ],
          ),

          // Bottom floating Compare Bar
          if (state.compareModeEnabled && state.selectedCompareIds.isNotEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${state.selectedCompareIds.length} items selected",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            state.selectedCompareIds.length < 2 ? "Choose 1 more item" : "Ready to analyze",
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                          )
                        ],
                      ),
                      ElevatedButton(
                        onPressed: state.selectedCompareIds.length == 2
                            ? () {
                                setState(() {
                                  showCompareOverlay = true;
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryContainer,
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(state.s.savedCompareButton, style: const TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
            ),

          // Comparison Table Overlay
          if (showCompareOverlay && state.selectedCompareIds.length == 2)
            _CompareOverlay(
              listings: savedListings.where((l) => state.selectedCompareIds.contains(l.id)).toList(),
              onClose: () {
                setState(() {
                  showCompareOverlay = false;
                });
              },
            )
        ],
      ),
    );
  }
}

class _CompareOverlay extends StatelessWidget {
  final List<Listing> listings;
  final VoidCallback onClose;

  const _CompareOverlay({required this.listings, required this.onClose});

  @override
  Widget build(BuildContext context) {
    if (listings.length < 2) return const SizedBox();

    final rowSpecs = [
      _CompareRowSpec("Price", (l) => l.price),
      _CompareRowSpec("Location", (l) => l.location.split(',')[0]),
      _CompareRowSpec("Status", (l) => l.conditionOrStatus),
      _CompareRowSpec("Specs 1", (l) => l.spec1Label != null ? "${l.spec1Label}: ${l.spec1Value}" : "N/A"),
      _CompareRowSpec("Specs 2", (l) => l.spec2Label != null ? "${l.spec2Label}: ${l.spec2Value}" : "N/A"),
      _CompareRowSpec("Specs 3", (l) => l.spec3Label != null ? "${l.spec3Label}: ${l.spec3Value}" : "N/A"),
      _CompareRowSpec("Seller", (l) => l.sellerName),
    ];

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Material(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 650),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(KoolanAppStateScope.of(context).s.compareTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                  ],
                ),
                const SizedBox(height: 16),

                // Headers
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(listings[0].imageUrl, height: 70, width: 100, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 4),
                          Text(listings[0].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(listings[1].imageUrl, height: 70, width: 100, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 4),
                          Text(listings[1].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                // Rows
                Expanded(
                  child: ListView.separated(
                    itemCount: rowSpecs.length,
                    separatorBuilder: (c, i) => const Divider(color: Color(0xFFF1F3F9)),
                    itemBuilder: (context, index) {
                      final spec = rowSpecs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                spec.label,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kPrimary),
                              ),
                            ),
                            Expanded(child: Text(spec.mapper(listings[0]), style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(spec.mapper(listings[1]), style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Close Comparison", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareRowSpec {
  final String label;
  final String Function(Listing) mapper;
  _CompareRowSpec(this.label, this.mapper);
}

// ==========================================
// SCREEN 4: DETAILED SCREEN WITH MAP
// ==========================================
class ListingDetailScreen extends StatefulWidget {
  final int listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool isContactUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final listing = state.allListings.firstWhere((l) => l.id == widget.listingId);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Area
                SizedBox(
                  height: 360,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(listing.imageUrl, fit: BoxFit.cover),
                      // Carousel Indicator
                      Positioned(
                        left: 24,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(width: 24, height: 6, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 4),
                              const CircleAvatar(radius: 3, backgroundColor: Colors.white30),
                              const SizedBox(width: 4),
                              const CircleAvatar(radius: 3, backgroundColor: Colors.white30),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text("1 / 3", style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),

                      // Header Actions
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: kPrimary),
                                onPressed: () => state.popScreen(),
                              ),
                            ),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  child: IconButton(
                                    icon: const Icon(Icons.share, color: kPrimary),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Link shared!")),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  child: IconButton(
                                    icon: Icon(
                                      listing.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                      color: listing.isSaved ? Colors.red : kPrimary,
                                    ),
                                    onPressed: () => state.toggleSaveListing(listing.id),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Info Area
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              listing.category == "SKILLS" ? "Verified Skilled Professional" : "Verified Listing",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimary),
                            ),
                          ),
                          Text(
                            listing.price,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimary),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        listing.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kOnSurface),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: kOutline, size: 16),
                          const SizedBox(width: 4),
                          Text(listing.location, style: const TextStyle(color: kOnSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bento grid of specifications
                      Column(
                        children: [
                          Row(
                            children: [
                              if (listing.spec1Label != null && listing.spec1Value != null)
                                Expanded(child: _BentoBox(label: listing.spec1Label!, value: listing.spec1Value!, icon: _getIconForLabel(listing.spec1Label!))),
                              if (listing.spec1Label != null && listing.spec2Label != null) const SizedBox(width: 12),
                              if (listing.spec2Label != null && listing.spec2Value != null)
                                Expanded(child: _BentoBox(label: listing.spec2Label!, value: listing.spec2Value!, icon: _getIconForLabel(listing.spec2Label!))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (listing.spec3Label != null && listing.spec3Value != null)
                                Expanded(child: _BentoBox(label: listing.spec3Label!, value: listing.spec3Value!, icon: _getIconForLabel(listing.spec3Label!))),
                              if (listing.spec3Label != null && listing.spec4Label != null) const SizedBox(width: 12),
                              if (listing.spec4Label != null && listing.spec4Value != null)
                                Expanded(child: _BentoBox(label: listing.spec4Label!, value: listing.spec4Value!, icon: _getIconForLabel(listing.spec4Label!))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(state.s.detailDescription, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        listing.description.isEmpty
                            ? "Dedicated listing in Jigjiga. Authentic and ready for immediate transition."
                            : listing.description,
                        style: const TextStyle(fontSize: 14, color: kOnSurfaceVariant, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Map Custom Painting
                      const Text("Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kOutlineVariant.withOpacity(0.4)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            CustomPaint(
                              painter: MapPainter(kPrimary),
                              child: const SizedBox.expand(),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                color: Colors.white.withOpacity(0.9),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Kebele 06, Jigjiga Central", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Opening Google Maps...")),
                                        );
                                      },
                                      child: const Row(
                                        children: [
                                          Text("Open in Maps", style: TextStyle(fontSize: 12)),
                                          SizedBox(width: 4),
                                          Icon(Icons.open_in_new, size: 12),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Seller profile card
                      Card(
                        color: kSurfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: kOutlineVariant.withOpacity(0.2)),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.s.detailSeller,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kOnSurfaceVariant.withOpacity(0.6)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: NetworkImage(
                                      listing.sellerImage.isEmpty
                                          ? "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80"
                                          : listing.sellerImage,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(listing.sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text("${listing.sellerRating} (${listing.sellerReviewsCount} ${state.s.detailReviews})", style: const TextStyle(fontSize: 12)),
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(state.s.detailProfileVerified)),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: const BorderSide(color: kOutlineVariant),
                                ),
                                child: Text(state.s.detailViewProfile, style: const TextStyle(color: kOnSurface)),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Protected contact details
                      Card(
                        color: kSurfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: kPrimary.withOpacity(0.3)),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Contact Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Icon(Icons.lock, color: kPrimary, size: 28),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Phone numbers and direct emails are protected to avoid phishing/spam. Interact safely using escrow.",
                                style: TextStyle(fontSize: 13, color: kOnSurfaceVariant),
                              ),
                              const SizedBox(height: 16),
                              if (isContactUnlocked) ...[
                                const Text("Phone: +251 91 123 4567", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
                                const SizedBox(height: 4),
                                const Text("Email: contact@jigjigamarketplace.et", style: TextStyle(color: kOnSurfaceVariant)),
                              ] else ...[
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      isContactUnlocked = true;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: kPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.payment, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(state.s.detailUnlockContact, style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white.withOpacity(0.95),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Open Chat! Check if session with this seller exists, or just open first session simulator
                        state.pushScreen(ActiveChatScreenRoute(0));
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: kPrimary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat, color: kPrimary),
                          const SizedBox(width: 8),
                          Text(state.s.detailChat, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Request logged. Partner notified!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            listing.category == "SKILLS" ? state.s.detailRequestHire : state.s.detailViewProperty,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _BentoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BentoBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: kPrimary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: kOnSurfaceVariant)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// Map Custom Painter
class MapPainter extends CustomPainter {
  final Color primaryColor;
  MapPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    final bgPaint = Paint()..color = const Color(0xFFF1F3F5);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw main road (horizontal)
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), roadPaint);

    // Draw dash lines on main road
    double dashWidth = 10;
    double dashSpace = 10;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw cross road (vertical at 1/3 width)
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), roadPaint);

    // Pulser marker rings
    final pulsePaint1 = Paint()..color = primaryColor.withOpacity(0.2);
    final pulsePaint2 = Paint()..color = Colors.white;
    final pulsePaint3 = Paint()..color = primaryColor;

    canvas.drawCircle(Offset(size.width / 3, size.height / 2), 24, pulsePaint1);
    canvas.drawCircle(Offset(size.width / 3, size.height / 2), 8, pulsePaint2);
    canvas.drawCircle(Offset(size.width / 3, size.height / 2), 4, pulsePaint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// SCREEN 5: POST WIZARD SCREEN
// ==========================================
class PostWizardScreen extends StatefulWidget {
  const PostWizardScreen({super.key});

  @override
  State<PostWizardScreen> createState() => _PostWizardScreenState();
}

class _PostWizardScreenState extends State<PostWizardScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      KoolanAppStateScope.of(context).resetWizard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kPrimary),
                    onPressed: () {
                      if (state.postStep > 1) {
                        setState(() {
                          state.postStep--;
                        });
                      } else {
                        state.popScreen();
                      }
                    },
                  ),
                  Text(state.s.wizardTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(
                    "Step ${state.postStep} of 4",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: kOnSurfaceVariant),
                  )
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: state.postStep / 4.0,
                color: kPrimary,
                backgroundColor: kSurfaceContainerHigh,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),

            // Step Content Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStepContent(state),
              ),
            ),

            // Bottom Navigation CTA
            Container(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (state.postStep < 4) {
                      setState(() {
                        state.postStep++;
                      });
                    } else {
                      state.submitPost();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  state.postStep == 4 ? state.s.wizardSubmit : state.s.wizardNext,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(KoolanAppState state) {
    switch (state.postStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Start posting", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              "Select what type of classified ad or worker profile you'd like to list in Jigjiga.",
              style: TextStyle(color: kOnSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _CategorySelectionCard(
              title: "Professional Service",
              desc: "Post a skilled worker profile with verified bio and credentials.",
              icon: Icons.construction,
              isSelected: state.postCategory == "SKILLS",
              onTap: () => setState(() => state.postCategory = "SKILLS"),
            ),
            const SizedBox(height: 16),
            _CategorySelectionCard(
              title: "Vehicles / Cars",
              desc: "Sell or rent out cars, motorbikes, or heavy machinery.",
              icon: Icons.directions_car,
              isSelected: state.postCategory == "CARS",
              onTap: () => setState(() => state.postCategory = "CARS"),
            ),
            const SizedBox(height: 16),
            _CategorySelectionCard(
              title: "Real Estate / Houses",
              desc: "List houses, apartments, villas, or hotel rooms.",
              icon: Icons.home,
              isSelected: state.postCategory == "HOUSES",
              onTap: () => setState(() => state.postCategory = "HOUSES"),
            ),
            const SizedBox(height: 16),
            _CategorySelectionCard(
              title: "Land / Plots",
              desc: "Sell or lease farming fields, residential plots, or commercial sites.",
              icon: Icons.landscape,
              isSelected: state.postCategory == "LAND",
              onTap: () => setState(() => state.postCategory = "LAND"),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Details & Title", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("Provide a title and pricing details for your ad.", style: TextStyle(color: kOnSurfaceVariant)),
            const SizedBox(height: 24),

            // Title
            const Text("Title", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: state.postTitle,
              onChanged: (val) => state.postTitle = val,
              validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
              decoration: InputDecoration(
                hintText: "e.g. Toyota Hilux 2021 Raider",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            const Text("Price / Rate", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: state.postPrice,
              onChanged: (val) => state.postPrice = val,
              validator: (val) => val == null || val.trim().isEmpty ? "Price is required" : null,
              decoration: InputDecoration(
                hintText: "e.g. 4,500,000 or 15,000 /mo",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            const Text("Location Zone", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: state.postLocation,
              items: ["Kebele 01", "Kebele 02", "Kebele 03", "Kebele 04", "Kebele 05", "Kebele 06"]
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (val) => state.postLocation = val ?? "Kebele 06",
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      case 3:
        // Category Specs Step
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Specifications", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("Provide specifications specific to ${state.postCategory.toLowerCase()}.", style: TextStyle(color: kOnSurfaceVariant)),
            const SizedBox(height: 24),

            if (state.postCategory == "CARS") ...[
              _buildWizardField("Year", state.postSpec1, (val) => state.postSpec1 = val, hint: "e.g. 2022"),
              const SizedBox(height: 16),
              _buildWizardField("Mileage", state.postSpec2, (val) => state.postSpec2 = val, hint: "e.g. 12,000 km"),
              const SizedBox(height: 16),
              _buildWizardField("Transmission", state.postSpec3, (val) => state.postSpec3 = val, hint: "Automatic / Manual"),
              const SizedBox(height: 16),
              _buildWizardField("Fuel Type", state.postSpec4, (val) => state.postSpec4 = val, hint: "Petrol / Diesel"),
            ] else if (state.postCategory == "HOUSES") ...[
              _buildWizardField("Bedrooms", state.postSpec1, (val) => state.postSpec1 = val, hint: "e.g. 4 Bed"),
              const SizedBox(height: 16),
              _buildWizardField("Bathrooms", state.postSpec2, (val) => state.postSpec2 = val, hint: "e.g. 3 Bath"),
              const SizedBox(height: 16),
              _buildWizardField("Area size", state.postSpec3, (val) => state.postSpec3 = val, hint: "e.g. 350 m²"),
              const SizedBox(height: 16),
              _buildWizardField("Security", state.postSpec4, (val) => state.postSpec4 = val, hint: "e.g. 24/7"),
            ] else if (state.postCategory == "LAND") ...[
              _buildWizardField("Plot Size", state.postSpec1, (val) => state.postSpec1 = val, hint: "e.g. 1000 sqm"),
              const SizedBox(height: 16),
              _buildWizardField("Land Use", state.postSpec2, (val) => state.postSpec2 = val, hint: "Residential / Agricultural"),
              const SizedBox(height: 16),
              _buildWizardField("Title Deed status", state.postSpec3, (val) => state.postSpec3 = val, hint: "Available / Pending"),
              const SizedBox(height: 16),
              _buildWizardField("Road Access", state.postSpec4, (val) => state.postSpec4 = val, hint: "Yes / No"),
            ] else ...[
              _buildWizardField("Service category", state.postSpec1, (val) => state.postSpec1 = val, hint: "e.g. Electrician"),
              const SizedBox(height: 16),
              _buildWizardField("Years of experience", state.postSpec2, (val) => state.postSpec2 = val, hint: "e.g. 5 years"),
              const SizedBox(height: 16),
              _buildWizardField("Key skills specialty", state.postSpec3, (val) => state.postSpec3 = val, hint: "e.g. Wiring, Repairs"),
              const SizedBox(height: 16),
              _buildWizardField("ID Verification status", state.postSpec4, (val) => state.postSpec4 = val, hint: "Yes / Pending"),
            ]
          ],
        );
      default:
        // Step 4: Description & Attachments
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Finalize Post", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("Write a detailed description and attach media files.", style: TextStyle(color: kOnSurfaceVariant)),
            const SizedBox(height: 24),

            // Description
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: state.postDescription,
              onChanged: (val) => state.postDescription = val,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Briefly explain condition, location merits, and escrow preferences...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Attachment Simulation Box
            Card(
              color: kSurfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: kOutlineVariant.withValues(alpha: 0.4), style: BorderStyle.solid),
              ),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  setState(() {
                    state.postMainPhotoAttached = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mock photo attached successfully!")),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          state.postMainPhotoAttached ? Icons.check_circle : Icons.cloud_upload_outlined,
                          size: 48,
                          color: state.postMainPhotoAttached ? kVerifiedColor : kPrimary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.postMainPhotoAttached ? "1 file attached" : "Attach media files",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "JPG, PNG, MP4 up to 50MB",
                          style: TextStyle(fontSize: 12, color: kOnSurfaceVariant.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        );
    }
  }

  Widget _buildWizardField(String label, String value, Function(String) onChanged, {required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _CategorySelectionCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategorySelectionCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isSelected ? kPrimary.withOpacity(0.05) : kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? kPrimary : kOutlineVariant.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isSelected ? kPrimary : kSurfaceContainerHigh,
                child: Icon(icon, color: isSelected ? Colors.white : kPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 6 & 7: MESSAGES & CHAT SCREEN
// ==========================================
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final sessions = state.chatSessions;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.s.messagesTitle,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kOnSurface),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: kPrimary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Chat list updated")),
                    );
                  },
                )
              ],
            ),
          ),

          // Search messages
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: kSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kOutlineVariant.withOpacity(0.5)),
              ),
              child: const TextField(
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search messages...",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filters Quick Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _QuickFilterChip(label: "All", isSelected: true),
                const SizedBox(width: 10),
                _QuickFilterChip(label: "Unread", isSelected: false),
                const SizedBox(width: 10),
                _QuickFilterChip(label: "Archived", isSelected: false),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chat Sessions List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: sessions.length,
              separatorBuilder: (c, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final lastMsg = session.messages.lastOrNull;
                final isOnline = index % 2 == 0;

                return Card(
                  elevation: 0,
                  color: kSurfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
                  ),
                  child: InkWell(
                    onTap: () => state.pushScreen(ActiveChatScreenRoute(index)),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 27,
                                backgroundImage: NetworkImage(session.partnerAvatar),
                              ),
                              if (isOnline)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: kVerifiedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                )
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      session.partnerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      lastMsg?.timestamp ?? "Just now",
                                      style: TextStyle(fontSize: 11, color: kOnSurfaceVariant.withOpacity(0.6)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  session.listingTitle,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastMsg?.text ?? "No messages yet",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: session.unreadCount > 0 ? kOnSurface : kOnSurfaceVariant,
                                    fontWeight: session.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),
                          if (session.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: kPrimary,
                              child: Text(
                                session.unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _QuickFilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? kPrimary : kSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : kOnSurfaceVariant,
        ),
      ),
    );
  }
}

// Active Chat View Screen
class ActiveChatScreen extends StatefulWidget {
  final int sessionIndex;
  const ActiveChatScreen({super.key, required this.sessionIndex});

  @override
  State<ActiveChatScreen> createState() => _ActiveChatScreenState();
}

class _ActiveChatScreenState extends State<ActiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final session = state.chatSessions[widget.sessionIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => state.popScreen(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(session.partnerAvatar),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.partnerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    session.listingTitle,
                    style: const TextStyle(fontSize: 10, color: kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            )
          ],
        ),
        backgroundColor: kSurfaceContainerLowest,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Message stream
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: session.messages.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final msg = session.messages[index];
                return _ChatBubble(msg: msg);
              },
            ),
          ),

          // Text Field Panel
          Container(
            color: kSurfaceContainerLowest,
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: state.s.chatInputHint,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: kPrimary,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          state.sendChatMessage(widget.sessionIndex, _messageController.text);
                          _messageController.clear();
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;

  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = msg.isMe ? kPrimaryContainer : kSurfaceContainerHigh;
    final textColor = msg.isMe ? Colors.white : kOnSurface;
    final alignment = msg.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final textAlignment = msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: textAlignment,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                bottomRight: Radius.circular(msg.isMe ? 4 : 16),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            msg.timestamp,
            style: TextStyle(fontSize: 10, color: kOnSurfaceVariant.withOpacity(0.5)),
          )
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 8: PROFILE SCREEN
// ==========================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String activeTab = "Services";

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final myListings = state.allListings.where((l) => l.isCustom || l.sellerName.contains("Me")).toList();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner & Overlay Settings
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80",
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => state.pushScreen(SettingsScreenRoute()),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Profile info block
            Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Avatar
                    const CircleAvatar(
                      radius: 56,
                      backgroundColor: kBackground,
                      child: CircleAvatar(
                        radius: 52,
                        backgroundImage: NetworkImage(
                          "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Hodan Ahmed",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kOnSurface),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.verified, color: kVerifiedColor, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Role
                    const Text(
                      "Professional Housekeeper & Plumber",
                      style: TextStyle(fontWeight: FontWeight.w600, color: kPrimary),
                    ),
                    const SizedBox(height: 4),

                    const Text(
                      "Kebele 06, Jigjiga • Joined Dec 2024",
                      style: TextStyle(color: kOnSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Stats card
                    Card(
                      color: kSurfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                    SizedBox(width: 4),
                                    Text("5.0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Text("12 Reviews", style: TextStyle(fontSize: 10, color: kOnSurfaceVariant)),
                              ],
                            ),
                            Container(width: 1, height: 30, color: kOutlineVariant.withOpacity(0.3)),
                            const Column(
                              children: [
                                Text("47", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Jobs Done", style: TextStyle(fontSize: 10, color: kOnSurfaceVariant)),
                              ],
                            ),
                            Container(width: 1, height: 30, color: kOutlineVariant.withOpacity(0.3)),
                            const Column(
                              children: [
                                Text("100%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kVerifiedColor)),
                                Text("Response Rate", style: TextStyle(fontSize: 10, color: kOnSurfaceVariant)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tabs
                    Row(
                      children: ["Services", "About", "Reviews"].map((tabName) {
                        final isSel = activeTab == tabName;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  activeTab = tabName;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSel ? kPrimary : kSurfaceContainerHigh,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              child: Text(
                                tabName,
                                style: TextStyle(
                                  color: isSel ? Colors.white : kOnSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Tab Content
                    _buildProfileTabContent(state, myListings),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTabContent(KoolanAppState state, List<Listing> myListings) {
    if (activeTab == "Services") {
      if (myListings.isEmpty) {
        return Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: kPrimary.withOpacity(0.05),
              child: const Icon(Icons.work_outline, size: 36, color: kPrimary),
            ),
            const SizedBox(height: 16),
            const Text("No services posted yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              "Tap the central + button to publish your professional service ad instantly.",
              style: TextStyle(color: kOnSurfaceVariant.withOpacity(0.6), fontSize: 13),
              textAlign: TextAlign.center,
            )
          ],
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: myListings.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = myListings[index];
          return Card(
            color: kSurfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
            ),
            elevation: 0,
            child: InkWell(
              onTap: () => state.pushScreen(ListingDetailScreenRoute(item.id)),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(item.imageUrl, width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(item.price, style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: kPrimary, size: 14),
                              const SizedBox(width: 4),
                              Text(item.location.split(',')[0], style: const TextStyle(color: kOnSurfaceVariant, fontSize: 11)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: kOnSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else if (activeTab == "About") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Professional Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            "Highly skilled and dependable professional offering comprehensive housekeeper, catering, and plumbing support. Over 4 years of verified experience assisting private homes and business complexes in Jigjiga.",
            style: TextStyle(color: kOnSurfaceVariant, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Escrow safety wallet card
          Card(
            color: kSurfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield, color: kVerifiedColor),
                          SizedBox(width: 8),
                          Text("Escrow Safety Vault", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      Text("Active", style: TextStyle(color: kVerifiedColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Secured Escrow Wallet", style: TextStyle(color: kOnSurfaceVariant, fontSize: 13)),
                      Text("15,400 ETB", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Specialties tags
          const Text("Verified Specialties", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ["Residential Plumbing", "Deep Cleaning", "Emergency Repairs", "Meal Preparation", "Bilingual Support"].map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 11),
                ),
              );
            }).toList(),
          )
        ],
      );
    } else {
      // Reviews Tab
      return Column(
        children: [
          _ReviewCard(
            name: "Ahmed Mohammed",
            date: "2 days ago",
            comment: "Hodan was absolutely amazing! Fixed a complicated plumbing issue in our house within an hour. Extremely professional and courteous.",
          ),
          const SizedBox(height: 16),
          _ReviewCard(
            name: "Hodan Ali",
            date: "1 week ago",
            comment: "Great cleaning service, left the house sparkling and clean. Will definitely hire her again next month!",
          ),
        ],
      );
    }
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String date;
  final String comment;

  const _ReviewCard({required this.name, required this.date, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: kPrimary.withOpacity(0.1),
                      child: Text(name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(date, style: TextStyle(fontSize: 10, color: kOnSurfaceVariant.withOpacity(0.6))),
                      ],
                    )
                  ],
                ),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text("5.0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(fontSize: 13, color: kOnSurfaceVariant, height: 1.4),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 9: SETTINGS SCREEN
// ==========================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkModeEnabled = false;
  bool notificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => state.popScreen(),
        ),
        title: Text(state.s.settingsTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: kBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(state.s.isAmharic ? "የሂሳብ ቅንብሮች" : state.s.isSomali ? "Dejinta xisaabta" : "Account settings", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 12)),
          const SizedBox(height: 10),
          _SettingsRow(icon: Icons.person, title: state.s.settingsProfile, subtitle: state.s.isAmharic ? "ስም፣ ባዮ እና ፎቶ ይቀይሩ" : state.s.isSomali ? "Beddel magaca, xogta" : "Change display name, bio, and photos"),
          const SizedBox(height: 10),
          _SettingsRow(icon: Icons.phone, title: state.s.isAmharic ? "ስልክ ማረጋገጫ" : state.s.isSomali ? "Xaqiijinta telefoonka" : "Phone Verification", subtitle: "+251 912 ****90 verified", trailingText: state.s.isAmharic ? "ተረጋግጧል" : state.s.isSomali ? "Xaqiijiyey" : "Verified"),
          const SizedBox(height: 10),
          _SettingsRow(icon: Icons.work, title: state.s.isAmharic ? "ተመራጭ ምድብ" : state.s.isSomali ? "Qaybta la doortay" : "Preferred Category", subtitle: state.s.isAmharic ? "የቤት ውስጥ አገልግሎቶች" : state.s.isSomali ? "Adeegyada guriga" : "Selected: HOUSEHOLD SERVICES"),
          const SizedBox(height: 24),

          Text(state.s.isAmharic ? "ደህንነት እና ኤስክሮ" : state.s.isSomali ? "Ammaan & Escrow" : "Trust & Escrow Safety", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 12)),
          const SizedBox(height: 10),
          _SettingsRow(icon: Icons.shield, title: state.s.isAmharic ? "ዋስትና ማረጋገጫ" : state.s.isSomali ? "Xaqiijinta aqoonsiga" : "ID Document Verification", subtitle: state.s.isAmharic ? "የቀበሌ መታወቂያ ተረጋግጧል" : state.s.isSomali ? "Aqoonsiga Kebele xaqiijiyey" : "Kebele ID verified", trailingText: state.s.isAmharic ? "ንቁ" : state.s.isSomali ? "Firfircoon" : "Active"),
          const SizedBox(height: 10),
          _SettingsRow(icon: Icons.payment, title: state.s.isAmharic ? "የኤስክሮ ዋሌት" : state.s.isSomali ? "Xisaabta Escrow" : "Secure Wallet Account", subtitle: state.s.isAmharic ? "የክፍያ ባንኮችን ያዋቅሩ" : state.s.isSomali ? "Habaynta bangiga" : "Configure payout banks & escrow conditions"),
          const SizedBox(height: 24),

          Text(state.s.isAmharic ? "የስርዓት ቅንብሮች" : state.s.isSomali ? "Doorashada nidaamka" : "System preferences", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary, fontSize: 12)),
          const SizedBox(height: 10),
          _SettingsToggleRow(
            icon: Icons.notifications,
            title: state.s.settingsPushEnabled,
            value: notificationEnabled,
            onChanged: (val) {
              setState(() {
                notificationEnabled = val;
              });
            },
          ),
          const SizedBox(height: 10),
          _SettingsToggleRow(
            icon: Icons.light_mode,
            title: state.s.settingsDarkMode,
            value: darkModeEnabled,
            onChanged: (val) {
              setState(() {
                darkModeEnabled = val;
              });
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () => state.popScreen(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(state.s.isAmharic ? "ከሂሳብ ውጣ" : state.s.isSomali ? "Ka bax xisaabta" : "Log Out Account", style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;

  const _SettingsRow({required this.icon, required this.title, required this.subtitle, this.trailingText});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: kPrimary.withOpacity(0.08),
              child: Icon(icon, color: kPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: kOnSurfaceVariant.withOpacity(0.7))),
                ],
              ),
            ),
            if (trailingText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kVerifiedColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Text(trailingText!, style: const TextStyle(color: kVerifiedColor, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            else
              const Icon(Icons.chevron_right, color: kOnSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: kPrimary.withOpacity(0.08),
              child: Icon(icon, color: kPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Switch(
              value: value,
              activeColor: kPrimary,
              onChanged: onChanged,
            )
          ],
        ),
      ),
    );
  }
}
