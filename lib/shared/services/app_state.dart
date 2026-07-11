import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../models/chat.dart';
import '../models/app_strings.dart';
import '../../core/router/routes.dart';

/// Central application state. Shared via [KoolanAppStateScope].
class KoolanAppState extends ChangeNotifier {
  // ── Navigation ─────────────────────────────────────────────────────────────
  final List<KoolanScreen> navigationStack = [HomeScreenRoute()];

  // ── Locale ──────────────────────────────────────────────────────────────────
  String locale = 'en';
  AppStrings get s => AppStrings(locale);

  void toggleLocale() {
    locale = locale == 'en' ? 'am' : locale == 'am' ? 'so' : 'en';
    notifyListeners();
  }

  // ── Filters ─────────────────────────────────────────────────────────────────
  String selectedCategory = 'ALL';
  String searchQuery = '';

  // ── Comparison ──────────────────────────────────────────────────────────────
  bool compareModeEnabled = false;
  Set<int> selectedCompareIds = {};

  // ── Data ────────────────────────────────────────────────────────────────────
  List<Listing> allListings = [];
  List<ChatSession> chatSessions = [];

  // ── Post-wizard state ────────────────────────────────────────────────────────
  int postStep = 1;
  String postCategory = 'CARS';
  String postTitle = '';
  String postPrice = '';
  String postDescription = '';
  String postLocation = 'Kebele 06';
  String postPhysicalAddress = '';
  bool postMainPhotoAttached = false;
  String postSpec1 = '';
  String postSpec2 = '';
  String postSpec3 = '';
  String postSpec4 = '';

  KoolanAppState() {
    _prepopulate();
  }

  // ── Seed data ────────────────────────────────────────────────────────────────
  void _prepopulate() {
    allListings = [
      const Listing(
        id: 1,
        category: 'LAND',
        title: 'Residential Plot in Kebele 02',
        price: 'ETB 4,200,000',
        imageUrl:
            'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=500&q=80',
        location: 'Kebele 02, Jigjiga, Somali Region',
        verified: true,
        conditionOrStatus: 'For Sale',
        sellerName: 'Ahmed Mohammed',
        sellerRating: 4.9,
        sellerReviewsCount: 124,
        sellerImage:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
        description:
            'A wide angle high-resolution photograph of a vast, flat residential land plot in '
            'Jigjiga under a clear blue sky. Located in the popular and rapidly developing '
            'Kebele 02 neighborhood of Jigjiga, perfect for family homes or commercial development.',
        spec1Label: 'Size',
        spec1Value: '1000 sqm',
        spec2Label: 'Land Use',
        spec2Value: 'Residential',
        spec3Label: 'Title Deed',
        spec3Value: 'Available',
        spec4Label: 'Road Access',
        spec4Value: 'Yes (12m)',
      ),
      const Listing(
        id: 2,
        category: 'LAND',
        title: 'Agricultural Plot in Tuli-Guled',
        price: r'$28,500',
        imageUrl:
            'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=500&q=80',
        location: 'Tuli-Guled, Fafan',
        conditionOrStatus: 'For Sale',
        sellerName: 'Ahmed Nur',
        sellerRating: 4.8,
        sellerReviewsCount: 31,
        sellerImage:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
        description:
            'A lush green agricultural plot at golden hour. Perfect fertile land in the Fafan zone '
            'with rich soil and reliable irrigation options.',
        spec1Label: 'Size',
        spec1Value: '2.5 hectares',
        spec2Label: 'Land Use',
        spec2Value: 'Agricultural',
        spec3Label: 'Title Deed',
        spec3Value: 'Pending',
        spec4Label: 'Road Access',
        spec4Value: 'Yes',
      ),
      const Listing(
        id: 3,
        category: 'LAND',
        title: 'Commercial Highway Plot',
        price: r'$450,000',
        imageUrl:
            'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=500&q=80',
        location: 'Qabribayah Road, Jigjiga',
        verified: true,
        conditionOrStatus: 'For Sale',
        sellerName: 'Ahmed Mohammed',
        sellerRating: 4.9,
        sellerReviewsCount: 124,
        sellerImage:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
        description:
            'Outstanding visibility, ideal for gas stations, logistics, warehouses or multi-story '
            'commercial facilities.',
        spec1Label: 'Size',
        spec1Value: '4,800 sqm',
        spec2Label: 'Land Use',
        spec2Value: 'Commercial',
        spec3Label: 'Title Deed',
        spec3Value: 'Available',
        spec4Label: 'Road Access',
        spec4Value: 'Direct Highway',
      ),
      const Listing(
        id: 4,
        category: 'CARS',
        title: '2022 Toyota Land Cruiser Prado',
        price: r'$42,500',
        imageUrl:
            'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80',
        location: 'Downtown, Jigjiga',
        verified: true,
        conditionOrStatus: 'For Sale',
        sellerName: 'Ahmed Nur',
        sellerRating: 4.9,
        sellerReviewsCount: 124,
        sellerImage:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
        description:
            'A sleek, metallic charcoal gray luxury SUV Toyota Land Cruiser Prado TXL in mint '
            'condition. Fully loaded with modern options, dual zone A/C, leather seats.',
        spec1Label: 'Year',
        spec1Value: '2022',
        spec2Label: 'Mileage',
        spec2Value: '12,400 km',
        spec3Label: 'Transmission',
        spec3Value: 'Automatic',
        spec4Label: 'Fuel Type',
        spec4Value: 'Petrol',
      ),
      const Listing(
        id: 5,
        category: 'CARS',
        title: '2021 Hyundai Sonata Limited',
        price: r'$28,900',
        imageUrl:
            'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=500&q=80',
        location: 'Airport Rd, Jigjiga',
        verified: true,
        conditionOrStatus: 'For Sale',
        sellerName: 'Ahmed Nur',
        sellerRating: 4.8,
        sellerReviewsCount: 31,
        sellerImage:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
        description:
            'A pristine white executive sedan with panorama sunroof, smart adaptive cruise '
            'control, lane assist and luxurious driving ergonomics.',
        spec1Label: 'Year',
        spec1Value: '2021',
        spec2Label: 'Mileage',
        spec2Value: '28,000 km',
        spec3Label: 'Transmission',
        spec3Value: 'Automatic',
        spec4Label: 'Fuel Type',
        spec4Value: 'Petrol',
      ),
      const Listing(
        id: 6,
        category: 'CARS',
        title: '2021 Toyota Hilux 2.8 GD-6 Raider',
        price: r'$42,500',
        imageUrl:
            'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80',
        location: 'Jigjiga Central, Somali Region',
        verified: true,
        conditionOrStatus: 'Good Condition',
        sellerName: 'Ahmed Nur',
        sellerRating: 4.9,
        sellerReviewsCount: 124,
        sellerImage:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
        description:
            'Extremely well-maintained 2021 Toyota Hilux. Single owner since new, full service '
            'history at certified Toyota dealers.',
        spec1Label: 'Year',
        spec1Value: '2021',
        spec2Label: 'Mileage',
        spec2Value: '45,000 km',
        spec3Label: 'Transmission',
        spec3Value: 'Automatic',
        spec4Label: 'Fuel Type',
        spec4Value: 'Diesel',
      ),
      const Listing(
        id: 7,
        category: 'HOUSES',
        title: 'Modern 4-Bedroom Villa',
        price: r'$145,000',
        imageUrl:
            'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=500&q=80',
        location: 'Kebele 04, Jigjiga',
        verified: true,
        conditionOrStatus: 'For Sale',
        sellerName: 'Ahmed Abdullahi',
        sellerRating: 4.8,
        sellerReviewsCount: 124,
        sellerImage:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
        description:
            'A stunning ultra-modern villa in Jigjiga with clean white geometric lines, large '
            'floor-to-ceiling glass windows, and a lush private courtyard.',
        spec1Label: 'Bedrooms',
        spec1Value: '4 Bed',
        spec2Label: 'Bathrooms',
        spec2Value: '3 Bath',
        spec3Label: 'Area',
        spec3Value: '350 m²',
        spec4Label: 'Security',
        spec4Value: '24/7',
      ),
      const Listing(
        id: 8,
        category: 'HOUSES',
        title: 'Elite Studio Loft',
        price: r'$450 /mo',
        imageUrl:
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=500&q=80',
        location: 'City Center, Jigjiga',
        verified: true,
        conditionOrStatus: 'For Rent',
        sellerName: 'Ahmed Abdullahi',
        sellerRating: 4.8,
        sellerReviewsCount: 124,
        sellerImage:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
        description:
            'A minimalist luxury studio apartment interior in a high-rise building in Jigjiga.',
        spec1Label: 'Bedrooms',
        spec1Value: '1 Bed',
        spec2Label: 'Bathrooms',
        spec2Value: '1 Bath',
        spec3Label: 'Area',
        spec3Value: '65 m²',
        spec4Label: 'Security',
        spec4Value: '24/7',
      ),
      const Listing(
        id: 9,
        category: 'SKILLS',
        title: 'Marcus Chen',
        price: r'$45 /hr',
        imageUrl:
            'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=500&q=80',
        location: 'Silver Valley • 1.2 km away',
        verified: true,
        conditionOrStatus: 'Available',
        sellerName: 'Marcus Chen',
        sellerRating: 4.9,
        sellerReviewsCount: 120,
        sellerImage:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=150&q=80',
        description:
            'A professional male electrician with over 5 years of experience. Dedicated to '
            'thorough residential wiring, appliance setups, testing, and trouble-shooting.',
        spec1Label: 'Category',
        spec1Value: 'Electrician',
        spec2Label: 'Experience',
        spec2Value: '5 years',
        spec3Label: 'Skills',
        spec3Value: 'Wiring, Troubleshooting',
        spec4Label: 'Verified',
        spec4Value: 'Yes',
      ),
      const Listing(
        id: 10,
        category: 'SKILLS',
        title: 'Hodan Ahmed',
        price: 'Unlock for 30 ETB',
        imageUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=500&q=80',
        location: 'Kebele 03, Jigjiga',
        verified: true,
        conditionOrStatus: 'Available',
        sellerName: 'Hodan Ahmed',
        sellerRating: 5.0,
        sellerReviewsCount: 48,
        sellerImage:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80',
        description:
            'Dedicated and thorough professional specialising in comprehensive household '
            'management. Known for attention to detail, punctuality, and a trust-first approach.',
        spec1Label: 'Category',
        spec1Value: 'House Help',
        spec2Label: 'Experience',
        spec2Value: '2 years',
        spec3Label: 'Skills',
        spec3Value: 'Deep Cleaning, Cooking, Laundry, Organization',
        spec4Label: 'Verified',
        spec4Value: 'Koolan Verified',
      ),
    ];

    chatSessions = [
      ChatSession(
        partnerName: 'Ahmed Nur',
        partnerAvatar:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
        listingTitle: '2021 Toyota Hilux 2.8 GD-6 Raider',
        messages: const [
          ChatMessage(
            sender: 'Ahmed Nur',
            text: 'Hello, are you still interested in the Toyota Hilux?',
            timestamp: '09:30 AM',
            isMe: false,
          ),
          ChatMessage(
            sender: 'Me',
            text: 'Yes! Is the price negotiable?',
            timestamp: '09:32 AM',
            isMe: true,
          ),
          ChatMessage(
            sender: 'Ahmed Nur',
            text: 'We can discuss a small discount. Are you available for viewing today?',
            timestamp: '09:33 AM',
            isMe: false,
          ),
        ],
        unreadCount: 1,
      ),
      ChatSession(
        partnerName: 'Ahmed Mohammed',
        partnerAvatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
        listingTitle: 'Residential Plot in Kebele 02',
        messages: const [
          ChatMessage(
            sender: 'Ahmed Mohammed',
            text: 'Welcome! The land deed is fully verified with the local authorities.',
            timestamp: 'Yesterday',
            isMe: false,
          ),
        ],
      ),
    ];
  }

  // ── Navigation actions ───────────────────────────────────────────────────────
  void pushScreen(KoolanScreen screen) {
    navigationStack.add(screen);
    notifyListeners();
  }

  void popScreen() {
    if (navigationStack.length > 1) {
      navigationStack.removeLast();
      notifyListeners();
    }
  }

  void switchTab(KoolanScreen rootTab) {
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    if (rootTab is! HomeScreenRoute) {
      navigationStack.add(rootTab);
    }
    notifyListeners();
  }

  // ── Filter actions ───────────────────────────────────────────────────────────
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
      final matchesCategory =
          selectedCategory == 'ALL' || listing.category == selectedCategory;
      final q = searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          listing.title.toLowerCase().contains(q) ||
          listing.location.toLowerCase().contains(q) ||
          listing.description.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Listing> getSavedListings() =>
      allListings.where((l) => l.isSaved).toList();

  // ── Save / Bookmark ──────────────────────────────────────────────────────────
  void toggleSaveListing(int listingId) {
    final index = allListings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      final listing = allListings[index];
      allListings[index] = listing.copyWith(isSaved: !listing.isSaved);
      notifyListeners();
    }
  }

  // ── Comparison ───────────────────────────────────────────────────────────────
  void toggleCompareMode() {
    compareModeEnabled = !compareModeEnabled;
    if (!compareModeEnabled) selectedCompareIds.clear();
    notifyListeners();
  }

  void toggleCompareSelection(int id) {
    if (selectedCompareIds.contains(id)) {
      selectedCompareIds.remove(id);
    } else if (selectedCompareIds.length < 2) {
      selectedCompareIds.add(id);
    }
    notifyListeners();
  }

  // ── Chat ─────────────────────────────────────────────────────────────────────
  void sendChatMessage(int sessionIndex, String text) {
    if (text.trim().isEmpty) return;
    final session = chatSessions[sessionIndex];
    final updatedMsgs = List<ChatMessage>.from(session.messages)
      ..add(ChatMessage(
        sender: 'Me',
        text: text,
        timestamp: 'Just now',
        isMe: true,
      ));
    chatSessions[sessionIndex] =
        session.copyWith(messages: updatedMsgs, unreadCount: 0);
    notifyListeners();
  }

  // ── Wizard ───────────────────────────────────────────────────────────────────
  void resetWizard() {
    postStep = 1;
    postTitle = '';
    postPrice = '';
    postDescription = '';
    postPhysicalAddress = '';
    postMainPhotoAttached = false;
    postSpec1 = '';
    postSpec2 = '';
    postSpec3 = '';
    postSpec4 = '';
    notifyListeners();
  }

  void submitPost() {
    final titleStr = postTitle.trim().isEmpty
        ? 'Untitled $postCategory Listing'
        : postTitle.trim();
    final priceStr = postPrice.trim().isEmpty
        ? 'Contact for price'
        : (postPrice.startsWith('ETB') || postPrice.startsWith(r'$'))
            ? postPrice.trim()
            : 'ETB ${postPrice.trim()}';
    final descStr = postDescription.trim().isEmpty
        ? 'No description provided.'
        : postDescription.trim();

    final imageStr = _defaultImageForCategory(postCategory);

    final l1 = _specLabel1(postCategory);
    final v1 = postSpec1.trim().isEmpty ? _specDefault1(postCategory) : postSpec1.trim();
    final l2 = _specLabel2(postCategory);
    final v2 = postSpec2.trim().isEmpty ? _specDefault2(postCategory) : postSpec2.trim();
    final l3 = _specLabel3(postCategory);
    final v3 = postSpec3.trim().isEmpty ? _specDefault3(postCategory) : postSpec3.trim();
    final l4 = _specLabel4(postCategory);
    final v4 = postSpec4.trim().isEmpty ? _specDefault4(postCategory) : postSpec4.trim();

    final newListing = Listing(
      id: allListings.length + 1,
      category: postCategory,
      title: titleStr,
      price: priceStr,
      imageUrl: imageStr,
      location: '${postLocation.trim()}, Jigjiga',
      verified: true,
      conditionOrStatus: 'Available',
      sellerName: 'Hodan Ahmed (Me)',
      sellerRating: 5.0,
      sellerReviewsCount: 1,
      sellerImage:
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80',
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
    selectedCategory = postCategory;

    navigationStack
      ..clear()
      ..add(HomeScreenRoute())
      ..add(CategoryListScreenRoute(postCategory));
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────────
  String _defaultImageForCategory(String cat) {
    switch (cat) {
      case 'CARS':
        return 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80';
      case 'HOUSES':
        return 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=500&q=80';
      case 'LAND':
        return 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=500&q=80';
      default:
        return 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=500&q=80';
    }
  }

  String _specLabel1(String cat) =>
      cat == 'CARS' ? 'Year' : cat == 'HOUSES' ? 'Bedrooms' : cat == 'LAND' ? 'Size' : 'Category';
  String _specDefault1(String cat) =>
      cat == 'CARS' ? '2023' : cat == 'HOUSES' ? '3 Bed' : cat == 'LAND' ? '500 sqm' : 'Worker';

  String _specLabel2(String cat) =>
      cat == 'CARS' ? 'Mileage' : cat == 'HOUSES' ? 'Bathrooms' : cat == 'LAND' ? 'Land Use' : 'Experience';
  String _specDefault2(String cat) =>
      cat == 'CARS' ? '5,000 km' : cat == 'HOUSES' ? '2 Bath' : cat == 'LAND' ? 'Residential' : '3 years';

  String _specLabel3(String cat) =>
      cat == 'CARS' ? 'Transmission' : cat == 'HOUSES' ? 'Area' : cat == 'LAND' ? 'Title Deed' : 'Skills';
  String _specDefault3(String cat) =>
      cat == 'CARS' ? 'Automatic' : cat == 'HOUSES' ? '150m²' : cat == 'LAND' ? 'Available' : 'General Support';

  String _specLabel4(String cat) =>
      cat == 'CARS' ? 'Fuel Type' : cat == 'HOUSES' ? 'Security' : cat == 'LAND' ? 'Road Access' : 'Status';
  String _specDefault4(String cat) =>
      cat == 'CARS' ? 'Petrol' : cat == 'HOUSES' ? '24/7' : cat == 'LAND' ? 'Yes' : 'Verified';
}

/// Makes [KoolanAppState] accessible anywhere in the widget tree.
class KoolanAppStateScope extends InheritedNotifier<KoolanAppState> {
  const KoolanAppStateScope({
    super.key,
    required KoolanAppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static KoolanAppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<KoolanAppStateScope>();
    assert(scope != null, 'No KoolanAppStateScope found in context');
    return scope!.notifier!;
  }
}
