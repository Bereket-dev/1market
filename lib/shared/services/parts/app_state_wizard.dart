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
      listingImageUploadError = s.errorUnknown;
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
        dataError = s.errorSupabaseUnavailable;
        notifyListeners();
        return '';
      }

      // ── 1. Upload picked images to Cloudinary ──────────────────────────────
      final tempListingId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
      final uploadedUrls = <String>[];
      final pendingNetworkImages = <Map<String, dynamic>>[];

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
            case CloudinaryUploadFailure(:final code):
              if (code == CloudinaryFailureCode.network) {
                pendingNetworkImages.add({
                  'localPath': postImagePaths[i],
                  'index': i,
                });
              } else {
                isUploadingListingImages = false;
                listingImageUploadError = _listingUploadErrorFor(code);
                notifyListeners();
                return '';
              }
          }
        }

        isUploadingListingImages = false;
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
      if (pendingNetworkImages.isNotEmpty) {
        await _queueListingImages(
          listingId: newListing.id,
          userId: userId,
          images: pendingNetworkImages,
        );
        dataError = s.wizardPhotosQueued;
      }
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
      reportDataError(e);
      notifyListeners();
      rethrow;
    }
  }

  String _listingUploadErrorFor(CloudinaryFailureCode code) {
    return switch (code) {
      CloudinaryFailureCode.unauthorized => s.errorUnauthorized,
      CloudinaryFailureCode.notConfigured => s.errorSupabaseUnavailable,
      CloudinaryFailureCode.network => s.errorNetwork,
      _ => s.errorUnknown,
    };
  }

  Future<void> _queueListingImages({
    required String listingId,
    required String userId,
    required List<Map<String, dynamic>> images,
  }) async {
    final store = HiveSyncStore.instance;
    await store.initialize();
    await store.savePendingListingImages(
      listingId,
      jsonEncode({
        'listingId': listingId,
        'userId': userId,
        'images': images,
      }),
    );
    if (kDebugMode) {
      debugPrint('[ListingUpload] queued ${images.length} images for $listingId');
    }
  }

  /// Flushes listing images queued after network failures during post wizard.
  Future<void> flushPendingListingImages() async {
    final store = HiveSyncStore.instance;
    await store.initialize();
    if (_repo == null) return;

    final listingIds = await store.getPendingListingImageIds();
    for (final listingId in listingIds) {
      final raw = store.readPendingListingImages(listingId);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final userId = data['userId'] as String? ?? currentUser?.id ?? '';
        final images = (data['images'] as List?) ?? [];
        if (userId.isEmpty || images.isEmpty) {
          await store.deletePendingListingImages(listingId);
          continue;
        }

        final uploaded = <String, String>{};
        var keepQueued = false;
        for (final item in images) {
          if (item is! Map) continue;
          final localPath = item['localPath'] as String?;
          final index = item['index'] as int? ?? uploaded.length;
          if (localPath == null) continue;
          final file = File(localPath);
          if (!await file.exists()) continue;

          final result = await CloudinaryUploadService.instance.uploadListingImage(
            imageFile: file,
            userId: userId,
            listingId: listingId,
            index: index,
          );
          switch (result) {
            case CloudinaryUploadSuccess(:final secureUrl):
              uploaded['$index'] = secureUrl;
            case CloudinaryUploadFailure(:final code):
              if (code == CloudinaryFailureCode.network) {
                keepQueued = true;
              } else if (kDebugMode) {
                debugPrint('[ListingUpload] flush failed for $listingId: $code');
              }
          }
        }

        if (uploaded.isEmpty) {
          if (!keepQueued) await store.deletePendingListingImages(listingId);
          continue;
        }

        final idx = allListings.indexWhere((l) => l.id == listingId);
        final existing = idx >= 0 ? allListings[idx] : null;
        final merged = List<String>.from(existing?.imageUrls ?? []);
        if (merged.isEmpty && existing?.imageUrl.isNotEmpty == true) {
          merged.add(existing!.imageUrl);
        }
        for (final url in uploaded.values) {
          if (!merged.contains(url)) merged.add(url);
        }

        await _repo!.updateListing(listingId, {
          'image_url': merged.first,
          'image_urls': merged,
        });

        if (idx >= 0) {
          allListings[idx] = allListings[idx].copyWith(
            imageUrl: merged.first,
            imageUrls: merged,
          );
          notifyListeners();
        }

        if (keepQueued) {
          final remaining = images.where((item) {
            if (item is! Map) return false;
            final index = '${item['index']}';
            return !uploaded.containsKey(index);
          }).toList();
          if (remaining.isEmpty) {
            await store.deletePendingListingImages(listingId);
          } else {
            await store.savePendingListingImages(
              listingId,
              jsonEncode({
                'listingId': listingId,
                'userId': userId,
                'images': remaining,
              }),
            );
          }
        } else {
          await store.deletePendingListingImages(listingId);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ListingUpload] flush error for $listingId: $e');
        }
      }
    }
  }
}
