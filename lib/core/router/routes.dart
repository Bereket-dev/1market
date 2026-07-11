/// Sealed-class navigation routes used by [KoolanAppState].
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
