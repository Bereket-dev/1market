import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onemarket/core/router/routes.dart';
import 'package:onemarket/features/listings/presentation/screens/listing_detail_screen.dart';
import 'package:onemarket/features/post/presentation/screens/post_wizard_screen.dart';
import 'package:onemarket/shared/models/listing.dart';
import 'package:onemarket/shared/services/app_state.dart';

Listing _sampleListing() => Listing(
      id: 'listing-1',
      category: 'CARS',
      title: 'Toyota Land Cruiser',
      price: 'ETB 1,200,000',
      imageUrl: 'https://example.com/car.jpg',
      location: 'Dire Dawa, Kebele 06',
      conditionOrStatus: 'Available',
      sellerName: 'Test Seller',
      sellerPhone: '0911223344',
      sellerId: 'seller-1',
      description: 'Well maintained vehicle.',
      isOwnedByCurrentUser: true,
    );

Widget _shellFor(OnemarketAppState state, OnemarketScreen screen) {
  final child = switch (screen) {
    PostWizardScreenRoute() => const PostWizardScreen(key: ValueKey('wizard')),
    ListingDetailScreenRoute(:final listingId) => ListingDetailScreen(
        key: ValueKey('detail_$listingId'),
        listingId: listingId,
      ),
    _ => const SizedBox(key: ValueKey('unknown')),
  };

  return MaterialApp(
    home: OnemarketAppStateScope(
      notifier: state,
      child: RefreshIndicator(
        onRefresh: () async {},
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('pop wizard then push listing detail shows content',
      (WidgetTester tester) async {
    final state = OnemarketAppState();
    state.allListings = [_sampleListing()];
    state.navigationStack.add(PostWizardScreenRoute());

    await tester.pumpWidget(_shellFor(state, state.navigationStack.last));
    await tester.pump();

    state.popScreen();
    state.pushScreen(ListingDetailScreenRoute('listing-1'));
    await tester.pumpWidget(_shellFor(state, state.navigationStack.last));

    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Toyota Land Cruiser'), findsOneWidget);
  });
}
