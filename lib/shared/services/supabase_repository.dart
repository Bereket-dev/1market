import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application.dart';
import '../models/chat.dart';
import '../models/hiring_post.dart';
import '../models/listing.dart';
import '../models/profile.dart';
import '../models/service.dart';
import '../models/service_review.dart';

part 'parts/supabase_repository_profile.dart';
part 'parts/supabase_repository_listings.dart';
part 'parts/supabase_repository_chat.dart';
part 'parts/supabase_repository_reviews.dart';
part 'parts/supabase_repository_services.dart';
part 'parts/supabase_repository_hiring.dart';
part 'parts/supabase_repository_notifications.dart';

class SupabaseRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;

  static const int kPageSize = 30;

  String? get currentUserId => _client.auth.currentUser?.id;
}
