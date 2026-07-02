class YaCopeListing {
  final int id;
  final String name;
  final String phone;
  final String? address;
  final String imageUrls;
  final String condition;
  final int viewsCount;
  final int sharesCount;
  final bool isSold;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const YaCopeListing({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.imageUrls,
    this.condition = 'used',
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.isSold = false,
    this.createdAt,
    this.expiresAt,
  });

  static const ttlDays = 4;

  factory YaCopeListing.fromJson(Map<String, dynamic> json) {
    return YaCopeListing(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String? ?? '').trim(),
      phone: (json['phone'] as String? ?? '').trim(),
      address: (json['address'] as String?)?.trim(),
      imageUrls: (json['image_urls'] as String? ?? '').trim(),
      condition: (json['condition'] as String? ?? 'used').trim(),
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      sharesCount: (json['shares_count'] as num?)?.toInt() ?? 0,
      isSold: json['is_sold'] == true || json['is_sold'] == 1,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
    );
  }

  DateTime? get effectiveExpiresAt {
    if (expiresAt != null) return expiresAt;
    if (createdAt == null) return null;
    return createdAt!.add(const Duration(days: ttlDays));
  }

  bool get isExpired {
    final end = effectiveExpiresAt;
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  int? get daysRemaining {
    final end = effectiveExpiresAt;
    if (end == null) return null;
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inDays + (diff.inHours % 24 > 0 || diff.inMinutes % 60 > 0 ? 1 : 0);
  }

  String get shareUrl => 'https://uzaapp.com/ya-cope/$id';

  List<String> get images => imageUrls
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}
