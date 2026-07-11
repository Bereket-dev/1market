class Listing {
  final int id;

  /// Category: CARS, HOUSES, LAND, SKILLS
  final String category;
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

  /// True when posted by the current user via the wizard.
  final bool isCustom;

  const Listing({
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
