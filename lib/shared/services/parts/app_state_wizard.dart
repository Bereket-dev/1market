// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Post wizard ───────────────────────────────────────────────────────────────

extension AppStateWizard on KoolanAppState {
  /// Opens the system image picker and appends up to (8 − current count)
  /// images to [postImagePaths].
  Future<void> pickListingImages(BuildContext context) async {
    final remaining = 8 - postImagePaths.length;
    if (remaining <= 0) return;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );
    } catch (e) {
      listingImageUploadError = e.toString();
      notifyListeners();
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final paths = result.files
        .take(remaining)
        .map((f) => f.path)
        .whereType<String>()
        .toList();

    postImagePaths = [...postImagePaths, ...paths];
    postMainPhotoAttached = postImagePaths.isNotEmpty;
    listingImageUploadError = null;
    notifyListeners();
  }

  /// Removes the picked image at [index] from the wizard image list.
  void removeListingImage(int index) {
    if (index < 0 || index >= postImagePaths.length) return;
    postImagePaths = List.from(postImagePaths)..removeAt(index);
    postMainPhotoAttached = postImagePaths.isNotEmpty;
    notifyListeners();
  }

  void resetWizard() {
    postStep = 1;
    postCategory = 'CARS';
    postTitle = '';
    postPrice = '';
    postDescription = '';
    postLocation = 'Kebele 06';
    postPhysicalAddress = '';
    postMainPhotoAttached = false;
    postImagePaths = [];
    listingImageUploadError = null;
    isUploadingListingImages = false;
    postCondition = '';
    postSpec1 = '';
    postSpec2 = '';
    postSpec3 = '';
    postSpec4 = '';
    notifyListeners();
  }

  Future<String> submitPost() async {
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

    final sellerName = profile?.displayName ?? 'Me';
    final sellerImage = profile?.avatarUrl ?? '';
    final userId = currentUser?.id ?? '';

    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return '';
      }

      // ── 1. Upload picked images to Cloudinary ──────────────────────────────
      final tempListingId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
      final uploadedUrls = <String>[];
      final errors = <String>[];

      if (postImagePaths.isNotEmpty) {
        isUploadingListingImages = true;
        listingImageUploadError = null;
        notifyListeners();

        for (int i = 0; i < postImagePaths.length; i++) {
          final file = File(postImagePaths[i]);
          if (!await file.exists()) continue;
          final result = await CloudinaryUploadService.instance.uploadListingImage(
            imageFile: file,
            userId: userId,
            listingId: tempListingId,
            index: i,
          );
          switch (result) {
            case CloudinaryUploadSuccess(:final secureUrl):
              uploadedUrls.add(secureUrl);
            case CloudinaryUploadFailure(:final message):
              errors.add(message);
          }
        }

        isUploadingListingImages = false;
        if (errors.isNotEmpty) {
          listingImageUploadError =
              '${errors.length} image(s) failed to upload';
          notifyListeners();
        }
      }

      final primaryImageUrl = uploadedUrls.isNotEmpty
          ? uploadedUrls.first
          : _defaultImageForCategory(postCategory);

      // ── 2. Insert listing into Supabase ────────────────────────────────────
      final newListing = await _repo!.createListing(
        category: postCategory,
        title: titleStr,
        price: priceStr,
        imageUrl: primaryImageUrl,
        location: '${postLocation.trim()}, Jigjiga',
        conditionOrStatus: postCondition.trim().isEmpty
            ? 'Available'
            : postCondition.trim(),
        description: descStr,
        spec1Label: _specLabel1(postCategory),
        spec1Value: postSpec1.trim().isEmpty
            ? _specDefault1(postCategory)
            : postSpec1.trim(),
        spec2Label: _specLabel2(postCategory),
        spec2Value: postSpec2.trim().isEmpty
            ? _specDefault2(postCategory)
            : postSpec2.trim(),
        spec3Label: _specLabel3(postCategory),
        spec3Value: postSpec3.trim().isEmpty
            ? _specDefault3(postCategory)
            : postSpec3.trim(),
        spec4Label: _specLabel4(postCategory),
        spec4Value: postSpec4.trim().isEmpty
            ? _specDefault4(postCategory)
            : postSpec4.trim(),
        sellerName: sellerName,
        sellerImage: sellerImage,
        sellerPhone: profile?.phone,
        originalLanguage: locale,
        imageUrls: uploadedUrls,
      );

      allListings.insert(0, newListing);
      resetWizard();
      notifyListeners();

      // ── 3. Fire-and-forget translation ────────────────────────────────────
      TranslationService.instance.scheduleTranslation(
        listingId: newListing.id,
        title: titleStr,
        description: descStr,
        originalLanguage: locale,
      );
      return newListing.id;
    } catch (e) {
      isUploadingListingImages = false;
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
