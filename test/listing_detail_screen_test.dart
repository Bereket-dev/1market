import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onemarket/features/listings/presentation/screens/listing_detail_screen.dart';
import 'package:onemarket/shared/models/listing.dart';
import 'package:onemarket/shared/services/app_state.dart';

Listing _sampleListing({String? sellerPhone}) => Listing(
      id: 'listing-1',
      category: 'CARS',
      title: 'Toyota Land Cruiser',
      price: 'ETB 1,200,000',
      imageUrl: '',
      location: 'Dire Dawa, Kebele 06',
      conditionOrStatus: 'Available',
      sellerName: 'Test Seller',
      sellerPhone: sellerPhone,
      sellerId: 'seller-1',
      description: 'Well maintained vehicle.',
      isOwnedByCurrentUser: true,
    );

/// Mirrors the nested Scaffold used by [app_shell.dart].
Widget _nestedShell(OnemarketAppState state, Widget screen) {
  return MaterialApp(
    home: OnemarketAppStateScope(
      notifier: state,
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {},
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: screen,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('ListingDetailScreen shows listing inside AnimatedSwitcher shell',
      (WidgetTester tester) async {
    final state = OnemarketAppState();
    state.allListings = [_sampleListing(sellerPhone: '0911223344')];

    await tester.pumpWidget(
      _nestedShell(
        state,
        ListingDetailScreen(
          key: const ValueKey('detail_listing-1'),
          listingId: 'listing-1',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Toyota Land Cruiser'), findsOneWidget);
    expect(find.text('ETB 1,200,000'), findsOneWidget);
  });

  testWidgets('ListingDetailScreen not-found is visible inside RefreshIndicator',
      (WidgetTester tester) async {
    final state = OnemarketAppState();

    await tester.pumpWidget(
      _nestedShell(
        state,
        ListingDetailScreen(
          key: const ValueKey('detail_missing'),
          listingId: 'missing-id',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Listing not found'), findsOneWidget);
  });

  testWidgets('ListingDetailScreen with similar listings lays out',
      (WidgetTester tester) async {
    final state = OnemarketAppState();
    state.allListings = [
      _sampleListing(sellerPhone: '0911223344'),
      Listing(
        id: 'listing-2',
        category: 'CARS',
        title: 'Honda Civic',
        price: 'ETB 800,000',
        imageUrl: '',
        location: 'Addis Ababa',
        conditionOrStatus: 'Available',
        sellerName: 'Other Seller',
        sellerPhone: '0911000000',
        sellerId: 'seller-2',
        description: 'Clean car.',
        isOwnedByCurrentUser: false,
      ),
    ];

    await tester.pumpWidget(
      _nestedShell(
        state,
        ListingDetailScreen(
          key: const ValueKey('detail_listing-1'),
          listingId: 'listing-1',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Toyota Land Cruiser'), findsOneWidget);
    expect(find.text('Similar to This'), findsOneWidget);
    expect(find.text('Honda Civic'), findsOneWidget);
  });
}
