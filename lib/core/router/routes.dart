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
  final String listingId;
  ListingDetailScreenRoute(this.listingId);
}

class PostWizardScreenRoute extends KoolanScreen {}

class ActiveChatScreenRoute extends KoolanScreen {
  final int sessionIndex;
  ActiveChatScreenRoute(this.sessionIndex);
}

class ServiceManagementScreenRoute extends KoolanScreen {}

class ServiceEditScreenRoute extends KoolanScreen {
  final String? serviceId;
  ServiceEditScreenRoute(this.serviceId);
}

class ServiceBrowseScreenRoute extends KoolanScreen {}

class ServiceDetailScreenRoute extends KoolanScreen {
  final String serviceId;
  ServiceDetailScreenRoute(this.serviceId);
}

class ServiceReviewsScreenRoute extends KoolanScreen {
  final String serviceId;
  ServiceReviewsScreenRoute(this.serviceId);
}

class SettingsScreenRoute extends KoolanScreen {}

class EditProfileScreenRoute extends KoolanScreen {}

// ── Phase C Part 2: Hiring posts ─────────────────────────────────────────────

class HiringManagementScreenRoute extends KoolanScreen {}

class HiringEditScreenRoute extends KoolanScreen {
  final String? postId;
  HiringEditScreenRoute(this.postId);
}

class HiringApplicantListScreenRoute extends KoolanScreen {
  final String postId;
  HiringApplicantListScreenRoute(this.postId);
}

class HiringApplicantDetailScreenRoute extends KoolanScreen {
  final String applicationId;
  final String postId;
  HiringApplicantDetailScreenRoute({
    required this.applicationId,
    required this.postId,
  });
}

class HiringBrowseScreenRoute extends KoolanScreen {}

class HiringDetailScreenRoute extends KoolanScreen {
  final String postId;
  HiringDetailScreenRoute(this.postId);
}

class MyApplicationsScreenRoute extends KoolanScreen {}

class NotificationsScreenRoute extends KoolanScreen {}

class MyListingsScreenRoute extends KoolanScreen {}

class EditListingScreenRoute extends KoolanScreen {
  final String listingId;
  EditListingScreenRoute(this.listingId);
}
