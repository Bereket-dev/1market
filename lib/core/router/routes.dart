/// Sealed-class navigation routes used by [OnemarketAppState].
abstract class OnemarketScreen {}

class HomeScreenRoute extends OnemarketScreen {}

class SavedScreenRoute extends OnemarketScreen {}

class MessagesScreenRoute extends OnemarketScreen {}

class ProfileScreenRoute extends OnemarketScreen {}

class CategoryListScreenRoute extends OnemarketScreen {
  final String category;
  CategoryListScreenRoute(this.category);
}

class ListingDetailScreenRoute extends OnemarketScreen {
  final String listingId;
  ListingDetailScreenRoute(this.listingId);
}

class PostWizardScreenRoute extends OnemarketScreen {}

class ActiveChatScreenRoute extends OnemarketScreen {
  final int sessionIndex;
  ActiveChatScreenRoute(this.sessionIndex);
}

class ServiceManagementScreenRoute extends OnemarketScreen {}

class ServiceEditScreenRoute extends OnemarketScreen {
  final String? serviceId;
  ServiceEditScreenRoute(this.serviceId);
}

class ServiceBrowseScreenRoute extends OnemarketScreen {}

class ServiceDetailScreenRoute extends OnemarketScreen {
  final String serviceId;
  ServiceDetailScreenRoute(this.serviceId);
}

class ServiceReviewsScreenRoute extends OnemarketScreen {
  final String serviceId;
  ServiceReviewsScreenRoute(this.serviceId);
}

class SettingsScreenRoute extends OnemarketScreen {}

class EditProfileScreenRoute extends OnemarketScreen {}

// ── Phase C Part 2: Hiring posts ─────────────────────────────────────────────

class HiringManagementScreenRoute extends OnemarketScreen {}

class HiringEditScreenRoute extends OnemarketScreen {
  final String? postId;
  HiringEditScreenRoute(this.postId);
}

class HiringApplicantListScreenRoute extends OnemarketScreen {
  final String postId;
  HiringApplicantListScreenRoute(this.postId);
}

class HiringApplicantDetailScreenRoute extends OnemarketScreen {
  final String applicationId;
  final String postId;
  HiringApplicantDetailScreenRoute({
    required this.applicationId,
    required this.postId,
  });
}

class HiringBrowseScreenRoute extends OnemarketScreen {}

class HiringDetailScreenRoute extends OnemarketScreen {
  final String postId;
  HiringDetailScreenRoute(this.postId);
}

class MyApplicationsScreenRoute extends OnemarketScreen {}

class NotificationsScreenRoute extends OnemarketScreen {}

class MyListingsScreenRoute extends OnemarketScreen {}

class EditListingScreenRoute extends OnemarketScreen {
  final String listingId;
  EditListingScreenRoute(this.listingId);
}

class PublicProfileScreenRoute extends OnemarketScreen {
  final String userId;
  PublicProfileScreenRoute(this.userId);
}
