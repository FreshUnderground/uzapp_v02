// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uza_database.dart';

// ignore_for_file: type=lint
class $ShopsTable extends Shops with TableInfo<$ShopsTable, Shop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShopType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ShopType>($ShopsTable.$convertertype);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatsappMeta = const VerificationMeta(
    'whatsapp',
  );
  @override
  late final GeneratedColumn<String> whatsapp = GeneratedColumn<String>(
    'whatsapp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instagramUrlMeta = const VerificationMeta(
    'instagramUrl',
  );
  @override
  late final GeneratedColumn<String> instagramUrl = GeneratedColumn<String>(
    'instagram_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tiktokUrlMeta = const VerificationMeta(
    'tiktokUrl',
  );
  @override
  late final GeneratedColumn<String> tiktokUrl = GeneratedColumn<String>(
    'tiktok_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _facebookUrlMeta = const VerificationMeta(
    'facebookUrl',
  );
  @override
  late final GeneratedColumn<String> facebookUrl = GeneratedColumn<String>(
    'facebook_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _youtubeUrlMeta = const VerificationMeta(
    'youtubeUrl',
  );
  @override
  late final GeneratedColumn<String> youtubeUrl = GeneratedColumn<String>(
    'youtube_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerUrlMeta = const VerificationMeta(
    'bannerUrl',
  );
  @override
  late final GeneratedColumn<String> bannerUrl = GeneratedColumn<String>(
    'banner_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isBoostedMeta = const VerificationMeta(
    'isBoosted',
  );
  @override
  late final GeneratedColumn<bool> isBoosted = GeneratedColumn<bool>(
    'is_boosted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_boosted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _boostStatusMeta = const VerificationMeta(
    'boostStatus',
  );
  @override
  late final GeneratedColumn<int> boostStatus = GeneratedColumn<int>(
    'boost_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bannerStatusMeta = const VerificationMeta(
    'bannerStatus',
  );
  @override
  late final GeneratedColumn<int> bannerStatus = GeneratedColumn<int>(
    'banner_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bannerTextMeta = const VerificationMeta(
    'bannerText',
  );
  @override
  late final GeneratedColumn<String> bannerText = GeneratedColumn<String>(
    'banner_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isVerifiedMeta = const VerificationMeta(
    'isVerified',
  );
  @override
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
    'is_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _responseTimeMinutesMeta =
      const VerificationMeta('responseTimeMinutes');
  @override
  late final GeneratedColumn<int> responseTimeMinutes = GeneratedColumn<int>(
    'response_time_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _communeMeta = const VerificationMeta(
    'commune',
  );
  @override
  late final GeneratedColumn<String> commune = GeneratedColumn<String>(
    'commune',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    name,
    description,
    logoUrl,
    type,
    ownerId,
    address,
    whatsapp,
    phone,
    email,
    instagramUrl,
    tiktokUrl,
    facebookUrl,
    youtubeUrl,
    bannerUrl,
    videoUrl,
    updatedAt,
    isBoosted,
    boostStatus,
    bannerStatus,
    bannerText,
    isVerified,
    responseTimeMinutes,
    commune,
    city,
    verifiedAt,
    latitude,
    longitude,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shops';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shop> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('whatsapp')) {
      context.handle(
        _whatsappMeta,
        whatsapp.isAcceptableOrUnknown(data['whatsapp']!, _whatsappMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('instagram_url')) {
      context.handle(
        _instagramUrlMeta,
        instagramUrl.isAcceptableOrUnknown(
          data['instagram_url']!,
          _instagramUrlMeta,
        ),
      );
    }
    if (data.containsKey('tiktok_url')) {
      context.handle(
        _tiktokUrlMeta,
        tiktokUrl.isAcceptableOrUnknown(data['tiktok_url']!, _tiktokUrlMeta),
      );
    }
    if (data.containsKey('facebook_url')) {
      context.handle(
        _facebookUrlMeta,
        facebookUrl.isAcceptableOrUnknown(
          data['facebook_url']!,
          _facebookUrlMeta,
        ),
      );
    }
    if (data.containsKey('youtube_url')) {
      context.handle(
        _youtubeUrlMeta,
        youtubeUrl.isAcceptableOrUnknown(data['youtube_url']!, _youtubeUrlMeta),
      );
    }
    if (data.containsKey('banner_url')) {
      context.handle(
        _bannerUrlMeta,
        bannerUrl.isAcceptableOrUnknown(data['banner_url']!, _bannerUrlMeta),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_boosted')) {
      context.handle(
        _isBoostedMeta,
        isBoosted.isAcceptableOrUnknown(data['is_boosted']!, _isBoostedMeta),
      );
    }
    if (data.containsKey('boost_status')) {
      context.handle(
        _boostStatusMeta,
        boostStatus.isAcceptableOrUnknown(
          data['boost_status']!,
          _boostStatusMeta,
        ),
      );
    }
    if (data.containsKey('banner_status')) {
      context.handle(
        _bannerStatusMeta,
        bannerStatus.isAcceptableOrUnknown(
          data['banner_status']!,
          _bannerStatusMeta,
        ),
      );
    }
    if (data.containsKey('banner_text')) {
      context.handle(
        _bannerTextMeta,
        bannerText.isAcceptableOrUnknown(data['banner_text']!, _bannerTextMeta),
      );
    }
    if (data.containsKey('is_verified')) {
      context.handle(
        _isVerifiedMeta,
        isVerified.isAcceptableOrUnknown(data['is_verified']!, _isVerifiedMeta),
      );
    }
    if (data.containsKey('response_time_minutes')) {
      context.handle(
        _responseTimeMinutesMeta,
        responseTimeMinutes.isAcceptableOrUnknown(
          data['response_time_minutes']!,
          _responseTimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('commune')) {
      context.handle(
        _communeMeta,
        commune.isAcceptableOrUnknown(data['commune']!, _communeMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shop(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
      type: $ShopsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      whatsapp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}whatsapp'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      instagramUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instagram_url'],
      ),
      tiktokUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tiktok_url'],
      ),
      facebookUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facebook_url'],
      ),
      youtubeUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}youtube_url'],
      ),
      bannerUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_url'],
      ),
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isBoosted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_boosted'],
      )!,
      boostStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}boost_status'],
      )!,
      bannerStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}banner_status'],
      )!,
      bannerText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_text'],
      ),
      isVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_verified'],
      )!,
      responseTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_time_minutes'],
      ),
      commune: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commune'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
    );
  }

  @override
  $ShopsTable createAlias(String alias) {
    return $ShopsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ShopType, String, String> $convertertype =
      const EnumNameConverter<ShopType>(ShopType.values);
}

class Shop extends DataClass implements Insertable<Shop> {
  final int id;
  final String? remoteId;
  final String name;
  final String? description;
  final String? logoUrl;
  final ShopType type;
  final String? ownerId;
  final String? address;
  final String? whatsapp;
  final String? phone;
  final String? email;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? facebookUrl;
  final String? youtubeUrl;
  final String? bannerUrl;
  final String? videoUrl;
  final DateTime updatedAt;
  final bool isBoosted;
  final int boostStatus;
  final int bannerStatus;
  final String? bannerText;
  final bool isVerified;
  final int? responseTimeMinutes;
  final String? commune;
  final String? city;
  final DateTime? verifiedAt;
  final double? latitude;
  final double? longitude;
  const Shop({
    required this.id,
    this.remoteId,
    required this.name,
    this.description,
    this.logoUrl,
    required this.type,
    this.ownerId,
    this.address,
    this.whatsapp,
    this.phone,
    this.email,
    this.instagramUrl,
    this.tiktokUrl,
    this.facebookUrl,
    this.youtubeUrl,
    this.bannerUrl,
    this.videoUrl,
    required this.updatedAt,
    required this.isBoosted,
    required this.boostStatus,
    required this.bannerStatus,
    this.bannerText,
    required this.isVerified,
    this.responseTimeMinutes,
    this.commune,
    this.city,
    this.verifiedAt,
    this.latitude,
    this.longitude,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    {
      map['type'] = Variable<String>($ShopsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || whatsapp != null) {
      map['whatsapp'] = Variable<String>(whatsapp);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || instagramUrl != null) {
      map['instagram_url'] = Variable<String>(instagramUrl);
    }
    if (!nullToAbsent || tiktokUrl != null) {
      map['tiktok_url'] = Variable<String>(tiktokUrl);
    }
    if (!nullToAbsent || facebookUrl != null) {
      map['facebook_url'] = Variable<String>(facebookUrl);
    }
    if (!nullToAbsent || youtubeUrl != null) {
      map['youtube_url'] = Variable<String>(youtubeUrl);
    }
    if (!nullToAbsent || bannerUrl != null) {
      map['banner_url'] = Variable<String>(bannerUrl);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_boosted'] = Variable<bool>(isBoosted);
    map['boost_status'] = Variable<int>(boostStatus);
    map['banner_status'] = Variable<int>(bannerStatus);
    if (!nullToAbsent || bannerText != null) {
      map['banner_text'] = Variable<String>(bannerText);
    }
    map['is_verified'] = Variable<bool>(isVerified);
    if (!nullToAbsent || responseTimeMinutes != null) {
      map['response_time_minutes'] = Variable<int>(responseTimeMinutes);
    }
    if (!nullToAbsent || commune != null) {
      map['commune'] = Variable<String>(commune);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    return map;
  }

  ShopsCompanion toCompanion(bool nullToAbsent) {
    return ShopsCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      type: Value(type),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      whatsapp: whatsapp == null && nullToAbsent
          ? const Value.absent()
          : Value(whatsapp),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      instagramUrl: instagramUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(instagramUrl),
      tiktokUrl: tiktokUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(tiktokUrl),
      facebookUrl: facebookUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(facebookUrl),
      youtubeUrl: youtubeUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(youtubeUrl),
      bannerUrl: bannerUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerUrl),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      updatedAt: Value(updatedAt),
      isBoosted: Value(isBoosted),
      boostStatus: Value(boostStatus),
      bannerStatus: Value(bannerStatus),
      bannerText: bannerText == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerText),
      isVerified: Value(isVerified),
      responseTimeMinutes: responseTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(responseTimeMinutes),
      commune: commune == null && nullToAbsent
          ? const Value.absent()
          : Value(commune),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
    );
  }

  factory Shop.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shop(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      type: $ShopsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      address: serializer.fromJson<String?>(json['address']),
      whatsapp: serializer.fromJson<String?>(json['whatsapp']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      instagramUrl: serializer.fromJson<String?>(json['instagramUrl']),
      tiktokUrl: serializer.fromJson<String?>(json['tiktokUrl']),
      facebookUrl: serializer.fromJson<String?>(json['facebookUrl']),
      youtubeUrl: serializer.fromJson<String?>(json['youtubeUrl']),
      bannerUrl: serializer.fromJson<String?>(json['bannerUrl']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isBoosted: serializer.fromJson<bool>(json['isBoosted']),
      boostStatus: serializer.fromJson<int>(json['boostStatus']),
      bannerStatus: serializer.fromJson<int>(json['bannerStatus']),
      bannerText: serializer.fromJson<String?>(json['bannerText']),
      isVerified: serializer.fromJson<bool>(json['isVerified']),
      responseTimeMinutes: serializer.fromJson<int?>(
        json['responseTimeMinutes'],
      ),
      commune: serializer.fromJson<String?>(json['commune']),
      city: serializer.fromJson<String?>(json['city']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'type': serializer.toJson<String>(
        $ShopsTable.$convertertype.toJson(type),
      ),
      'ownerId': serializer.toJson<String?>(ownerId),
      'address': serializer.toJson<String?>(address),
      'whatsapp': serializer.toJson<String?>(whatsapp),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'instagramUrl': serializer.toJson<String?>(instagramUrl),
      'tiktokUrl': serializer.toJson<String?>(tiktokUrl),
      'facebookUrl': serializer.toJson<String?>(facebookUrl),
      'youtubeUrl': serializer.toJson<String?>(youtubeUrl),
      'bannerUrl': serializer.toJson<String?>(bannerUrl),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isBoosted': serializer.toJson<bool>(isBoosted),
      'boostStatus': serializer.toJson<int>(boostStatus),
      'bannerStatus': serializer.toJson<int>(bannerStatus),
      'bannerText': serializer.toJson<String?>(bannerText),
      'isVerified': serializer.toJson<bool>(isVerified),
      'responseTimeMinutes': serializer.toJson<int?>(responseTimeMinutes),
      'commune': serializer.toJson<String?>(commune),
      'city': serializer.toJson<String?>(city),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
    };
  }

  Shop copyWith({
    int? id,
    Value<String?> remoteId = const Value.absent(),
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> logoUrl = const Value.absent(),
    ShopType? type,
    Value<String?> ownerId = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> whatsapp = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> instagramUrl = const Value.absent(),
    Value<String?> tiktokUrl = const Value.absent(),
    Value<String?> facebookUrl = const Value.absent(),
    Value<String?> youtubeUrl = const Value.absent(),
    Value<String?> bannerUrl = const Value.absent(),
    Value<String?> videoUrl = const Value.absent(),
    DateTime? updatedAt,
    bool? isBoosted,
    int? boostStatus,
    int? bannerStatus,
    Value<String?> bannerText = const Value.absent(),
    bool? isVerified,
    Value<int?> responseTimeMinutes = const Value.absent(),
    Value<String?> commune = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<DateTime?> verifiedAt = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
  }) => Shop(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    type: type ?? this.type,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    address: address.present ? address.value : this.address,
    whatsapp: whatsapp.present ? whatsapp.value : this.whatsapp,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    instagramUrl: instagramUrl.present ? instagramUrl.value : this.instagramUrl,
    tiktokUrl: tiktokUrl.present ? tiktokUrl.value : this.tiktokUrl,
    facebookUrl: facebookUrl.present ? facebookUrl.value : this.facebookUrl,
    youtubeUrl: youtubeUrl.present ? youtubeUrl.value : this.youtubeUrl,
    bannerUrl: bannerUrl.present ? bannerUrl.value : this.bannerUrl,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    updatedAt: updatedAt ?? this.updatedAt,
    isBoosted: isBoosted ?? this.isBoosted,
    boostStatus: boostStatus ?? this.boostStatus,
    bannerStatus: bannerStatus ?? this.bannerStatus,
    bannerText: bannerText.present ? bannerText.value : this.bannerText,
    isVerified: isVerified ?? this.isVerified,
    responseTimeMinutes: responseTimeMinutes.present
        ? responseTimeMinutes.value
        : this.responseTimeMinutes,
    commune: commune.present ? commune.value : this.commune,
    city: city.present ? city.value : this.city,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
  );
  Shop copyWithCompanion(ShopsCompanion data) {
    return Shop(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      type: data.type.present ? data.type.value : this.type,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      address: data.address.present ? data.address.value : this.address,
      whatsapp: data.whatsapp.present ? data.whatsapp.value : this.whatsapp,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      instagramUrl: data.instagramUrl.present
          ? data.instagramUrl.value
          : this.instagramUrl,
      tiktokUrl: data.tiktokUrl.present ? data.tiktokUrl.value : this.tiktokUrl,
      facebookUrl: data.facebookUrl.present
          ? data.facebookUrl.value
          : this.facebookUrl,
      youtubeUrl: data.youtubeUrl.present
          ? data.youtubeUrl.value
          : this.youtubeUrl,
      bannerUrl: data.bannerUrl.present ? data.bannerUrl.value : this.bannerUrl,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isBoosted: data.isBoosted.present ? data.isBoosted.value : this.isBoosted,
      boostStatus: data.boostStatus.present
          ? data.boostStatus.value
          : this.boostStatus,
      bannerStatus: data.bannerStatus.present
          ? data.bannerStatus.value
          : this.bannerStatus,
      bannerText: data.bannerText.present
          ? data.bannerText.value
          : this.bannerText,
      isVerified: data.isVerified.present
          ? data.isVerified.value
          : this.isVerified,
      responseTimeMinutes: data.responseTimeMinutes.present
          ? data.responseTimeMinutes.value
          : this.responseTimeMinutes,
      commune: data.commune.present ? data.commune.value : this.commune,
      city: data.city.present ? data.city.value : this.city,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shop(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('type: $type, ')
          ..write('ownerId: $ownerId, ')
          ..write('address: $address, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('instagramUrl: $instagramUrl, ')
          ..write('tiktokUrl: $tiktokUrl, ')
          ..write('facebookUrl: $facebookUrl, ')
          ..write('youtubeUrl: $youtubeUrl, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isBoosted: $isBoosted, ')
          ..write('boostStatus: $boostStatus, ')
          ..write('bannerStatus: $bannerStatus, ')
          ..write('bannerText: $bannerText, ')
          ..write('isVerified: $isVerified, ')
          ..write('responseTimeMinutes: $responseTimeMinutes, ')
          ..write('commune: $commune, ')
          ..write('city: $city, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    remoteId,
    name,
    description,
    logoUrl,
    type,
    ownerId,
    address,
    whatsapp,
    phone,
    email,
    instagramUrl,
    tiktokUrl,
    facebookUrl,
    youtubeUrl,
    bannerUrl,
    videoUrl,
    updatedAt,
    isBoosted,
    boostStatus,
    bannerStatus,
    bannerText,
    isVerified,
    responseTimeMinutes,
    commune,
    city,
    verifiedAt,
    latitude,
    longitude,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shop &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.description == this.description &&
          other.logoUrl == this.logoUrl &&
          other.type == this.type &&
          other.ownerId == this.ownerId &&
          other.address == this.address &&
          other.whatsapp == this.whatsapp &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.instagramUrl == this.instagramUrl &&
          other.tiktokUrl == this.tiktokUrl &&
          other.facebookUrl == this.facebookUrl &&
          other.youtubeUrl == this.youtubeUrl &&
          other.bannerUrl == this.bannerUrl &&
          other.videoUrl == this.videoUrl &&
          other.updatedAt == this.updatedAt &&
          other.isBoosted == this.isBoosted &&
          other.boostStatus == this.boostStatus &&
          other.bannerStatus == this.bannerStatus &&
          other.bannerText == this.bannerText &&
          other.isVerified == this.isVerified &&
          other.responseTimeMinutes == this.responseTimeMinutes &&
          other.commune == this.commune &&
          other.city == this.city &&
          other.verifiedAt == this.verifiedAt &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude);
}

class ShopsCompanion extends UpdateCompanion<Shop> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> logoUrl;
  final Value<ShopType> type;
  final Value<String?> ownerId;
  final Value<String?> address;
  final Value<String?> whatsapp;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> instagramUrl;
  final Value<String?> tiktokUrl;
  final Value<String?> facebookUrl;
  final Value<String?> youtubeUrl;
  final Value<String?> bannerUrl;
  final Value<String?> videoUrl;
  final Value<DateTime> updatedAt;
  final Value<bool> isBoosted;
  final Value<int> boostStatus;
  final Value<int> bannerStatus;
  final Value<String?> bannerText;
  final Value<bool> isVerified;
  final Value<int?> responseTimeMinutes;
  final Value<String?> commune;
  final Value<String?> city;
  final Value<DateTime?> verifiedAt;
  final Value<double?> latitude;
  final Value<double?> longitude;
  const ShopsCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.type = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.address = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.instagramUrl = const Value.absent(),
    this.tiktokUrl = const Value.absent(),
    this.facebookUrl = const Value.absent(),
    this.youtubeUrl = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isBoosted = const Value.absent(),
    this.boostStatus = const Value.absent(),
    this.bannerStatus = const Value.absent(),
    this.bannerText = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.responseTimeMinutes = const Value.absent(),
    this.commune = const Value.absent(),
    this.city = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
  });
  ShopsCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.logoUrl = const Value.absent(),
    required ShopType type,
    this.ownerId = const Value.absent(),
    this.address = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.instagramUrl = const Value.absent(),
    this.tiktokUrl = const Value.absent(),
    this.facebookUrl = const Value.absent(),
    this.youtubeUrl = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isBoosted = const Value.absent(),
    this.boostStatus = const Value.absent(),
    this.bannerStatus = const Value.absent(),
    this.bannerText = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.responseTimeMinutes = const Value.absent(),
    this.commune = const Value.absent(),
    this.city = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<Shop> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? logoUrl,
    Expression<String>? type,
    Expression<String>? ownerId,
    Expression<String>? address,
    Expression<String>? whatsapp,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? instagramUrl,
    Expression<String>? tiktokUrl,
    Expression<String>? facebookUrl,
    Expression<String>? youtubeUrl,
    Expression<String>? bannerUrl,
    Expression<String>? videoUrl,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isBoosted,
    Expression<int>? boostStatus,
    Expression<int>? bannerStatus,
    Expression<String>? bannerText,
    Expression<bool>? isVerified,
    Expression<int>? responseTimeMinutes,
    Expression<String>? commune,
    Expression<String>? city,
    Expression<DateTime>? verifiedAt,
    Expression<double>? latitude,
    Expression<double>? longitude,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (type != null) 'type': type,
      if (ownerId != null) 'owner_id': ownerId,
      if (address != null) 'address': address,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (instagramUrl != null) 'instagram_url': instagramUrl,
      if (tiktokUrl != null) 'tiktok_url': tiktokUrl,
      if (facebookUrl != null) 'facebook_url': facebookUrl,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isBoosted != null) 'is_boosted': isBoosted,
      if (boostStatus != null) 'boost_status': boostStatus,
      if (bannerStatus != null) 'banner_status': bannerStatus,
      if (bannerText != null) 'banner_text': bannerText,
      if (isVerified != null) 'is_verified': isVerified,
      if (responseTimeMinutes != null)
        'response_time_minutes': responseTimeMinutes,
      if (commune != null) 'commune': commune,
      if (city != null) 'city': city,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  ShopsCompanion copyWith({
    Value<int>? id,
    Value<String?>? remoteId,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? logoUrl,
    Value<ShopType>? type,
    Value<String?>? ownerId,
    Value<String?>? address,
    Value<String?>? whatsapp,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? instagramUrl,
    Value<String?>? tiktokUrl,
    Value<String?>? facebookUrl,
    Value<String?>? youtubeUrl,
    Value<String?>? bannerUrl,
    Value<String?>? videoUrl,
    Value<DateTime>? updatedAt,
    Value<bool>? isBoosted,
    Value<int>? boostStatus,
    Value<int>? bannerStatus,
    Value<String?>? bannerText,
    Value<bool>? isVerified,
    Value<int?>? responseTimeMinutes,
    Value<String?>? commune,
    Value<String?>? city,
    Value<DateTime?>? verifiedAt,
    Value<double?>? latitude,
    Value<double?>? longitude,
  }) {
    return ShopsCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      address: address ?? this.address,
      whatsapp: whatsapp ?? this.whatsapp,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      isBoosted: isBoosted ?? this.isBoosted,
      boostStatus: boostStatus ?? this.boostStatus,
      bannerStatus: bannerStatus ?? this.bannerStatus,
      bannerText: bannerText ?? this.bannerText,
      isVerified: isVerified ?? this.isVerified,
      responseTimeMinutes: responseTimeMinutes ?? this.responseTimeMinutes,
      commune: commune ?? this.commune,
      city: city ?? this.city,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $ShopsTable.$convertertype.toSql(type.value),
      );
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (whatsapp.present) {
      map['whatsapp'] = Variable<String>(whatsapp.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (instagramUrl.present) {
      map['instagram_url'] = Variable<String>(instagramUrl.value);
    }
    if (tiktokUrl.present) {
      map['tiktok_url'] = Variable<String>(tiktokUrl.value);
    }
    if (facebookUrl.present) {
      map['facebook_url'] = Variable<String>(facebookUrl.value);
    }
    if (youtubeUrl.present) {
      map['youtube_url'] = Variable<String>(youtubeUrl.value);
    }
    if (bannerUrl.present) {
      map['banner_url'] = Variable<String>(bannerUrl.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isBoosted.present) {
      map['is_boosted'] = Variable<bool>(isBoosted.value);
    }
    if (boostStatus.present) {
      map['boost_status'] = Variable<int>(boostStatus.value);
    }
    if (bannerStatus.present) {
      map['banner_status'] = Variable<int>(bannerStatus.value);
    }
    if (bannerText.present) {
      map['banner_text'] = Variable<String>(bannerText.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (responseTimeMinutes.present) {
      map['response_time_minutes'] = Variable<int>(responseTimeMinutes.value);
    }
    if (commune.present) {
      map['commune'] = Variable<String>(commune.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopsCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('type: $type, ')
          ..write('ownerId: $ownerId, ')
          ..write('address: $address, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('instagramUrl: $instagramUrl, ')
          ..write('tiktokUrl: $tiktokUrl, ')
          ..write('facebookUrl: $facebookUrl, ')
          ..write('youtubeUrl: $youtubeUrl, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isBoosted: $isBoosted, ')
          ..write('boostStatus: $boostStatus, ')
          ..write('bannerStatus: $bannerStatus, ')
          ..write('bannerText: $bannerText, ')
          ..write('isVerified: $isVerified, ')
          ..write('responseTimeMinutes: $responseTimeMinutes, ')
          ..write('commune: $commune, ')
          ..write('city: $city, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    name,
    icon,
    updatedAt,
    parentId,
    level,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String? remoteId;
  final String name;
  final String? icon;
  final DateTime updatedAt;
  final int? parentId;
  final int level;
  final int sortOrder;
  const Category({
    required this.id,
    this.remoteId,
    required this.name,
    this.icon,
    required this.updatedAt,
    this.parentId,
    required this.level,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['level'] = Variable<int>(level);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      updatedAt: Value(updatedAt),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      level: Value(level),
      sortOrder: Value(sortOrder),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      level: serializer.fromJson<int>(json['level']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'parentId': serializer.toJson<int?>(parentId),
      'level': serializer.toJson<int>(level),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Category copyWith({
    int? id,
    Value<String?> remoteId = const Value.absent(),
    String? name,
    Value<String?> icon = const Value.absent(),
    DateTime? updatedAt,
    Value<int?> parentId = const Value.absent(),
    int? level,
    int? sortOrder,
  }) => Category(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    updatedAt: updatedAt ?? this.updatedAt,
    parentId: parentId.present ? parentId.value : this.parentId,
    level: level ?? this.level,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      level: data.level.present ? data.level.value : this.level,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    name,
    icon,
    updatedAt,
    parentId,
    level,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.updatedAt == this.updatedAt &&
          other.parentId == this.parentId &&
          other.level == this.level &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<String> name;
  final Value<String?> icon;
  final Value<DateTime> updatedAt;
  final Value<int?> parentId;
  final Value<int> level;
  final Value<int> sortOrder;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<DateTime>? updatedAt,
    Expression<int>? parentId,
    Expression<int>? level,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (parentId != null) 'parent_id': parentId,
      if (level != null) 'level': level,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String?>? remoteId,
    Value<String>? name,
    Value<String?>? icon,
    Value<DateTime>? updatedAt,
    Value<int?>? parentId,
    Value<int>? level,
    Value<int>? sortOrder,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<int> shopId = GeneratedColumn<int>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shops (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlsMeta = const VerificationMeta(
    'imageUrls',
  );
  @override
  late final GeneratedColumn<String> imageUrls = GeneratedColumn<String>(
    'image_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArrivalMeta = const VerificationMeta(
    'isArrival',
  );
  @override
  late final GeneratedColumn<bool> isArrival = GeneratedColumn<bool>(
    'is_arrival',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_arrival" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPromotionMeta = const VerificationMeta(
    'isPromotion',
  );
  @override
  late final GeneratedColumn<bool> isPromotion = GeneratedColumn<bool>(
    'is_promotion',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_promotion" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _stockCountMeta = const VerificationMeta(
    'stockCount',
  );
  @override
  late final GeneratedColumn<int> stockCount = GeneratedColumn<int>(
    'stock_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hidePriceMeta = const VerificationMeta(
    'hidePrice',
  );
  @override
  late final GeneratedColumn<bool> hidePrice = GeneratedColumn<bool>(
    'hide_price',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hide_price" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showStockMeta = const VerificationMeta(
    'showStock',
  );
  @override
  late final GeneratedColumn<bool> showStock = GeneratedColumn<bool>(
    'show_stock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_stock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isBoostedMeta = const VerificationMeta(
    'isBoosted',
  );
  @override
  late final GeneratedColumn<bool> isBoosted = GeneratedColumn<bool>(
    'is_boosted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_boosted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _promotionMessageMeta = const VerificationMeta(
    'promotionMessage',
  );
  @override
  late final GeneratedColumn<String> promotionMessage = GeneratedColumn<String>(
    'promotion_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _viewsCountMeta = const VerificationMeta(
    'viewsCount',
  );
  @override
  late final GeneratedColumn<int> viewsCount = GeneratedColumn<int>(
    'views_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sharesCountMeta = const VerificationMeta(
    'sharesCount',
  );
  @override
  late final GeneratedColumn<int> sharesCount = GeneratedColumn<int>(
    'shares_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ratingsCountMeta = const VerificationMeta(
    'ratingsCount',
  );
  @override
  late final GeneratedColumn<int> ratingsCount = GeneratedColumn<int>(
    'ratings_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ratingAvgMeta = const VerificationMeta(
    'ratingAvg',
  );
  @override
  late final GeneratedColumn<double> ratingAvg = GeneratedColumn<double>(
    'rating_avg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _boostStatusMeta = const VerificationMeta(
    'boostStatus',
  );
  @override
  late final GeneratedColumn<int> boostStatus = GeneratedColumn<int>(
    'boost_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('new'),
  );
  static const VerificationMeta _reportCountMeta = const VerificationMeta(
    'reportCount',
  );
  @override
  late final GeneratedColumn<int> reportCount = GeneratedColumn<int>(
    'report_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSoldMeta = const VerificationMeta('isSold');
  @override
  late final GeneratedColumn<bool> isSold = GeneratedColumn<bool>(
    'is_sold',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sold" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    shopId,
    categoryId,
    name,
    description,
    price,
    category,
    imageUrls,
    isArrival,
    isPromotion,
    stockCount,
    hidePrice,
    showStock,
    isBoosted,
    promotionMessage,
    updatedAt,
    viewsCount,
    sharesCount,
    ratingsCount,
    ratingAvg,
    boostStatus,
    condition,
    reportCount,
    isSold,
    metadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('image_urls')) {
      context.handle(
        _imageUrlsMeta,
        imageUrls.isAcceptableOrUnknown(data['image_urls']!, _imageUrlsMeta),
      );
    } else if (isInserting) {
      context.missing(_imageUrlsMeta);
    }
    if (data.containsKey('is_arrival')) {
      context.handle(
        _isArrivalMeta,
        isArrival.isAcceptableOrUnknown(data['is_arrival']!, _isArrivalMeta),
      );
    }
    if (data.containsKey('is_promotion')) {
      context.handle(
        _isPromotionMeta,
        isPromotion.isAcceptableOrUnknown(
          data['is_promotion']!,
          _isPromotionMeta,
        ),
      );
    }
    if (data.containsKey('stock_count')) {
      context.handle(
        _stockCountMeta,
        stockCount.isAcceptableOrUnknown(data['stock_count']!, _stockCountMeta),
      );
    }
    if (data.containsKey('hide_price')) {
      context.handle(
        _hidePriceMeta,
        hidePrice.isAcceptableOrUnknown(data['hide_price']!, _hidePriceMeta),
      );
    }
    if (data.containsKey('show_stock')) {
      context.handle(
        _showStockMeta,
        showStock.isAcceptableOrUnknown(data['show_stock']!, _showStockMeta),
      );
    }
    if (data.containsKey('is_boosted')) {
      context.handle(
        _isBoostedMeta,
        isBoosted.isAcceptableOrUnknown(data['is_boosted']!, _isBoostedMeta),
      );
    }
    if (data.containsKey('promotion_message')) {
      context.handle(
        _promotionMessageMeta,
        promotionMessage.isAcceptableOrUnknown(
          data['promotion_message']!,
          _promotionMessageMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('views_count')) {
      context.handle(
        _viewsCountMeta,
        viewsCount.isAcceptableOrUnknown(data['views_count']!, _viewsCountMeta),
      );
    }
    if (data.containsKey('shares_count')) {
      context.handle(
        _sharesCountMeta,
        sharesCount.isAcceptableOrUnknown(
          data['shares_count']!,
          _sharesCountMeta,
        ),
      );
    }
    if (data.containsKey('ratings_count')) {
      context.handle(
        _ratingsCountMeta,
        ratingsCount.isAcceptableOrUnknown(
          data['ratings_count']!,
          _ratingsCountMeta,
        ),
      );
    }
    if (data.containsKey('rating_avg')) {
      context.handle(
        _ratingAvgMeta,
        ratingAvg.isAcceptableOrUnknown(data['rating_avg']!, _ratingAvgMeta),
      );
    }
    if (data.containsKey('boost_status')) {
      context.handle(
        _boostStatusMeta,
        boostStatus.isAcceptableOrUnknown(
          data['boost_status']!,
          _boostStatusMeta,
        ),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('report_count')) {
      context.handle(
        _reportCountMeta,
        reportCount.isAcceptableOrUnknown(
          data['report_count']!,
          _reportCountMeta,
        ),
      );
    }
    if (data.containsKey('is_sold')) {
      context.handle(
        _isSoldMeta,
        isSold.isAcceptableOrUnknown(data['is_sold']!, _isSoldMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shop_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      imageUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_urls'],
      )!,
      isArrival: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_arrival'],
      )!,
      isPromotion: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_promotion'],
      )!,
      stockCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_count'],
      ),
      hidePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hide_price'],
      )!,
      showStock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_stock'],
      )!,
      isBoosted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_boosted'],
      )!,
      promotionMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promotion_message'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      viewsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}views_count'],
      )!,
      sharesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shares_count'],
      )!,
      ratingsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ratings_count'],
      )!,
      ratingAvg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating_avg'],
      )!,
      boostStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}boost_status'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      )!,
      reportCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}report_count'],
      )!,
      isSold: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sold'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String? remoteId;
  final int shopId;
  final int? categoryId;
  final String name;
  final String? description;
  final double? price;
  final String? category;
  final String imageUrls;
  final bool isArrival;
  final bool isPromotion;
  final int? stockCount;
  final bool hidePrice;
  final bool showStock;
  final bool isBoosted;
  final String? promotionMessage;
  final DateTime updatedAt;
  final int viewsCount;
  final int sharesCount;
  final int ratingsCount;
  final double ratingAvg;
  final int boostStatus;
  final String condition;
  final int reportCount;
  final bool isSold;
  final String? metadata;
  const Product({
    required this.id,
    this.remoteId,
    required this.shopId,
    this.categoryId,
    required this.name,
    this.description,
    this.price,
    this.category,
    required this.imageUrls,
    required this.isArrival,
    required this.isPromotion,
    this.stockCount,
    required this.hidePrice,
    required this.showStock,
    required this.isBoosted,
    this.promotionMessage,
    required this.updatedAt,
    required this.viewsCount,
    required this.sharesCount,
    required this.ratingsCount,
    required this.ratingAvg,
    required this.boostStatus,
    required this.condition,
    required this.reportCount,
    required this.isSold,
    this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['shop_id'] = Variable<int>(shopId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['image_urls'] = Variable<String>(imageUrls);
    map['is_arrival'] = Variable<bool>(isArrival);
    map['is_promotion'] = Variable<bool>(isPromotion);
    if (!nullToAbsent || stockCount != null) {
      map['stock_count'] = Variable<int>(stockCount);
    }
    map['hide_price'] = Variable<bool>(hidePrice);
    map['show_stock'] = Variable<bool>(showStock);
    map['is_boosted'] = Variable<bool>(isBoosted);
    if (!nullToAbsent || promotionMessage != null) {
      map['promotion_message'] = Variable<String>(promotionMessage);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['views_count'] = Variable<int>(viewsCount);
    map['shares_count'] = Variable<int>(sharesCount);
    map['ratings_count'] = Variable<int>(ratingsCount);
    map['rating_avg'] = Variable<double>(ratingAvg);
    map['boost_status'] = Variable<int>(boostStatus);
    map['condition'] = Variable<String>(condition);
    map['report_count'] = Variable<int>(reportCount);
    map['is_sold'] = Variable<bool>(isSold);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      shopId: Value(shopId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      imageUrls: Value(imageUrls),
      isArrival: Value(isArrival),
      isPromotion: Value(isPromotion),
      stockCount: stockCount == null && nullToAbsent
          ? const Value.absent()
          : Value(stockCount),
      hidePrice: Value(hidePrice),
      showStock: Value(showStock),
      isBoosted: Value(isBoosted),
      promotionMessage: promotionMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(promotionMessage),
      updatedAt: Value(updatedAt),
      viewsCount: Value(viewsCount),
      sharesCount: Value(sharesCount),
      ratingsCount: Value(ratingsCount),
      ratingAvg: Value(ratingAvg),
      boostStatus: Value(boostStatus),
      condition: Value(condition),
      reportCount: Value(reportCount),
      isSold: Value(isSold),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      shopId: serializer.fromJson<int>(json['shopId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<double?>(json['price']),
      category: serializer.fromJson<String?>(json['category']),
      imageUrls: serializer.fromJson<String>(json['imageUrls']),
      isArrival: serializer.fromJson<bool>(json['isArrival']),
      isPromotion: serializer.fromJson<bool>(json['isPromotion']),
      stockCount: serializer.fromJson<int?>(json['stockCount']),
      hidePrice: serializer.fromJson<bool>(json['hidePrice']),
      showStock: serializer.fromJson<bool>(json['showStock']),
      isBoosted: serializer.fromJson<bool>(json['isBoosted']),
      promotionMessage: serializer.fromJson<String?>(json['promotionMessage']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      viewsCount: serializer.fromJson<int>(json['viewsCount']),
      sharesCount: serializer.fromJson<int>(json['sharesCount']),
      ratingsCount: serializer.fromJson<int>(json['ratingsCount']),
      ratingAvg: serializer.fromJson<double>(json['ratingAvg']),
      boostStatus: serializer.fromJson<int>(json['boostStatus']),
      condition: serializer.fromJson<String>(json['condition']),
      reportCount: serializer.fromJson<int>(json['reportCount']),
      isSold: serializer.fromJson<bool>(json['isSold']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'shopId': serializer.toJson<int>(shopId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<double?>(price),
      'category': serializer.toJson<String?>(category),
      'imageUrls': serializer.toJson<String>(imageUrls),
      'isArrival': serializer.toJson<bool>(isArrival),
      'isPromotion': serializer.toJson<bool>(isPromotion),
      'stockCount': serializer.toJson<int?>(stockCount),
      'hidePrice': serializer.toJson<bool>(hidePrice),
      'showStock': serializer.toJson<bool>(showStock),
      'isBoosted': serializer.toJson<bool>(isBoosted),
      'promotionMessage': serializer.toJson<String?>(promotionMessage),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'viewsCount': serializer.toJson<int>(viewsCount),
      'sharesCount': serializer.toJson<int>(sharesCount),
      'ratingsCount': serializer.toJson<int>(ratingsCount),
      'ratingAvg': serializer.toJson<double>(ratingAvg),
      'boostStatus': serializer.toJson<int>(boostStatus),
      'condition': serializer.toJson<String>(condition),
      'reportCount': serializer.toJson<int>(reportCount),
      'isSold': serializer.toJson<bool>(isSold),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  Product copyWith({
    int? id,
    Value<String?> remoteId = const Value.absent(),
    int? shopId,
    Value<int?> categoryId = const Value.absent(),
    String? name,
    Value<String?> description = const Value.absent(),
    Value<double?> price = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? imageUrls,
    bool? isArrival,
    bool? isPromotion,
    Value<int?> stockCount = const Value.absent(),
    bool? hidePrice,
    bool? showStock,
    bool? isBoosted,
    Value<String?> promotionMessage = const Value.absent(),
    DateTime? updatedAt,
    int? viewsCount,
    int? sharesCount,
    int? ratingsCount,
    double? ratingAvg,
    int? boostStatus,
    String? condition,
    int? reportCount,
    bool? isSold,
    Value<String?> metadata = const Value.absent(),
  }) => Product(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    shopId: shopId ?? this.shopId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    price: price.present ? price.value : this.price,
    category: category.present ? category.value : this.category,
    imageUrls: imageUrls ?? this.imageUrls,
    isArrival: isArrival ?? this.isArrival,
    isPromotion: isPromotion ?? this.isPromotion,
    stockCount: stockCount.present ? stockCount.value : this.stockCount,
    hidePrice: hidePrice ?? this.hidePrice,
    showStock: showStock ?? this.showStock,
    isBoosted: isBoosted ?? this.isBoosted,
    promotionMessage: promotionMessage.present
        ? promotionMessage.value
        : this.promotionMessage,
    updatedAt: updatedAt ?? this.updatedAt,
    viewsCount: viewsCount ?? this.viewsCount,
    sharesCount: sharesCount ?? this.sharesCount,
    ratingsCount: ratingsCount ?? this.ratingsCount,
    ratingAvg: ratingAvg ?? this.ratingAvg,
    boostStatus: boostStatus ?? this.boostStatus,
    condition: condition ?? this.condition,
    reportCount: reportCount ?? this.reportCount,
    isSold: isSold ?? this.isSold,
    metadata: metadata.present ? metadata.value : this.metadata,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      price: data.price.present ? data.price.value : this.price,
      category: data.category.present ? data.category.value : this.category,
      imageUrls: data.imageUrls.present ? data.imageUrls.value : this.imageUrls,
      isArrival: data.isArrival.present ? data.isArrival.value : this.isArrival,
      isPromotion: data.isPromotion.present
          ? data.isPromotion.value
          : this.isPromotion,
      stockCount: data.stockCount.present
          ? data.stockCount.value
          : this.stockCount,
      hidePrice: data.hidePrice.present ? data.hidePrice.value : this.hidePrice,
      showStock: data.showStock.present ? data.showStock.value : this.showStock,
      isBoosted: data.isBoosted.present ? data.isBoosted.value : this.isBoosted,
      promotionMessage: data.promotionMessage.present
          ? data.promotionMessage.value
          : this.promotionMessage,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      viewsCount: data.viewsCount.present
          ? data.viewsCount.value
          : this.viewsCount,
      sharesCount: data.sharesCount.present
          ? data.sharesCount.value
          : this.sharesCount,
      ratingsCount: data.ratingsCount.present
          ? data.ratingsCount.value
          : this.ratingsCount,
      ratingAvg: data.ratingAvg.present ? data.ratingAvg.value : this.ratingAvg,
      boostStatus: data.boostStatus.present
          ? data.boostStatus.value
          : this.boostStatus,
      condition: data.condition.present ? data.condition.value : this.condition,
      reportCount: data.reportCount.present
          ? data.reportCount.value
          : this.reportCount,
      isSold: data.isSold.present ? data.isSold.value : this.isSold,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('shopId: $shopId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('category: $category, ')
          ..write('imageUrls: $imageUrls, ')
          ..write('isArrival: $isArrival, ')
          ..write('isPromotion: $isPromotion, ')
          ..write('stockCount: $stockCount, ')
          ..write('hidePrice: $hidePrice, ')
          ..write('showStock: $showStock, ')
          ..write('isBoosted: $isBoosted, ')
          ..write('promotionMessage: $promotionMessage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('viewsCount: $viewsCount, ')
          ..write('sharesCount: $sharesCount, ')
          ..write('ratingsCount: $ratingsCount, ')
          ..write('ratingAvg: $ratingAvg, ')
          ..write('boostStatus: $boostStatus, ')
          ..write('condition: $condition, ')
          ..write('reportCount: $reportCount, ')
          ..write('isSold: $isSold, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    remoteId,
    shopId,
    categoryId,
    name,
    description,
    price,
    category,
    imageUrls,
    isArrival,
    isPromotion,
    stockCount,
    hidePrice,
    showStock,
    isBoosted,
    promotionMessage,
    updatedAt,
    viewsCount,
    sharesCount,
    ratingsCount,
    ratingAvg,
    boostStatus,
    condition,
    reportCount,
    isSold,
    metadata,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.shopId == this.shopId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.category == this.category &&
          other.imageUrls == this.imageUrls &&
          other.isArrival == this.isArrival &&
          other.isPromotion == this.isPromotion &&
          other.stockCount == this.stockCount &&
          other.hidePrice == this.hidePrice &&
          other.showStock == this.showStock &&
          other.isBoosted == this.isBoosted &&
          other.promotionMessage == this.promotionMessage &&
          other.updatedAt == this.updatedAt &&
          other.viewsCount == this.viewsCount &&
          other.sharesCount == this.sharesCount &&
          other.ratingsCount == this.ratingsCount &&
          other.ratingAvg == this.ratingAvg &&
          other.boostStatus == this.boostStatus &&
          other.condition == this.condition &&
          other.reportCount == this.reportCount &&
          other.isSold == this.isSold &&
          other.metadata == this.metadata);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<int> shopId;
  final Value<int?> categoryId;
  final Value<String> name;
  final Value<String?> description;
  final Value<double?> price;
  final Value<String?> category;
  final Value<String> imageUrls;
  final Value<bool> isArrival;
  final Value<bool> isPromotion;
  final Value<int?> stockCount;
  final Value<bool> hidePrice;
  final Value<bool> showStock;
  final Value<bool> isBoosted;
  final Value<String?> promotionMessage;
  final Value<DateTime> updatedAt;
  final Value<int> viewsCount;
  final Value<int> sharesCount;
  final Value<int> ratingsCount;
  final Value<double> ratingAvg;
  final Value<int> boostStatus;
  final Value<String> condition;
  final Value<int> reportCount;
  final Value<bool> isSold;
  final Value<String?> metadata;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.shopId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.category = const Value.absent(),
    this.imageUrls = const Value.absent(),
    this.isArrival = const Value.absent(),
    this.isPromotion = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.hidePrice = const Value.absent(),
    this.showStock = const Value.absent(),
    this.isBoosted = const Value.absent(),
    this.promotionMessage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.viewsCount = const Value.absent(),
    this.sharesCount = const Value.absent(),
    this.ratingsCount = const Value.absent(),
    this.ratingAvg = const Value.absent(),
    this.boostStatus = const Value.absent(),
    this.condition = const Value.absent(),
    this.reportCount = const Value.absent(),
    this.isSold = const Value.absent(),
    this.metadata = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int shopId,
    this.categoryId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.category = const Value.absent(),
    required String imageUrls,
    this.isArrival = const Value.absent(),
    this.isPromotion = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.hidePrice = const Value.absent(),
    this.showStock = const Value.absent(),
    this.isBoosted = const Value.absent(),
    this.promotionMessage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.viewsCount = const Value.absent(),
    this.sharesCount = const Value.absent(),
    this.ratingsCount = const Value.absent(),
    this.ratingAvg = const Value.absent(),
    this.boostStatus = const Value.absent(),
    this.condition = const Value.absent(),
    this.reportCount = const Value.absent(),
    this.isSold = const Value.absent(),
    this.metadata = const Value.absent(),
  }) : shopId = Value(shopId),
       name = Value(name),
       imageUrls = Value(imageUrls);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<int>? shopId,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<String>? category,
    Expression<String>? imageUrls,
    Expression<bool>? isArrival,
    Expression<bool>? isPromotion,
    Expression<int>? stockCount,
    Expression<bool>? hidePrice,
    Expression<bool>? showStock,
    Expression<bool>? isBoosted,
    Expression<String>? promotionMessage,
    Expression<DateTime>? updatedAt,
    Expression<int>? viewsCount,
    Expression<int>? sharesCount,
    Expression<int>? ratingsCount,
    Expression<double>? ratingAvg,
    Expression<int>? boostStatus,
    Expression<String>? condition,
    Expression<int>? reportCount,
    Expression<bool>? isSold,
    Expression<String>? metadata,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (shopId != null) 'shop_id': shopId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      if (imageUrls != null) 'image_urls': imageUrls,
      if (isArrival != null) 'is_arrival': isArrival,
      if (isPromotion != null) 'is_promotion': isPromotion,
      if (stockCount != null) 'stock_count': stockCount,
      if (hidePrice != null) 'hide_price': hidePrice,
      if (showStock != null) 'show_stock': showStock,
      if (isBoosted != null) 'is_boosted': isBoosted,
      if (promotionMessage != null) 'promotion_message': promotionMessage,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (viewsCount != null) 'views_count': viewsCount,
      if (sharesCount != null) 'shares_count': sharesCount,
      if (ratingsCount != null) 'ratings_count': ratingsCount,
      if (ratingAvg != null) 'rating_avg': ratingAvg,
      if (boostStatus != null) 'boost_status': boostStatus,
      if (condition != null) 'condition': condition,
      if (reportCount != null) 'report_count': reportCount,
      if (isSold != null) 'is_sold': isSold,
      if (metadata != null) 'metadata': metadata,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String?>? remoteId,
    Value<int>? shopId,
    Value<int?>? categoryId,
    Value<String>? name,
    Value<String?>? description,
    Value<double?>? price,
    Value<String?>? category,
    Value<String>? imageUrls,
    Value<bool>? isArrival,
    Value<bool>? isPromotion,
    Value<int?>? stockCount,
    Value<bool>? hidePrice,
    Value<bool>? showStock,
    Value<bool>? isBoosted,
    Value<String?>? promotionMessage,
    Value<DateTime>? updatedAt,
    Value<int>? viewsCount,
    Value<int>? sharesCount,
    Value<int>? ratingsCount,
    Value<double>? ratingAvg,
    Value<int>? boostStatus,
    Value<String>? condition,
    Value<int>? reportCount,
    Value<bool>? isSold,
    Value<String?>? metadata,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      shopId: shopId ?? this.shopId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      isArrival: isArrival ?? this.isArrival,
      isPromotion: isPromotion ?? this.isPromotion,
      stockCount: stockCount ?? this.stockCount,
      hidePrice: hidePrice ?? this.hidePrice,
      showStock: showStock ?? this.showStock,
      isBoosted: isBoosted ?? this.isBoosted,
      promotionMessage: promotionMessage ?? this.promotionMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      boostStatus: boostStatus ?? this.boostStatus,
      condition: condition ?? this.condition,
      reportCount: reportCount ?? this.reportCount,
      isSold: isSold ?? this.isSold,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<int>(shopId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (imageUrls.present) {
      map['image_urls'] = Variable<String>(imageUrls.value);
    }
    if (isArrival.present) {
      map['is_arrival'] = Variable<bool>(isArrival.value);
    }
    if (isPromotion.present) {
      map['is_promotion'] = Variable<bool>(isPromotion.value);
    }
    if (stockCount.present) {
      map['stock_count'] = Variable<int>(stockCount.value);
    }
    if (hidePrice.present) {
      map['hide_price'] = Variable<bool>(hidePrice.value);
    }
    if (showStock.present) {
      map['show_stock'] = Variable<bool>(showStock.value);
    }
    if (isBoosted.present) {
      map['is_boosted'] = Variable<bool>(isBoosted.value);
    }
    if (promotionMessage.present) {
      map['promotion_message'] = Variable<String>(promotionMessage.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (viewsCount.present) {
      map['views_count'] = Variable<int>(viewsCount.value);
    }
    if (sharesCount.present) {
      map['shares_count'] = Variable<int>(sharesCount.value);
    }
    if (ratingsCount.present) {
      map['ratings_count'] = Variable<int>(ratingsCount.value);
    }
    if (ratingAvg.present) {
      map['rating_avg'] = Variable<double>(ratingAvg.value);
    }
    if (boostStatus.present) {
      map['boost_status'] = Variable<int>(boostStatus.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (reportCount.present) {
      map['report_count'] = Variable<int>(reportCount.value);
    }
    if (isSold.present) {
      map['is_sold'] = Variable<bool>(isSold.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('shopId: $shopId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('category: $category, ')
          ..write('imageUrls: $imageUrls, ')
          ..write('isArrival: $isArrival, ')
          ..write('isPromotion: $isPromotion, ')
          ..write('stockCount: $stockCount, ')
          ..write('hidePrice: $hidePrice, ')
          ..write('showStock: $showStock, ')
          ..write('isBoosted: $isBoosted, ')
          ..write('promotionMessage: $promotionMessage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('viewsCount: $viewsCount, ')
          ..write('sharesCount: $sharesCount, ')
          ..write('ratingsCount: $ratingsCount, ')
          ..write('ratingAvg: $ratingAvg, ')
          ..write('boostStatus: $boostStatus, ')
          ..write('condition: $condition, ')
          ..write('reportCount: $reportCount, ')
          ..write('isSold: $isSold, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }
}

class $StoriesTable extends Stories with TableInfo<$StoriesTable, Story> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<int> shopId = GeneratedColumn<int>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shops (id)',
    ),
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArrivageMeta = const VerificationMeta(
    'isArrivage',
  );
  @override
  late final GeneratedColumn<bool> isArrivage = GeneratedColumn<bool>(
    'is_arrivage',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_arrivage" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    shopId,
    mediaUrl,
    mediaType,
    isArrivage,
    expiresAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Story> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaUrlMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('is_arrivage')) {
      context.handle(
        _isArrivageMeta,
        isArrivage.isAcceptableOrUnknown(data['is_arrivage']!, _isArrivageMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Story map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Story(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shop_id'],
      )!,
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      isArrivage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_arrivage'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StoriesTable createAlias(String alias) {
    return $StoriesTable(attachedDatabase, alias);
  }
}

class Story extends DataClass implements Insertable<Story> {
  final int id;
  final String? remoteId;
  final int shopId;
  final String mediaUrl;
  final String mediaType;
  final bool isArrivage;
  final DateTime expiresAt;
  final DateTime createdAt;
  const Story({
    required this.id,
    this.remoteId,
    required this.shopId,
    required this.mediaUrl,
    required this.mediaType,
    required this.isArrivage,
    required this.expiresAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['shop_id'] = Variable<int>(shopId);
    map['media_url'] = Variable<String>(mediaUrl);
    map['media_type'] = Variable<String>(mediaType);
    map['is_arrivage'] = Variable<bool>(isArrivage);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StoriesCompanion toCompanion(bool nullToAbsent) {
    return StoriesCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      shopId: Value(shopId),
      mediaUrl: Value(mediaUrl),
      mediaType: Value(mediaType),
      isArrivage: Value(isArrivage),
      expiresAt: Value(expiresAt),
      createdAt: Value(createdAt),
    );
  }

  factory Story.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Story(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      shopId: serializer.fromJson<int>(json['shopId']),
      mediaUrl: serializer.fromJson<String>(json['mediaUrl']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      isArrivage: serializer.fromJson<bool>(json['isArrivage']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'shopId': serializer.toJson<int>(shopId),
      'mediaUrl': serializer.toJson<String>(mediaUrl),
      'mediaType': serializer.toJson<String>(mediaType),
      'isArrivage': serializer.toJson<bool>(isArrivage),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Story copyWith({
    int? id,
    Value<String?> remoteId = const Value.absent(),
    int? shopId,
    String? mediaUrl,
    String? mediaType,
    bool? isArrivage,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) => Story(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    shopId: shopId ?? this.shopId,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    mediaType: mediaType ?? this.mediaType,
    isArrivage: isArrivage ?? this.isArrivage,
    expiresAt: expiresAt ?? this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Story copyWithCompanion(StoriesCompanion data) {
    return Story(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      isArrivage: data.isArrivage.present
          ? data.isArrivage.value
          : this.isArrivage,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Story(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('shopId: $shopId, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaType: $mediaType, ')
          ..write('isArrivage: $isArrivage, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    shopId,
    mediaUrl,
    mediaType,
    isArrivage,
    expiresAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Story &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.shopId == this.shopId &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaType == this.mediaType &&
          other.isArrivage == this.isArrivage &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt);
}

class StoriesCompanion extends UpdateCompanion<Story> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<int> shopId;
  final Value<String> mediaUrl;
  final Value<String> mediaType;
  final Value<bool> isArrivage;
  final Value<DateTime> expiresAt;
  final Value<DateTime> createdAt;
  const StoriesCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.shopId = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.isArrivage = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StoriesCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required int shopId,
    required String mediaUrl,
    required String mediaType,
    this.isArrivage = const Value.absent(),
    required DateTime expiresAt,
    this.createdAt = const Value.absent(),
  }) : shopId = Value(shopId),
       mediaUrl = Value(mediaUrl),
       mediaType = Value(mediaType),
       expiresAt = Value(expiresAt);
  static Insertable<Story> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<int>? shopId,
    Expression<String>? mediaUrl,
    Expression<String>? mediaType,
    Expression<bool>? isArrivage,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (shopId != null) 'shop_id': shopId,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaType != null) 'media_type': mediaType,
      if (isArrivage != null) 'is_arrivage': isArrivage,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StoriesCompanion copyWith({
    Value<int>? id,
    Value<String?>? remoteId,
    Value<int>? shopId,
    Value<String>? mediaUrl,
    Value<String>? mediaType,
    Value<bool>? isArrivage,
    Value<DateTime>? expiresAt,
    Value<DateTime>? createdAt,
  }) {
    return StoriesCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      shopId: shopId ?? this.shopId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      isArrivage: isArrivage ?? this.isArrivage,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<int>(shopId.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (isArrivage.present) {
      map['is_arrivage'] = Variable<bool>(isArrivage.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoriesCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('shopId: $shopId, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaType: $mediaType, ')
          ..write('isArrivage: $isArrivage, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityDataMeta = const VerificationMeta(
    'entityData',
  );
  @override
  late final GeneratedColumn<String> entityData = GeneratedColumn<String>(
    'entity_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    action,
    entityType,
    entityData,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_data')) {
      context.handle(
        _entityDataMeta,
        entityData.isAcceptableOrUnknown(data['entity_data']!, _entityDataMeta),
      );
    } else if (isInserting) {
      context.missing(_entityDataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_data'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String action;
  final String entityType;
  final String entityData;
  final DateTime createdAt;
  const SyncQueueData({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityData,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_data'] = Variable<String>(entityData);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      action: Value(action),
      entityType: Value(entityType),
      entityData: Value(entityData),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityData: serializer.fromJson<String>(json['entityData']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityData': serializer.toJson<String>(entityData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? action,
    String? entityType,
    String? entityData,
    DateTime? createdAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    entityData: entityData ?? this.entityData,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityData: data.entityData.present
          ? data.entityData.value
          : this.entityData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityData: $entityData, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, action, entityType, entityData, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityData == this.entityData &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String> entityData;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityData = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String action,
    required String entityType,
    required String entityData,
    this.createdAt = const Value.absent(),
  }) : action = Value(action),
       entityType = Value(entityType),
       entityData = Value(entityData);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityData,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityData != null) 'entity_data': entityData,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? action,
    Value<String>? entityType,
    Value<String>? entityData,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityData: entityData ?? this.entityData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityData.present) {
      map['entity_data'] = Variable<String>(entityData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityData: $entityData, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OfflineQueueTable extends OfflineQueue
    with TableInfo<$OfflineQueueTable, OfflineQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    action,
    payload,
    status,
    retryCount,
    createdAt,
    lastAttemptAt,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $OfflineQueueTable createAlias(String alias) {
    return $OfflineQueueTable(attachedDatabase, alias);
  }
}

class OfflineQueueData extends DataClass
    implements Insertable<OfflineQueueData> {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  const OfflineQueueData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  OfflineQueueCompanion toCompanion(bool nullToAbsent) {
    return OfflineQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payload: Value(payload),
      status: Value(status),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory OfflineQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineQueueData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  OfflineQueueData copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? action,
    String? payload,
    String? status,
    int? retryCount,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => OfflineQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  OfflineQueueData copyWithCompanion(OfflineQueueCompanion data) {
    return OfflineQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    action,
    payload,
    status,
    retryCount,
    createdAt,
    lastAttemptAt,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.errorMessage == this.errorMessage);
}

class OfflineQueueCompanion extends UpdateCompanion<OfflineQueueData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const OfflineQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineQueueCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       payload = Value(payload);
  static Insertable<OfflineQueueData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return OfflineQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalyticsTable extends Analytics
    with TableInfo<$AnalyticsTable, Analytic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalyticsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interactionTypeMeta = const VerificationMeta(
    'interactionType',
  );
  @override
  late final GeneratedColumn<String> interactionType = GeneratedColumn<String>(
    'interaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    interactionType,
    entityId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analytics';
  @override
  VerificationContext validateIntegrity(
    Insertable<Analytic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('interaction_type')) {
      context.handle(
        _interactionTypeMeta,
        interactionType.isAcceptableOrUnknown(
          data['interaction_type']!,
          _interactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_interactionTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Analytic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Analytic(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      interactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interaction_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entity_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnalyticsTable createAlias(String alias) {
    return $AnalyticsTable(attachedDatabase, alias);
  }
}

class Analytic extends DataClass implements Insertable<Analytic> {
  final int id;
  final String entityType;
  final String interactionType;
  final int entityId;
  final DateTime createdAt;
  const Analytic({
    required this.id,
    required this.entityType,
    required this.interactionType,
    required this.entityId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['interaction_type'] = Variable<String>(interactionType);
    map['entity_id'] = Variable<int>(entityId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnalyticsCompanion toCompanion(bool nullToAbsent) {
    return AnalyticsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      interactionType: Value(interactionType),
      entityId: Value(entityId),
      createdAt: Value(createdAt),
    );
  }

  factory Analytic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Analytic(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      interactionType: serializer.fromJson<String>(json['interactionType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'interactionType': serializer.toJson<String>(interactionType),
      'entityId': serializer.toJson<int>(entityId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Analytic copyWith({
    int? id,
    String? entityType,
    String? interactionType,
    int? entityId,
    DateTime? createdAt,
  }) => Analytic(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    interactionType: interactionType ?? this.interactionType,
    entityId: entityId ?? this.entityId,
    createdAt: createdAt ?? this.createdAt,
  );
  Analytic copyWithCompanion(AnalyticsCompanion data) {
    return Analytic(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      interactionType: data.interactionType.present
          ? data.interactionType.value
          : this.interactionType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Analytic(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('interactionType: $interactionType, ')
          ..write('entityId: $entityId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityType, interactionType, entityId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Analytic &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.interactionType == this.interactionType &&
          other.entityId == this.entityId &&
          other.createdAt == this.createdAt);
}

class AnalyticsCompanion extends UpdateCompanion<Analytic> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> interactionType;
  final Value<int> entityId;
  final Value<DateTime> createdAt;
  const AnalyticsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.interactionType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnalyticsCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String interactionType,
    required int entityId,
    this.createdAt = const Value.absent(),
  }) : entityType = Value(entityType),
       interactionType = Value(interactionType),
       entityId = Value(entityId);
  static Insertable<Analytic> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? interactionType,
    Expression<int>? entityId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (interactionType != null) 'interaction_type': interactionType,
      if (entityId != null) 'entity_id': entityId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnalyticsCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? interactionType,
    Value<int>? entityId,
    Value<DateTime>? createdAt,
  }) {
    return AnalyticsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      interactionType: interactionType ?? this.interactionType,
      entityId: entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (interactionType.present) {
      map['interaction_type'] = Variable<String>(interactionType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('interactionType: $interactionType, ')
          ..write('entityId: $entityId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 7,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPhoneVerifiedMeta = const VerificationMeta(
    'isPhoneVerified',
  );
  @override
  late final GeneratedColumn<bool> isPhoneVerified = GeneratedColumn<bool>(
    'is_phone_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_phone_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    phone,
    name,
    avatarUrl,
    isPhoneVerified,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('is_phone_verified')) {
      context.handle(
        _isPhoneVerifiedMeta,
        isPhoneVerified.isAcceptableOrUnknown(
          data['is_phone_verified']!,
          _isPhoneVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      isPhoneVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_phone_verified'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final int id;
  final String? remoteId;
  final String phone;
  final String? name;
  final String? avatarUrl;
  final bool isPhoneVerified;
  final DateTime createdAt;
  const UserProfile({
    required this.id,
    this.remoteId,
    required this.phone,
    this.name,
    this.avatarUrl,
    required this.isPhoneVerified,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['is_phone_verified'] = Variable<bool>(isPhoneVerified);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      phone: Value(phone),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      isPhoneVerified: Value(isPhoneVerified),
      createdAt: Value(createdAt),
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      phone: serializer.fromJson<String>(json['phone']),
      name: serializer.fromJson<String?>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      isPhoneVerified: serializer.fromJson<bool>(json['isPhoneVerified']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'phone': serializer.toJson<String>(phone),
      'name': serializer.toJson<String?>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'isPhoneVerified': serializer.toJson<bool>(isPhoneVerified),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserProfile copyWith({
    int? id,
    Value<String?> remoteId = const Value.absent(),
    String? phone,
    Value<String?> name = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    bool? isPhoneVerified,
    DateTime? createdAt,
  }) => UserProfile(
    id: id ?? this.id,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    phone: phone ?? this.phone,
    name: name.present ? name.value : this.name,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    createdAt: createdAt ?? this.createdAt,
  );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      phone: data.phone.present ? data.phone.value : this.phone,
      name: data.name.present ? data.name.value : this.name,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      isPhoneVerified: data.isPhoneVerified.present
          ? data.isPhoneVerified.value
          : this.isPhoneVerified,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('phone: $phone, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isPhoneVerified: $isPhoneVerified, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    phone,
    name,
    avatarUrl,
    isPhoneVerified,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.phone == this.phone &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.isPhoneVerified == this.isPhoneVerified &&
          other.createdAt == this.createdAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<String> phone;
  final Value<String?> name;
  final Value<String?> avatarUrl;
  final Value<bool> isPhoneVerified;
  final Value<DateTime> createdAt;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.phone = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isPhoneVerified = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String phone,
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isPhoneVerified = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : phone = Value(phone);
  static Insertable<UserProfile> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? phone,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<bool>? isPhoneVerified,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (phone != null) 'phone': phone,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isPhoneVerified != null) 'is_phone_verified': isPhoneVerified,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<String?>? remoteId,
    Value<String>? phone,
    Value<String?>? name,
    Value<String?>? avatarUrl,
    Value<bool>? isPhoneVerified,
    Value<DateTime>? createdAt,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (isPhoneVerified.present) {
      map['is_phone_verified'] = Variable<bool>(isPhoneVerified.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('phone: $phone, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isPhoneVerified: $isPhoneVerified, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CartItemsTable extends CartItems
    with TableInfo<$CartItemsTable, CartItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CartItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, productId, quantity, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cart_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CartItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CartItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CartItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CartItemsTable createAlias(String alias) {
    return $CartItemsTable(attachedDatabase, alias);
  }
}

class CartItem extends DataClass implements Insertable<CartItem> {
  final int id;
  final int productId;
  final int quantity;
  final DateTime createdAt;
  const CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CartItemsCompanion toCompanion(bool nullToAbsent) {
    return CartItemsCompanion(
      id: Value(id),
      productId: Value(productId),
      quantity: Value(quantity),
      createdAt: Value(createdAt),
    );
  }

  factory CartItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CartItem(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CartItem copyWith({
    int? id,
    int? productId,
    int? quantity,
    DateTime? createdAt,
  }) => CartItem(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    createdAt: createdAt ?? this.createdAt,
  );
  CartItem copyWithCompanion(CartItemsCompanion data) {
    return CartItem(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CartItem(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, quantity, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartItem &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.createdAt == this.createdAt);
}

class CartItemsCompanion extends UpdateCompanion<CartItem> {
  final Value<int> id;
  final Value<int> productId;
  final Value<int> quantity;
  final Value<DateTime> createdAt;
  const CartItemsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CartItemsCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    this.quantity = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : productId = Value(productId);
  static Insertable<CartItem> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<int>? quantity,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CartItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<int>? quantity,
    Value<DateTime>? createdAt,
  }) {
    return CartItemsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartItemsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UserContactsTable extends UserContacts
    with TableInfo<$UserContactsTable, UserContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<int> shopId = GeneratedColumn<int>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shops (id)',
    ),
  );
  static const VerificationMeta _userPhoneMeta = const VerificationMeta(
    'userPhone',
  );
  @override
  late final GeneratedColumn<String> userPhone = GeneratedColumn<String>(
    'user_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactTypeMeta = const VerificationMeta(
    'contactType',
  );
  @override
  late final GeneratedColumn<String> contactType = GeneratedColumn<String>(
    'contact_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shopId,
    userPhone,
    userName,
    contactType,
    productId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserContact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('user_phone')) {
      context.handle(
        _userPhoneMeta,
        userPhone.isAcceptableOrUnknown(data['user_phone']!, _userPhoneMeta),
      );
    } else if (isInserting) {
      context.missing(_userPhoneMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('contact_type')) {
      context.handle(
        _contactTypeMeta,
        contactType.isAcceptableOrUnknown(
          data['contact_type']!,
          _contactTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactTypeMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserContact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shop_id'],
      )!,
      userPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_phone'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      ),
      contactType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_type'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserContactsTable createAlias(String alias) {
    return $UserContactsTable(attachedDatabase, alias);
  }
}

class UserContact extends DataClass implements Insertable<UserContact> {
  final int id;
  final int shopId;
  final String userPhone;
  final String? userName;
  final String contactType;
  final int? productId;
  final DateTime createdAt;
  const UserContact({
    required this.id,
    required this.shopId,
    required this.userPhone,
    this.userName,
    required this.contactType,
    this.productId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shop_id'] = Variable<int>(shopId);
    map['user_phone'] = Variable<String>(userPhone);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    map['contact_type'] = Variable<String>(contactType);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserContactsCompanion toCompanion(bool nullToAbsent) {
    return UserContactsCompanion(
      id: Value(id),
      shopId: Value(shopId),
      userPhone: Value(userPhone),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      contactType: Value(contactType),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      createdAt: Value(createdAt),
    );
  }

  factory UserContact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserContact(
      id: serializer.fromJson<int>(json['id']),
      shopId: serializer.fromJson<int>(json['shopId']),
      userPhone: serializer.fromJson<String>(json['userPhone']),
      userName: serializer.fromJson<String?>(json['userName']),
      contactType: serializer.fromJson<String>(json['contactType']),
      productId: serializer.fromJson<int?>(json['productId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shopId': serializer.toJson<int>(shopId),
      'userPhone': serializer.toJson<String>(userPhone),
      'userName': serializer.toJson<String?>(userName),
      'contactType': serializer.toJson<String>(contactType),
      'productId': serializer.toJson<int?>(productId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserContact copyWith({
    int? id,
    int? shopId,
    String? userPhone,
    Value<String?> userName = const Value.absent(),
    String? contactType,
    Value<int?> productId = const Value.absent(),
    DateTime? createdAt,
  }) => UserContact(
    id: id ?? this.id,
    shopId: shopId ?? this.shopId,
    userPhone: userPhone ?? this.userPhone,
    userName: userName.present ? userName.value : this.userName,
    contactType: contactType ?? this.contactType,
    productId: productId.present ? productId.value : this.productId,
    createdAt: createdAt ?? this.createdAt,
  );
  UserContact copyWithCompanion(UserContactsCompanion data) {
    return UserContact(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      userPhone: data.userPhone.present ? data.userPhone.value : this.userPhone,
      userName: data.userName.present ? data.userName.value : this.userName,
      contactType: data.contactType.present
          ? data.contactType.value
          : this.contactType,
      productId: data.productId.present ? data.productId.value : this.productId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserContact(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('userPhone: $userPhone, ')
          ..write('userName: $userName, ')
          ..write('contactType: $contactType, ')
          ..write('productId: $productId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shopId,
    userPhone,
    userName,
    contactType,
    productId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserContact &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.userPhone == this.userPhone &&
          other.userName == this.userName &&
          other.contactType == this.contactType &&
          other.productId == this.productId &&
          other.createdAt == this.createdAt);
}

class UserContactsCompanion extends UpdateCompanion<UserContact> {
  final Value<int> id;
  final Value<int> shopId;
  final Value<String> userPhone;
  final Value<String?> userName;
  final Value<String> contactType;
  final Value<int?> productId;
  final Value<DateTime> createdAt;
  const UserContactsCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.userPhone = const Value.absent(),
    this.userName = const Value.absent(),
    this.contactType = const Value.absent(),
    this.productId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserContactsCompanion.insert({
    this.id = const Value.absent(),
    required int shopId,
    required String userPhone,
    this.userName = const Value.absent(),
    required String contactType,
    this.productId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : shopId = Value(shopId),
       userPhone = Value(userPhone),
       contactType = Value(contactType);
  static Insertable<UserContact> custom({
    Expression<int>? id,
    Expression<int>? shopId,
    Expression<String>? userPhone,
    Expression<String>? userName,
    Expression<String>? contactType,
    Expression<int>? productId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (userPhone != null) 'user_phone': userPhone,
      if (userName != null) 'user_name': userName,
      if (contactType != null) 'contact_type': contactType,
      if (productId != null) 'product_id': productId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserContactsCompanion copyWith({
    Value<int>? id,
    Value<int>? shopId,
    Value<String>? userPhone,
    Value<String?>? userName,
    Value<String>? contactType,
    Value<int?>? productId,
    Value<DateTime>? createdAt,
  }) {
    return UserContactsCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userPhone: userPhone ?? this.userPhone,
      userName: userName ?? this.userName,
      contactType: contactType ?? this.contactType,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<int>(shopId.value);
    }
    if (userPhone.present) {
      map['user_phone'] = Variable<String>(userPhone.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (contactType.present) {
      map['contact_type'] = Variable<String>(contactType.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserContactsCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('userPhone: $userPhone, ')
          ..write('userName: $userName, ')
          ..write('contactType: $contactType, ')
          ..write('productId: $productId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppPreferencesTable extends AppPreferences
    with TableInfo<$AppPreferencesTable, AppPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDarkModeMeta = const VerificationMeta(
    'isDarkMode',
  );
  @override
  late final GeneratedColumn<bool> isDarkMode = GeneratedColumn<bool>(
    'is_dark_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dark_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fr'),
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isLiteModeMeta = const VerificationMeta(
    'isLiteMode',
  );
  @override
  late final GeneratedColumn<bool> isLiteMode = GeneratedColumn<bool>(
    'is_lite_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_lite_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _biometricEnabledMeta = const VerificationMeta(
    'biometricEnabled',
  );
  @override
  late final GeneratedColumn<bool> biometricEnabled = GeneratedColumn<bool>(
    'biometric_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("biometric_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _userCommuneMeta = const VerificationMeta(
    'userCommune',
  );
  @override
  late final GeneratedColumn<String> userCommune = GeneratedColumn<String>(
    'user_commune',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncMeta = const VerificationMeta(
    'lastSync',
  );
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
    'last_sync',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isDarkMode,
    language,
    notificationsEnabled,
    isLiteMode,
    biometricEnabled,
    userCommune,
    lastSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_dark_mode')) {
      context.handle(
        _isDarkModeMeta,
        isDarkMode.isAcceptableOrUnknown(
          data['is_dark_mode']!,
          _isDarkModeMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('is_lite_mode')) {
      context.handle(
        _isLiteModeMeta,
        isLiteMode.isAcceptableOrUnknown(
          data['is_lite_mode']!,
          _isLiteModeMeta,
        ),
      );
    }
    if (data.containsKey('biometric_enabled')) {
      context.handle(
        _biometricEnabledMeta,
        biometricEnabled.isAcceptableOrUnknown(
          data['biometric_enabled']!,
          _biometricEnabledMeta,
        ),
      );
    }
    if (data.containsKey('user_commune')) {
      context.handle(
        _userCommuneMeta,
        userCommune.isAcceptableOrUnknown(
          data['user_commune']!,
          _userCommuneMeta,
        ),
      );
    }
    if (data.containsKey('last_sync')) {
      context.handle(
        _lastSyncMeta,
        lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isDarkMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dark_mode'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      isLiteMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_lite_mode'],
      )!,
      biometricEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}biometric_enabled'],
      )!,
      userCommune: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_commune'],
      ),
      lastSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync'],
      ),
    );
  }

  @override
  $AppPreferencesTable createAlias(String alias) {
    return $AppPreferencesTable(attachedDatabase, alias);
  }
}

class AppPreference extends DataClass implements Insertable<AppPreference> {
  final int id;
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool isLiteMode;
  final bool biometricEnabled;
  final String? userCommune;
  final DateTime? lastSync;
  const AppPreference({
    required this.id,
    required this.isDarkMode,
    required this.language,
    required this.notificationsEnabled,
    required this.isLiteMode,
    required this.biometricEnabled,
    this.userCommune,
    this.lastSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_dark_mode'] = Variable<bool>(isDarkMode);
    map['language'] = Variable<String>(language);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['is_lite_mode'] = Variable<bool>(isLiteMode);
    map['biometric_enabled'] = Variable<bool>(biometricEnabled);
    if (!nullToAbsent || userCommune != null) {
      map['user_commune'] = Variable<String>(userCommune);
    }
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<DateTime>(lastSync);
    }
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(
      id: Value(id),
      isDarkMode: Value(isDarkMode),
      language: Value(language),
      notificationsEnabled: Value(notificationsEnabled),
      isLiteMode: Value(isLiteMode),
      biometricEnabled: Value(biometricEnabled),
      userCommune: userCommune == null && nullToAbsent
          ? const Value.absent()
          : Value(userCommune),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory AppPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreference(
      id: serializer.fromJson<int>(json['id']),
      isDarkMode: serializer.fromJson<bool>(json['isDarkMode']),
      language: serializer.fromJson<String>(json['language']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      isLiteMode: serializer.fromJson<bool>(json['isLiteMode']),
      biometricEnabled: serializer.fromJson<bool>(json['biometricEnabled']),
      userCommune: serializer.fromJson<String?>(json['userCommune']),
      lastSync: serializer.fromJson<DateTime?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isDarkMode': serializer.toJson<bool>(isDarkMode),
      'language': serializer.toJson<String>(language),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'isLiteMode': serializer.toJson<bool>(isLiteMode),
      'biometricEnabled': serializer.toJson<bool>(biometricEnabled),
      'userCommune': serializer.toJson<String?>(userCommune),
      'lastSync': serializer.toJson<DateTime?>(lastSync),
    };
  }

  AppPreference copyWith({
    int? id,
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? isLiteMode,
    bool? biometricEnabled,
    Value<String?> userCommune = const Value.absent(),
    Value<DateTime?> lastSync = const Value.absent(),
  }) => AppPreference(
    id: id ?? this.id,
    isDarkMode: isDarkMode ?? this.isDarkMode,
    language: language ?? this.language,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    isLiteMode: isLiteMode ?? this.isLiteMode,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    userCommune: userCommune.present ? userCommune.value : this.userCommune,
    lastSync: lastSync.present ? lastSync.value : this.lastSync,
  );
  AppPreference copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreference(
      id: data.id.present ? data.id.value : this.id,
      isDarkMode: data.isDarkMode.present
          ? data.isDarkMode.value
          : this.isDarkMode,
      language: data.language.present ? data.language.value : this.language,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      isLiteMode: data.isLiteMode.present
          ? data.isLiteMode.value
          : this.isLiteMode,
      biometricEnabled: data.biometricEnabled.present
          ? data.biometricEnabled.value
          : this.biometricEnabled,
      userCommune: data.userCommune.present
          ? data.userCommune.value
          : this.userCommune,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreference(')
          ..write('id: $id, ')
          ..write('isDarkMode: $isDarkMode, ')
          ..write('language: $language, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('isLiteMode: $isLiteMode, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('userCommune: $userCommune, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isDarkMode,
    language,
    notificationsEnabled,
    isLiteMode,
    biometricEnabled,
    userCommune,
    lastSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreference &&
          other.id == this.id &&
          other.isDarkMode == this.isDarkMode &&
          other.language == this.language &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.isLiteMode == this.isLiteMode &&
          other.biometricEnabled == this.biometricEnabled &&
          other.userCommune == this.userCommune &&
          other.lastSync == this.lastSync);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreference> {
  final Value<int> id;
  final Value<bool> isDarkMode;
  final Value<String> language;
  final Value<bool> notificationsEnabled;
  final Value<bool> isLiteMode;
  final Value<bool> biometricEnabled;
  final Value<String?> userCommune;
  final Value<DateTime?> lastSync;
  const AppPreferencesCompanion({
    this.id = const Value.absent(),
    this.isDarkMode = const Value.absent(),
    this.language = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.isLiteMode = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.userCommune = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.isDarkMode = const Value.absent(),
    this.language = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.isLiteMode = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.userCommune = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<AppPreference> custom({
    Expression<int>? id,
    Expression<bool>? isDarkMode,
    Expression<String>? language,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? isLiteMode,
    Expression<bool>? biometricEnabled,
    Expression<String>? userCommune,
    Expression<DateTime>? lastSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDarkMode != null) 'is_dark_mode': isDarkMode,
      if (language != null) 'language': language,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (isLiteMode != null) 'is_lite_mode': isLiteMode,
      if (biometricEnabled != null) 'biometric_enabled': biometricEnabled,
      if (userCommune != null) 'user_commune': userCommune,
      if (lastSync != null) 'last_sync': lastSync,
    });
  }

  AppPreferencesCompanion copyWith({
    Value<int>? id,
    Value<bool>? isDarkMode,
    Value<String>? language,
    Value<bool>? notificationsEnabled,
    Value<bool>? isLiteMode,
    Value<bool>? biometricEnabled,
    Value<String?>? userCommune,
    Value<DateTime?>? lastSync,
  }) {
    return AppPreferencesCompanion(
      id: id ?? this.id,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLiteMode: isLiteMode ?? this.isLiteMode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      userCommune: userCommune ?? this.userCommune,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isDarkMode.present) {
      map['is_dark_mode'] = Variable<bool>(isDarkMode.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (isLiteMode.present) {
      map['is_lite_mode'] = Variable<bool>(isLiteMode.value);
    }
    if (biometricEnabled.present) {
      map['biometric_enabled'] = Variable<bool>(biometricEnabled.value);
    }
    if (userCommune.present) {
      map['user_commune'] = Variable<String>(userCommune.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('isDarkMode: $isDarkMode, ')
          ..write('language: $language, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('isLiteMode: $isLiteMode, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('userCommune: $userCommune, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $WishlistProductsTable extends WishlistProducts
    with TableInfo<$WishlistProductsTable, WishlistProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WishlistProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, productId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wishlist_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<WishlistProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WishlistProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WishlistProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WishlistProductsTable createAlias(String alias) {
    return $WishlistProductsTable(attachedDatabase, alias);
  }
}

class WishlistProduct extends DataClass implements Insertable<WishlistProduct> {
  final int id;
  final int productId;
  final DateTime createdAt;
  const WishlistProduct({
    required this.id,
    required this.productId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WishlistProductsCompanion toCompanion(bool nullToAbsent) {
    return WishlistProductsCompanion(
      id: Value(id),
      productId: Value(productId),
      createdAt: Value(createdAt),
    );
  }

  factory WishlistProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WishlistProduct(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WishlistProduct copyWith({int? id, int? productId, DateTime? createdAt}) =>
      WishlistProduct(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        createdAt: createdAt ?? this.createdAt,
      );
  WishlistProduct copyWithCompanion(WishlistProductsCompanion data) {
    return WishlistProduct(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WishlistProduct(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WishlistProduct &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.createdAt == this.createdAt);
}

class WishlistProductsCompanion extends UpdateCompanion<WishlistProduct> {
  final Value<int> id;
  final Value<int> productId;
  final Value<DateTime> createdAt;
  const WishlistProductsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WishlistProductsCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    this.createdAt = const Value.absent(),
  }) : productId = Value(productId);
  static Insertable<WishlistProduct> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WishlistProductsCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<DateTime>? createdAt,
  }) {
    return WishlistProductsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WishlistProductsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FollowedShopsTable extends FollowedShops
    with TableInfo<$FollowedShopsTable, FollowedShop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowedShopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shopIdMeta = const VerificationMeta('shopId');
  @override
  late final GeneratedColumn<int> shopId = GeneratedColumn<int>(
    'shop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shops (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, shopId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'followed_shops';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowedShop> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shop_id')) {
      context.handle(
        _shopIdMeta,
        shopId.isAcceptableOrUnknown(data['shop_id']!, _shopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shopIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FollowedShop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowedShop(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shop_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FollowedShopsTable createAlias(String alias) {
    return $FollowedShopsTable(attachedDatabase, alias);
  }
}

class FollowedShop extends DataClass implements Insertable<FollowedShop> {
  final int id;
  final int shopId;
  final DateTime createdAt;
  const FollowedShop({
    required this.id,
    required this.shopId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shop_id'] = Variable<int>(shopId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FollowedShopsCompanion toCompanion(bool nullToAbsent) {
    return FollowedShopsCompanion(
      id: Value(id),
      shopId: Value(shopId),
      createdAt: Value(createdAt),
    );
  }

  factory FollowedShop.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowedShop(
      id: serializer.fromJson<int>(json['id']),
      shopId: serializer.fromJson<int>(json['shopId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shopId': serializer.toJson<int>(shopId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FollowedShop copyWith({int? id, int? shopId, DateTime? createdAt}) =>
      FollowedShop(
        id: id ?? this.id,
        shopId: shopId ?? this.shopId,
        createdAt: createdAt ?? this.createdAt,
      );
  FollowedShop copyWithCompanion(FollowedShopsCompanion data) {
    return FollowedShop(
      id: data.id.present ? data.id.value : this.id,
      shopId: data.shopId.present ? data.shopId.value : this.shopId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowedShop(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shopId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowedShop &&
          other.id == this.id &&
          other.shopId == this.shopId &&
          other.createdAt == this.createdAt);
}

class FollowedShopsCompanion extends UpdateCompanion<FollowedShop> {
  final Value<int> id;
  final Value<int> shopId;
  final Value<DateTime> createdAt;
  const FollowedShopsCompanion({
    this.id = const Value.absent(),
    this.shopId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FollowedShopsCompanion.insert({
    this.id = const Value.absent(),
    required int shopId,
    this.createdAt = const Value.absent(),
  }) : shopId = Value(shopId);
  static Insertable<FollowedShop> custom({
    Expression<int>? id,
    Expression<int>? shopId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FollowedShopsCompanion copyWith({
    Value<int>? id,
    Value<int>? shopId,
    Value<DateTime>? createdAt,
  }) {
    return FollowedShopsCompanion(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shopId.present) {
      map['shop_id'] = Variable<int>(shopId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowedShopsCompanion(')
          ..write('id: $id, ')
          ..write('shopId: $shopId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProductReviewsTable extends ProductReviews
    with TableInfo<$ProductReviewsTable, ProductReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    userName,
    comment,
    rating,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    } else if (isInserting) {
      context.missing(_commentMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      ),
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProductReviewsTable createAlias(String alias) {
    return $ProductReviewsTable(attachedDatabase, alias);
  }
}

class ProductReview extends DataClass implements Insertable<ProductReview> {
  final int id;
  final int productId;
  final String? userName;
  final String comment;
  final double rating;
  final DateTime createdAt;
  const ProductReview({
    required this.id,
    required this.productId,
    this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    map['comment'] = Variable<String>(comment);
    map['rating'] = Variable<double>(rating);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductReviewsCompanion toCompanion(bool nullToAbsent) {
    return ProductReviewsCompanion(
      id: Value(id),
      productId: Value(productId),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      comment: Value(comment),
      rating: Value(rating),
      createdAt: Value(createdAt),
    );
  }

  factory ProductReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductReview(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      userName: serializer.fromJson<String?>(json['userName']),
      comment: serializer.fromJson<String>(json['comment']),
      rating: serializer.fromJson<double>(json['rating']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'userName': serializer.toJson<String?>(userName),
      'comment': serializer.toJson<String>(comment),
      'rating': serializer.toJson<double>(rating),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProductReview copyWith({
    int? id,
    int? productId,
    Value<String?> userName = const Value.absent(),
    String? comment,
    double? rating,
    DateTime? createdAt,
  }) => ProductReview(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    userName: userName.present ? userName.value : this.userName,
    comment: comment ?? this.comment,
    rating: rating ?? this.rating,
    createdAt: createdAt ?? this.createdAt,
  );
  ProductReview copyWithCompanion(ProductReviewsCompanion data) {
    return ProductReview(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      userName: data.userName.present ? data.userName.value : this.userName,
      comment: data.comment.present ? data.comment.value : this.comment,
      rating: data.rating.present ? data.rating.value : this.rating,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductReview(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('userName: $userName, ')
          ..write('comment: $comment, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, userName, comment, rating, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductReview &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.userName == this.userName &&
          other.comment == this.comment &&
          other.rating == this.rating &&
          other.createdAt == this.createdAt);
}

class ProductReviewsCompanion extends UpdateCompanion<ProductReview> {
  final Value<int> id;
  final Value<int> productId;
  final Value<String?> userName;
  final Value<String> comment;
  final Value<double> rating;
  final Value<DateTime> createdAt;
  const ProductReviewsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.userName = const Value.absent(),
    this.comment = const Value.absent(),
    this.rating = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProductReviewsCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    this.userName = const Value.absent(),
    required String comment,
    required double rating,
    this.createdAt = const Value.absent(),
  }) : productId = Value(productId),
       comment = Value(comment),
       rating = Value(rating);
  static Insertable<ProductReview> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<String>? userName,
    Expression<String>? comment,
    Expression<double>? rating,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (userName != null) 'user_name': userName,
      if (comment != null) 'comment': comment,
      if (rating != null) 'rating': rating,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProductReviewsCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<String?>? userName,
    Value<String>? comment,
    Value<double>? rating,
    Value<DateTime>? createdAt,
  }) {
    return ProductReviewsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userName: userName ?? this.userName,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductReviewsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('userName: $userName, ')
          ..write('comment: $comment, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StoryMediaTable extends StoryMedia
    with TableInfo<$StoryMediaTable, StoryMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stories (id)',
    ),
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('image'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storyId,
    mediaUrl,
    mediaType,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryMediaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaUrlMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryMediaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryMediaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_id'],
      )!,
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StoryMediaTable createAlias(String alias) {
    return $StoryMediaTable(attachedDatabase, alias);
  }
}

class StoryMediaData extends DataClass implements Insertable<StoryMediaData> {
  final int id;
  final int storyId;
  final String mediaUrl;
  final String mediaType;
  final int sortOrder;
  final DateTime createdAt;
  const StoryMediaData({
    required this.id,
    required this.storyId,
    required this.mediaUrl,
    required this.mediaType,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['story_id'] = Variable<int>(storyId);
    map['media_url'] = Variable<String>(mediaUrl);
    map['media_type'] = Variable<String>(mediaType);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StoryMediaCompanion toCompanion(bool nullToAbsent) {
    return StoryMediaCompanion(
      id: Value(id),
      storyId: Value(storyId),
      mediaUrl: Value(mediaUrl),
      mediaType: Value(mediaType),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory StoryMediaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryMediaData(
      id: serializer.fromJson<int>(json['id']),
      storyId: serializer.fromJson<int>(json['storyId']),
      mediaUrl: serializer.fromJson<String>(json['mediaUrl']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storyId': serializer.toJson<int>(storyId),
      'mediaUrl': serializer.toJson<String>(mediaUrl),
      'mediaType': serializer.toJson<String>(mediaType),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StoryMediaData copyWith({
    int? id,
    int? storyId,
    String? mediaUrl,
    String? mediaType,
    int? sortOrder,
    DateTime? createdAt,
  }) => StoryMediaData(
    id: id ?? this.id,
    storyId: storyId ?? this.storyId,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    mediaType: mediaType ?? this.mediaType,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  StoryMediaData copyWithCompanion(StoryMediaCompanion data) {
    return StoryMediaData(
      id: data.id.present ? data.id.value : this.id,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryMediaData(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaType: $mediaType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storyId, mediaUrl, mediaType, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryMediaData &&
          other.id == this.id &&
          other.storyId == this.storyId &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaType == this.mediaType &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class StoryMediaCompanion extends UpdateCompanion<StoryMediaData> {
  final Value<int> id;
  final Value<int> storyId;
  final Value<String> mediaUrl;
  final Value<String> mediaType;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const StoryMediaCompanion({
    this.id = const Value.absent(),
    this.storyId = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StoryMediaCompanion.insert({
    this.id = const Value.absent(),
    required int storyId,
    required String mediaUrl,
    this.mediaType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : storyId = Value(storyId),
       mediaUrl = Value(mediaUrl);
  static Insertable<StoryMediaData> custom({
    Expression<int>? id,
    Expression<int>? storyId,
    Expression<String>? mediaUrl,
    Expression<String>? mediaType,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storyId != null) 'story_id': storyId,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaType != null) 'media_type': mediaType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StoryMediaCompanion copyWith({
    Value<int>? id,
    Value<int>? storyId,
    Value<String>? mediaUrl,
    Value<String>? mediaType,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return StoryMediaCompanion(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryMediaCompanion(')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaType: $mediaType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$UzaDatabase extends GeneratedDatabase {
  _$UzaDatabase(QueryExecutor e) : super(e);
  $UzaDatabaseManager get managers => $UzaDatabaseManager(this);
  late final $ShopsTable shops = $ShopsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $StoriesTable stories = $StoriesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $OfflineQueueTable offlineQueue = $OfflineQueueTable(this);
  late final $AnalyticsTable analytics = $AnalyticsTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $CartItemsTable cartItems = $CartItemsTable(this);
  late final $UserContactsTable userContacts = $UserContactsTable(this);
  late final $AppPreferencesTable appPreferences = $AppPreferencesTable(this);
  late final $WishlistProductsTable wishlistProducts = $WishlistProductsTable(
    this,
  );
  late final $FollowedShopsTable followedShops = $FollowedShopsTable(this);
  late final $ProductReviewsTable productReviews = $ProductReviewsTable(this);
  late final $StoryMediaTable storyMedia = $StoryMediaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    shops,
    categories,
    products,
    stories,
    syncQueue,
    offlineQueue,
    analytics,
    userProfiles,
    cartItems,
    userContacts,
    appPreferences,
    wishlistProducts,
    followedShops,
    productReviews,
    storyMedia,
  ];
}

typedef $$ShopsTableCreateCompanionBuilder =
    ShopsCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      required String name,
      Value<String?> description,
      Value<String?> logoUrl,
      required ShopType type,
      Value<String?> ownerId,
      Value<String?> address,
      Value<String?> whatsapp,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> instagramUrl,
      Value<String?> tiktokUrl,
      Value<String?> facebookUrl,
      Value<String?> youtubeUrl,
      Value<String?> bannerUrl,
      Value<String?> videoUrl,
      Value<DateTime> updatedAt,
      Value<bool> isBoosted,
      Value<int> boostStatus,
      Value<int> bannerStatus,
      Value<String?> bannerText,
      Value<bool> isVerified,
      Value<int?> responseTimeMinutes,
      Value<String?> commune,
      Value<String?> city,
      Value<DateTime?> verifiedAt,
      Value<double?> latitude,
      Value<double?> longitude,
    });
typedef $$ShopsTableUpdateCompanionBuilder =
    ShopsCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      Value<String> name,
      Value<String?> description,
      Value<String?> logoUrl,
      Value<ShopType> type,
      Value<String?> ownerId,
      Value<String?> address,
      Value<String?> whatsapp,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> instagramUrl,
      Value<String?> tiktokUrl,
      Value<String?> facebookUrl,
      Value<String?> youtubeUrl,
      Value<String?> bannerUrl,
      Value<String?> videoUrl,
      Value<DateTime> updatedAt,
      Value<bool> isBoosted,
      Value<int> boostStatus,
      Value<int> bannerStatus,
      Value<String?> bannerText,
      Value<bool> isVerified,
      Value<int?> responseTimeMinutes,
      Value<String?> commune,
      Value<String?> city,
      Value<DateTime?> verifiedAt,
      Value<double?> latitude,
      Value<double?> longitude,
    });

final class $$ShopsTableReferences
    extends BaseReferences<_$UzaDatabase, $ShopsTable, Shop> {
  $$ShopsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductsTable, List<Product>> _productsRefsTable(
    _$UzaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.products,
    aliasName: $_aliasNameGenerator(db.shops.id, db.products.shopId),
  );

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.shopId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoriesTable, List<Story>> _storiesRefsTable(
    _$UzaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.stories,
    aliasName: $_aliasNameGenerator(db.shops.id, db.stories.shopId),
  );

  $$StoriesTableProcessedTableManager get storiesRefs {
    final manager = $$StoriesTableTableManager(
      $_db,
      $_db.stories,
    ).filter((f) => f.shopId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_storiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserContactsTable, List<UserContact>>
  _userContactsRefsTable(_$UzaDatabase db) => MultiTypedResultKey.fromTable(
    db.userContacts,
    aliasName: $_aliasNameGenerator(db.shops.id, db.userContacts.shopId),
  );

  $$UserContactsTableProcessedTableManager get userContactsRefs {
    final manager = $$UserContactsTableTableManager(
      $_db,
      $_db.userContacts,
    ).filter((f) => f.shopId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userContactsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FollowedShopsTable, List<FollowedShop>>
  _followedShopsRefsTable(_$UzaDatabase db) => MultiTypedResultKey.fromTable(
    db.followedShops,
    aliasName: $_aliasNameGenerator(db.shops.id, db.followedShops.shopId),
  );

  $$FollowedShopsTableProcessedTableManager get followedShopsRefs {
    final manager = $$FollowedShopsTableTableManager(
      $_db,
      $_db.followedShops,
    ).filter((f) => f.shopId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_followedShopsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShopsTableFilterComposer extends Composer<_$UzaDatabase, $ShopsTable> {
  $$ShopsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ShopType, ShopType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatsapp => $composableBuilder(
    column: $table.whatsapp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instagramUrl => $composableBuilder(
    column: $table.instagramUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiktokUrl => $composableBuilder(
    column: $table.tiktokUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get facebookUrl => $composableBuilder(
    column: $table.facebookUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerUrl => $composableBuilder(
    column: $table.bannerUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBoosted => $composableBuilder(
    column: $table.isBoosted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boostStatus => $composableBuilder(
    column: $table.boostStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bannerStatus => $composableBuilder(
    column: $table.bannerStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerText => $composableBuilder(
    column: $table.bannerText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseTimeMinutes => $composableBuilder(
    column: $table.responseTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commune => $composableBuilder(
    column: $table.commune,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsRefs(
    Expression<bool> Function($$ProductsTableFilterComposer f) f,
  ) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.shopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storiesRefs(
    Expression<bool> Function($$StoriesTableFilterComposer f) f,
  ) {
    final $$StoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.shopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableFilterComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userContactsRefs(
    Expression<bool> Function($$UserContactsTableFilterComposer f) f,
  ) {
    final $$UserContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userContacts,
      getReferencedColumn: (t) => t.shopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserContactsTableFilterComposer(
            $db: $db,
            $table: $db.userContacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> followedShopsRefs(
    Expression<bool> Function($$FollowedShopsTableFilterComposer f) f,
  ) {
    final $$FollowedShopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.followedShops,
      getReferencedColumn: (t) => t.shopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FollowedShopsTableFilterComposer(
            $db: $db,
            $table: $db.followedShops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShopsTableOrderingComposer
    extends Composer<_$UzaDatabase, $ShopsTable> {
  $$ShopsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatsapp => $composableBuilder(
    column: $table.whatsapp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instagramUrl => $composableBuilder(
    column: $table.instagramUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiktokUrl => $composableBuilder(
    column: $table.tiktokUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get facebookUrl => $composableBuilder(
    column: $table.facebookUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerUrl => $composableBuilder(
    column: $table.bannerUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBoosted => $composableBuilder(
    column: $table.isBoosted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boostStatus => $composableBuilder(
    column: $table.boostStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bannerStatus => $composableBuilder(
    column: $table.bannerStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerText => $composableBuilder(
    column: $table.bannerText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseTimeMinutes => $composableBuilder(
    column: $table.responseTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commune => $composableBuilder(
    column: $table.commune,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShopsTableAnnotationComposer
    extends Composer<_$UzaDatabase, $ShopsTable> {
  $$ShopsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ShopType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get whatsapp =>
      $composableBuilder(column: $table.whatsapp, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get instagramUrl => $composableBuilder(
    column: $table.instagramUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tiktokUrl =>
      $composableBuilder(column: $table.tiktokUrl, builder: (column) => column);

  GeneratedColumn<String> get facebookUrl => $composableBuilder(
    column: $table.facebookUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get youtubeUrl => $composableBuilder(
    column: $table.youtubeUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bannerUrl =>
      $composableBuilder(column: $table.bannerUrl, builder: (column) => column);

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isBoosted =>
      $composableBuilder(column: $table.isBoosted, builder: (column) => column);

  GeneratedColumn<int> get boostStatus => $composableBuilder(
    column: $table.boostStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bannerStatus => $composableBuilder(
    column: $table.bannerStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bannerText => $composableBuilder(
    column: $table.bannerText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVerified => $composableBuilder(
    column: $table.isVerified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseTimeMinutes => $composableBuilder(
    column: $table.responseTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commune =>
      $composableBuilder(column: $table.commune, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  Expression<T> productsRefs<T extends Object>(
    Expression<T> Function($$ProductsTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.shopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storiesRefs<T extends Object>(
    Expression<T> Function($$StoriesTableAnnotationComposer a) f,
  ) {
    final $$StoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.shopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userContactsRefs<T extends Object>(
    Expression<T> Function($$UserContactsTableAnnotationComposer a) f,
  ) {
    final $$UserContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userContacts,
      getReferencedColumn: (t) => t.shopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.userContacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> followedShopsRefs<T extends Object>(
    Expression<T> Function($$FollowedShopsTableAnnotationComposer a) f,
  ) {
    final $$FollowedShopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.followedShops,
      getReferencedColumn: (t) => t.shopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FollowedShopsTableAnnotationComposer(
            $db: $db,
            $table: $db.followedShops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShopsTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $ShopsTable,
          Shop,
          $$ShopsTableFilterComposer,
          $$ShopsTableOrderingComposer,
          $$ShopsTableAnnotationComposer,
          $$ShopsTableCreateCompanionBuilder,
          $$ShopsTableUpdateCompanionBuilder,
          (Shop, $$ShopsTableReferences),
          Shop,
          PrefetchHooks Function({
            bool productsRefs,
            bool storiesRefs,
            bool userContactsRefs,
            bool followedShopsRefs,
          })
        > {
  $$ShopsTableTableManager(_$UzaDatabase db, $ShopsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<ShopType> type = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> whatsapp = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> instagramUrl = const Value.absent(),
                Value<String?> tiktokUrl = const Value.absent(),
                Value<String?> facebookUrl = const Value.absent(),
                Value<String?> youtubeUrl = const Value.absent(),
                Value<String?> bannerUrl = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isBoosted = const Value.absent(),
                Value<int> boostStatus = const Value.absent(),
                Value<int> bannerStatus = const Value.absent(),
                Value<String?> bannerText = const Value.absent(),
                Value<bool> isVerified = const Value.absent(),
                Value<int?> responseTimeMinutes = const Value.absent(),
                Value<String?> commune = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
              }) => ShopsCompanion(
                id: id,
                remoteId: remoteId,
                name: name,
                description: description,
                logoUrl: logoUrl,
                type: type,
                ownerId: ownerId,
                address: address,
                whatsapp: whatsapp,
                phone: phone,
                email: email,
                instagramUrl: instagramUrl,
                tiktokUrl: tiktokUrl,
                facebookUrl: facebookUrl,
                youtubeUrl: youtubeUrl,
                bannerUrl: bannerUrl,
                videoUrl: videoUrl,
                updatedAt: updatedAt,
                isBoosted: isBoosted,
                boostStatus: boostStatus,
                bannerStatus: bannerStatus,
                bannerText: bannerText,
                isVerified: isVerified,
                responseTimeMinutes: responseTimeMinutes,
                commune: commune,
                city: city,
                verifiedAt: verifiedAt,
                latitude: latitude,
                longitude: longitude,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                required ShopType type,
                Value<String?> ownerId = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> whatsapp = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> instagramUrl = const Value.absent(),
                Value<String?> tiktokUrl = const Value.absent(),
                Value<String?> facebookUrl = const Value.absent(),
                Value<String?> youtubeUrl = const Value.absent(),
                Value<String?> bannerUrl = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isBoosted = const Value.absent(),
                Value<int> boostStatus = const Value.absent(),
                Value<int> bannerStatus = const Value.absent(),
                Value<String?> bannerText = const Value.absent(),
                Value<bool> isVerified = const Value.absent(),
                Value<int?> responseTimeMinutes = const Value.absent(),
                Value<String?> commune = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
              }) => ShopsCompanion.insert(
                id: id,
                remoteId: remoteId,
                name: name,
                description: description,
                logoUrl: logoUrl,
                type: type,
                ownerId: ownerId,
                address: address,
                whatsapp: whatsapp,
                phone: phone,
                email: email,
                instagramUrl: instagramUrl,
                tiktokUrl: tiktokUrl,
                facebookUrl: facebookUrl,
                youtubeUrl: youtubeUrl,
                bannerUrl: bannerUrl,
                videoUrl: videoUrl,
                updatedAt: updatedAt,
                isBoosted: isBoosted,
                boostStatus: boostStatus,
                bannerStatus: bannerStatus,
                bannerText: bannerText,
                isVerified: isVerified,
                responseTimeMinutes: responseTimeMinutes,
                commune: commune,
                city: city,
                verifiedAt: verifiedAt,
                latitude: latitude,
                longitude: longitude,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ShopsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                productsRefs = false,
                storiesRefs = false,
                userContactsRefs = false,
                followedShopsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productsRefs) db.products,
                    if (storiesRefs) db.stories,
                    if (userContactsRefs) db.userContacts,
                    if (followedShopsRefs) db.followedShops,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productsRefs)
                        await $_getPrefetchedData<Shop, $ShopsTable, Product>(
                          currentTable: table,
                          referencedTable: $$ShopsTableReferences
                              ._productsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShopsTableReferences(
                                db,
                                table,
                                p0,
                              ).productsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shopId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storiesRefs)
                        await $_getPrefetchedData<Shop, $ShopsTable, Story>(
                          currentTable: table,
                          referencedTable: $$ShopsTableReferences
                              ._storiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShopsTableReferences(db, table, p0).storiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shopId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userContactsRefs)
                        await $_getPrefetchedData<
                          Shop,
                          $ShopsTable,
                          UserContact
                        >(
                          currentTable: table,
                          referencedTable: $$ShopsTableReferences
                              ._userContactsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShopsTableReferences(
                                db,
                                table,
                                p0,
                              ).userContactsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shopId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (followedShopsRefs)
                        await $_getPrefetchedData<
                          Shop,
                          $ShopsTable,
                          FollowedShop
                        >(
                          currentTable: table,
                          referencedTable: $$ShopsTableReferences
                              ._followedShopsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShopsTableReferences(
                                db,
                                table,
                                p0,
                              ).followedShopsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shopId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ShopsTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $ShopsTable,
      Shop,
      $$ShopsTableFilterComposer,
      $$ShopsTableOrderingComposer,
      $$ShopsTableAnnotationComposer,
      $$ShopsTableCreateCompanionBuilder,
      $$ShopsTableUpdateCompanionBuilder,
      (Shop, $$ShopsTableReferences),
      Shop,
      PrefetchHooks Function({
        bool productsRefs,
        bool storiesRefs,
        bool userContactsRefs,
        bool followedShopsRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      required String name,
      Value<String?> icon,
      Value<DateTime> updatedAt,
      Value<int?> parentId,
      Value<int> level,
      Value<int> sortOrder,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      Value<String> name,
      Value<String?> icon,
      Value<DateTime> updatedAt,
      Value<int?> parentId,
      Value<int> level,
      Value<int> sortOrder,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$UzaDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductsTable, List<Product>> _productsRefsTable(
    _$UzaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.products,
    aliasName: $_aliasNameGenerator(db.categories.id, db.products.categoryId),
  );

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$UzaDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsRefs(
    Expression<bool> Function($$ProductsTableFilterComposer f) f,
  ) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$UzaDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$UzaDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> productsRefs<T extends Object>(
    Expression<T> Function($$ProductsTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool productsRefs})
        > {
  $$CategoriesTableTableManager(_$UzaDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                remoteId: remoteId,
                name: name,
                icon: icon,
                updatedAt: updatedAt,
                parentId: parentId,
                level: level,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                remoteId: remoteId,
                name: name,
                icon: icon,
                updatedAt: updatedAt,
                parentId: parentId,
                level: level,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedData<
                      Category,
                      $CategoriesTable,
                      Product
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._productsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).productsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool productsRefs})
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      required int shopId,
      Value<int?> categoryId,
      required String name,
      Value<String?> description,
      Value<double?> price,
      Value<String?> category,
      required String imageUrls,
      Value<bool> isArrival,
      Value<bool> isPromotion,
      Value<int?> stockCount,
      Value<bool> hidePrice,
      Value<bool> showStock,
      Value<bool> isBoosted,
      Value<String?> promotionMessage,
      Value<DateTime> updatedAt,
      Value<int> viewsCount,
      Value<int> sharesCount,
      Value<int> ratingsCount,
      Value<double> ratingAvg,
      Value<int> boostStatus,
      Value<String> condition,
      Value<int> reportCount,
      Value<bool> isSold,
      Value<String?> metadata,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      Value<int> shopId,
      Value<int?> categoryId,
      Value<String> name,
      Value<String?> description,
      Value<double?> price,
      Value<String?> category,
      Value<String> imageUrls,
      Value<bool> isArrival,
      Value<bool> isPromotion,
      Value<int?> stockCount,
      Value<bool> hidePrice,
      Value<bool> showStock,
      Value<bool> isBoosted,
      Value<String?> promotionMessage,
      Value<DateTime> updatedAt,
      Value<int> viewsCount,
      Value<int> sharesCount,
      Value<int> ratingsCount,
      Value<double> ratingAvg,
      Value<int> boostStatus,
      Value<String> condition,
      Value<int> reportCount,
      Value<bool> isSold,
      Value<String?> metadata,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$UzaDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShopsTable _shopIdTable(_$UzaDatabase db) => db.shops.createAlias(
    $_aliasNameGenerator(db.products.shopId, db.shops.id),
  );

  $$ShopsTableProcessedTableManager get shopId {
    final $_column = $_itemColumn<int>('shop_id')!;

    final manager = $$ShopsTableTableManager(
      $_db,
      $_db.shops,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$UzaDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.products.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CartItemsTable, List<CartItem>>
  _cartItemsRefsTable(_$UzaDatabase db) => MultiTypedResultKey.fromTable(
    db.cartItems,
    aliasName: $_aliasNameGenerator(db.products.id, db.cartItems.productId),
  );

  $$CartItemsTableProcessedTableManager get cartItemsRefs {
    final manager = $$CartItemsTableTableManager(
      $_db,
      $_db.cartItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cartItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserContactsTable, List<UserContact>>
  _userContactsRefsTable(_$UzaDatabase db) => MultiTypedResultKey.fromTable(
    db.userContacts,
    aliasName: $_aliasNameGenerator(db.products.id, db.userContacts.productId),
  );

  $$UserContactsTableProcessedTableManager get userContactsRefs {
    final manager = $$UserContactsTableTableManager(
      $_db,
      $_db.userContacts,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userContactsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WishlistProductsTable, List<WishlistProduct>>
  _wishlistProductsRefsTable(_$UzaDatabase db) => MultiTypedResultKey.fromTable(
    db.wishlistProducts,
    aliasName: $_aliasNameGenerator(
      db.products.id,
      db.wishlistProducts.productId,
    ),
  );

  $$WishlistProductsTableProcessedTableManager get wishlistProductsRefs {
    final manager = $$WishlistProductsTableTableManager(
      $_db,
      $_db.wishlistProducts,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _wishlistProductsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProductReviewsTable, List<ProductReview>>
  _productReviewsRefsTable(_$UzaDatabase db) => MultiTypedResultKey.fromTable(
    db.productReviews,
    aliasName: $_aliasNameGenerator(
      db.products.id,
      db.productReviews.productId,
    ),
  );

  $$ProductReviewsTableProcessedTableManager get productReviewsRefs {
    final manager = $$ProductReviewsTableTableManager(
      $_db,
      $_db.productReviews,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productReviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$UzaDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrls => $composableBuilder(
    column: $table.imageUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArrival => $composableBuilder(
    column: $table.isArrival,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPromotion => $composableBuilder(
    column: $table.isPromotion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidePrice => $composableBuilder(
    column: $table.hidePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showStock => $composableBuilder(
    column: $table.showStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBoosted => $composableBuilder(
    column: $table.isBoosted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promotionMessage => $composableBuilder(
    column: $table.promotionMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get viewsCount => $composableBuilder(
    column: $table.viewsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sharesCount => $composableBuilder(
    column: $table.sharesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratingsCount => $composableBuilder(
    column: $table.ratingsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ratingAvg => $composableBuilder(
    column: $table.ratingAvg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boostStatus => $composableBuilder(
    column: $table.boostStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reportCount => $composableBuilder(
    column: $table.reportCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSold => $composableBuilder(
    column: $table.isSold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  $$ShopsTableFilterComposer get shopId {
    final $$ShopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableFilterComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cartItemsRefs(
    Expression<bool> Function($$CartItemsTableFilterComposer f) f,
  ) {
    final $$CartItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cartItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartItemsTableFilterComposer(
            $db: $db,
            $table: $db.cartItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userContactsRefs(
    Expression<bool> Function($$UserContactsTableFilterComposer f) f,
  ) {
    final $$UserContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userContacts,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserContactsTableFilterComposer(
            $db: $db,
            $table: $db.userContacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> wishlistProductsRefs(
    Expression<bool> Function($$WishlistProductsTableFilterComposer f) f,
  ) {
    final $$WishlistProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishlistProducts,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishlistProductsTableFilterComposer(
            $db: $db,
            $table: $db.wishlistProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> productReviewsRefs(
    Expression<bool> Function($$ProductReviewsTableFilterComposer f) f,
  ) {
    final $$ProductReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productReviews,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductReviewsTableFilterComposer(
            $db: $db,
            $table: $db.productReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$UzaDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrls => $composableBuilder(
    column: $table.imageUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArrival => $composableBuilder(
    column: $table.isArrival,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPromotion => $composableBuilder(
    column: $table.isPromotion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidePrice => $composableBuilder(
    column: $table.hidePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showStock => $composableBuilder(
    column: $table.showStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBoosted => $composableBuilder(
    column: $table.isBoosted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promotionMessage => $composableBuilder(
    column: $table.promotionMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get viewsCount => $composableBuilder(
    column: $table.viewsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sharesCount => $composableBuilder(
    column: $table.sharesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratingsCount => $composableBuilder(
    column: $table.ratingsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ratingAvg => $composableBuilder(
    column: $table.ratingAvg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boostStatus => $composableBuilder(
    column: $table.boostStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reportCount => $composableBuilder(
    column: $table.reportCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSold => $composableBuilder(
    column: $table.isSold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShopsTableOrderingComposer get shopId {
    final $$ShopsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableOrderingComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$UzaDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get imageUrls =>
      $composableBuilder(column: $table.imageUrls, builder: (column) => column);

  GeneratedColumn<bool> get isArrival =>
      $composableBuilder(column: $table.isArrival, builder: (column) => column);

  GeneratedColumn<bool> get isPromotion => $composableBuilder(
    column: $table.isPromotion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockCount => $composableBuilder(
    column: $table.stockCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hidePrice =>
      $composableBuilder(column: $table.hidePrice, builder: (column) => column);

  GeneratedColumn<bool> get showStock =>
      $composableBuilder(column: $table.showStock, builder: (column) => column);

  GeneratedColumn<bool> get isBoosted =>
      $composableBuilder(column: $table.isBoosted, builder: (column) => column);

  GeneratedColumn<String> get promotionMessage => $composableBuilder(
    column: $table.promotionMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get viewsCount => $composableBuilder(
    column: $table.viewsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sharesCount => $composableBuilder(
    column: $table.sharesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ratingsCount => $composableBuilder(
    column: $table.ratingsCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ratingAvg =>
      $composableBuilder(column: $table.ratingAvg, builder: (column) => column);

  GeneratedColumn<int> get boostStatus => $composableBuilder(
    column: $table.boostStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<int> get reportCount => $composableBuilder(
    column: $table.reportCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSold =>
      $composableBuilder(column: $table.isSold, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  $$ShopsTableAnnotationComposer get shopId {
    final $$ShopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableAnnotationComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cartItemsRefs<T extends Object>(
    Expression<T> Function($$CartItemsTableAnnotationComposer a) f,
  ) {
    final $$CartItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cartItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CartItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.cartItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userContactsRefs<T extends Object>(
    Expression<T> Function($$UserContactsTableAnnotationComposer a) f,
  ) {
    final $$UserContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userContacts,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.userContacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> wishlistProductsRefs<T extends Object>(
    Expression<T> Function($$WishlistProductsTableAnnotationComposer a) f,
  ) {
    final $$WishlistProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishlistProducts,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishlistProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.wishlistProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> productReviewsRefs<T extends Object>(
    Expression<T> Function($$ProductReviewsTableAnnotationComposer a) f,
  ) {
    final $$ProductReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productReviews,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.productReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({
            bool shopId,
            bool categoryId,
            bool cartItemsRefs,
            bool userContactsRefs,
            bool wishlistProductsRefs,
            bool productReviewsRefs,
          })
        > {
  $$ProductsTableTableManager(_$UzaDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int> shopId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> imageUrls = const Value.absent(),
                Value<bool> isArrival = const Value.absent(),
                Value<bool> isPromotion = const Value.absent(),
                Value<int?> stockCount = const Value.absent(),
                Value<bool> hidePrice = const Value.absent(),
                Value<bool> showStock = const Value.absent(),
                Value<bool> isBoosted = const Value.absent(),
                Value<String?> promotionMessage = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> viewsCount = const Value.absent(),
                Value<int> sharesCount = const Value.absent(),
                Value<int> ratingsCount = const Value.absent(),
                Value<double> ratingAvg = const Value.absent(),
                Value<int> boostStatus = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<int> reportCount = const Value.absent(),
                Value<bool> isSold = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                remoteId: remoteId,
                shopId: shopId,
                categoryId: categoryId,
                name: name,
                description: description,
                price: price,
                category: category,
                imageUrls: imageUrls,
                isArrival: isArrival,
                isPromotion: isPromotion,
                stockCount: stockCount,
                hidePrice: hidePrice,
                showStock: showStock,
                isBoosted: isBoosted,
                promotionMessage: promotionMessage,
                updatedAt: updatedAt,
                viewsCount: viewsCount,
                sharesCount: sharesCount,
                ratingsCount: ratingsCount,
                ratingAvg: ratingAvg,
                boostStatus: boostStatus,
                condition: condition,
                reportCount: reportCount,
                isSold: isSold,
                metadata: metadata,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required int shopId,
                Value<int?> categoryId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required String imageUrls,
                Value<bool> isArrival = const Value.absent(),
                Value<bool> isPromotion = const Value.absent(),
                Value<int?> stockCount = const Value.absent(),
                Value<bool> hidePrice = const Value.absent(),
                Value<bool> showStock = const Value.absent(),
                Value<bool> isBoosted = const Value.absent(),
                Value<String?> promotionMessage = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> viewsCount = const Value.absent(),
                Value<int> sharesCount = const Value.absent(),
                Value<int> ratingsCount = const Value.absent(),
                Value<double> ratingAvg = const Value.absent(),
                Value<int> boostStatus = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<int> reportCount = const Value.absent(),
                Value<bool> isSold = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                remoteId: remoteId,
                shopId: shopId,
                categoryId: categoryId,
                name: name,
                description: description,
                price: price,
                category: category,
                imageUrls: imageUrls,
                isArrival: isArrival,
                isPromotion: isPromotion,
                stockCount: stockCount,
                hidePrice: hidePrice,
                showStock: showStock,
                isBoosted: isBoosted,
                promotionMessage: promotionMessage,
                updatedAt: updatedAt,
                viewsCount: viewsCount,
                sharesCount: sharesCount,
                ratingsCount: ratingsCount,
                ratingAvg: ratingAvg,
                boostStatus: boostStatus,
                condition: condition,
                reportCount: reportCount,
                isSold: isSold,
                metadata: metadata,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                shopId = false,
                categoryId = false,
                cartItemsRefs = false,
                userContactsRefs = false,
                wishlistProductsRefs = false,
                productReviewsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cartItemsRefs) db.cartItems,
                    if (userContactsRefs) db.userContacts,
                    if (wishlistProductsRefs) db.wishlistProducts,
                    if (productReviewsRefs) db.productReviews,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (shopId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.shopId,
                                    referencedTable: $$ProductsTableReferences
                                        ._shopIdTable(db),
                                    referencedColumn: $$ProductsTableReferences
                                        ._shopIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$ProductsTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$ProductsTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cartItemsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          CartItem
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._cartItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).cartItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userContactsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          UserContact
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._userContactsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).userContactsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (wishlistProductsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          WishlistProduct
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._wishlistProductsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).wishlistProductsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (productReviewsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          ProductReview
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._productReviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).productReviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({
        bool shopId,
        bool categoryId,
        bool cartItemsRefs,
        bool userContactsRefs,
        bool wishlistProductsRefs,
        bool productReviewsRefs,
      })
    >;
typedef $$StoriesTableCreateCompanionBuilder =
    StoriesCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      required int shopId,
      required String mediaUrl,
      required String mediaType,
      Value<bool> isArrivage,
      required DateTime expiresAt,
      Value<DateTime> createdAt,
    });
typedef $$StoriesTableUpdateCompanionBuilder =
    StoriesCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      Value<int> shopId,
      Value<String> mediaUrl,
      Value<String> mediaType,
      Value<bool> isArrivage,
      Value<DateTime> expiresAt,
      Value<DateTime> createdAt,
    });

final class $$StoriesTableReferences
    extends BaseReferences<_$UzaDatabase, $StoriesTable, Story> {
  $$StoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShopsTable _shopIdTable(_$UzaDatabase db) => db.shops.createAlias(
    $_aliasNameGenerator(db.stories.shopId, db.shops.id),
  );

  $$ShopsTableProcessedTableManager get shopId {
    final $_column = $_itemColumn<int>('shop_id')!;

    final manager = $$ShopsTableTableManager(
      $_db,
      $_db.shops,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StoryMediaTable, List<StoryMediaData>>
  _storyMediaRefsTable(_$UzaDatabase db) => MultiTypedResultKey.fromTable(
    db.storyMedia,
    aliasName: $_aliasNameGenerator(db.stories.id, db.storyMedia.storyId),
  );

  $$StoryMediaTableProcessedTableManager get storyMediaRefs {
    final manager = $$StoryMediaTableTableManager(
      $_db,
      $_db.storyMedia,
    ).filter((f) => f.storyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_storyMediaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoriesTableFilterComposer
    extends Composer<_$UzaDatabase, $StoriesTable> {
  $$StoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArrivage => $composableBuilder(
    column: $table.isArrivage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShopsTableFilterComposer get shopId {
    final $$ShopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableFilterComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> storyMediaRefs(
    Expression<bool> Function($$StoryMediaTableFilterComposer f) f,
  ) {
    final $$StoryMediaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyMedia,
      getReferencedColumn: (t) => t.storyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryMediaTableFilterComposer(
            $db: $db,
            $table: $db.storyMedia,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoriesTableOrderingComposer
    extends Composer<_$UzaDatabase, $StoriesTable> {
  $$StoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArrivage => $composableBuilder(
    column: $table.isArrivage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShopsTableOrderingComposer get shopId {
    final $$ShopsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableOrderingComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoriesTableAnnotationComposer
    extends Composer<_$UzaDatabase, $StoriesTable> {
  $$StoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<bool> get isArrivage => $composableBuilder(
    column: $table.isArrivage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ShopsTableAnnotationComposer get shopId {
    final $$ShopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableAnnotationComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> storyMediaRefs<T extends Object>(
    Expression<T> Function($$StoryMediaTableAnnotationComposer a) f,
  ) {
    final $$StoryMediaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storyMedia,
      getReferencedColumn: (t) => t.storyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoryMediaTableAnnotationComposer(
            $db: $db,
            $table: $db.storyMedia,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoriesTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $StoriesTable,
          Story,
          $$StoriesTableFilterComposer,
          $$StoriesTableOrderingComposer,
          $$StoriesTableAnnotationComposer,
          $$StoriesTableCreateCompanionBuilder,
          $$StoriesTableUpdateCompanionBuilder,
          (Story, $$StoriesTableReferences),
          Story,
          PrefetchHooks Function({bool shopId, bool storyMediaRefs})
        > {
  $$StoriesTableTableManager(_$UzaDatabase db, $StoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int> shopId = const Value.absent(),
                Value<String> mediaUrl = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<bool> isArrivage = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StoriesCompanion(
                id: id,
                remoteId: remoteId,
                shopId: shopId,
                mediaUrl: mediaUrl,
                mediaType: mediaType,
                isArrivage: isArrivage,
                expiresAt: expiresAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required int shopId,
                required String mediaUrl,
                required String mediaType,
                Value<bool> isArrivage = const Value.absent(),
                required DateTime expiresAt,
                Value<DateTime> createdAt = const Value.absent(),
              }) => StoriesCompanion.insert(
                id: id,
                remoteId: remoteId,
                shopId: shopId,
                mediaUrl: mediaUrl,
                mediaType: mediaType,
                isArrivage: isArrivage,
                expiresAt: expiresAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shopId = false, storyMediaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (storyMediaRefs) db.storyMedia],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shopId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shopId,
                                referencedTable: $$StoriesTableReferences
                                    ._shopIdTable(db),
                                referencedColumn: $$StoriesTableReferences
                                    ._shopIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (storyMediaRefs)
                    await $_getPrefetchedData<
                      Story,
                      $StoriesTable,
                      StoryMediaData
                    >(
                      currentTable: table,
                      referencedTable: $$StoriesTableReferences
                          ._storyMediaRefsTable(db),
                      managerFromTypedResult: (p0) => $$StoriesTableReferences(
                        db,
                        table,
                        p0,
                      ).storyMediaRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.storyId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $StoriesTable,
      Story,
      $$StoriesTableFilterComposer,
      $$StoriesTableOrderingComposer,
      $$StoriesTableAnnotationComposer,
      $$StoriesTableCreateCompanionBuilder,
      $$StoriesTableUpdateCompanionBuilder,
      (Story, $$StoriesTableReferences),
      Story,
      PrefetchHooks Function({bool shopId, bool storyMediaRefs})
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String action,
      required String entityType,
      required String entityData,
      Value<DateTime> createdAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> action,
      Value<String> entityType,
      Value<String> entityData,
      Value<DateTime> createdAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$UzaDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityData => $composableBuilder(
    column: $table.entityData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$UzaDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityData => $composableBuilder(
    column: $table.entityData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$UzaDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityData => $composableBuilder(
    column: $table.entityData,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$UzaDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$UzaDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityData = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                action: action,
                entityType: entityType,
                entityData: entityData,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String action,
                required String entityType,
                required String entityData,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                action: action,
                entityType: entityType,
                entityData: entityData,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$UzaDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$OfflineQueueTableCreateCompanionBuilder =
    OfflineQueueCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String action,
      required String payload,
      Value<String> status,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$OfflineQueueTableUpdateCompanionBuilder =
    OfflineQueueCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> action,
      Value<String> payload,
      Value<String> status,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$OfflineQueueTableFilterComposer
    extends Composer<_$UzaDatabase, $OfflineQueueTable> {
  $$OfflineQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineQueueTableOrderingComposer
    extends Composer<_$UzaDatabase, $OfflineQueueTable> {
  $$OfflineQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineQueueTableAnnotationComposer
    extends Composer<_$UzaDatabase, $OfflineQueueTable> {
  $$OfflineQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$OfflineQueueTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $OfflineQueueTable,
          OfflineQueueData,
          $$OfflineQueueTableFilterComposer,
          $$OfflineQueueTableOrderingComposer,
          $$OfflineQueueTableAnnotationComposer,
          $$OfflineQueueTableCreateCompanionBuilder,
          $$OfflineQueueTableUpdateCompanionBuilder,
          (
            OfflineQueueData,
            BaseReferences<_$UzaDatabase, $OfflineQueueTable, OfflineQueueData>,
          ),
          OfflineQueueData,
          PrefetchHooks Function()
        > {
  $$OfflineQueueTableTableManager(_$UzaDatabase db, $OfflineQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineQueueCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payload: payload,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String action,
                required String payload,
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payload: payload,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $OfflineQueueTable,
      OfflineQueueData,
      $$OfflineQueueTableFilterComposer,
      $$OfflineQueueTableOrderingComposer,
      $$OfflineQueueTableAnnotationComposer,
      $$OfflineQueueTableCreateCompanionBuilder,
      $$OfflineQueueTableUpdateCompanionBuilder,
      (
        OfflineQueueData,
        BaseReferences<_$UzaDatabase, $OfflineQueueTable, OfflineQueueData>,
      ),
      OfflineQueueData,
      PrefetchHooks Function()
    >;
typedef $$AnalyticsTableCreateCompanionBuilder =
    AnalyticsCompanion Function({
      Value<int> id,
      required String entityType,
      required String interactionType,
      required int entityId,
      Value<DateTime> createdAt,
    });
typedef $$AnalyticsTableUpdateCompanionBuilder =
    AnalyticsCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> interactionType,
      Value<int> entityId,
      Value<DateTime> createdAt,
    });

class $$AnalyticsTableFilterComposer
    extends Composer<_$UzaDatabase, $AnalyticsTable> {
  $$AnalyticsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interactionType => $composableBuilder(
    column: $table.interactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnalyticsTableOrderingComposer
    extends Composer<_$UzaDatabase, $AnalyticsTable> {
  $$AnalyticsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interactionType => $composableBuilder(
    column: $table.interactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnalyticsTableAnnotationComposer
    extends Composer<_$UzaDatabase, $AnalyticsTable> {
  $$AnalyticsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interactionType => $composableBuilder(
    column: $table.interactionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AnalyticsTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $AnalyticsTable,
          Analytic,
          $$AnalyticsTableFilterComposer,
          $$AnalyticsTableOrderingComposer,
          $$AnalyticsTableAnnotationComposer,
          $$AnalyticsTableCreateCompanionBuilder,
          $$AnalyticsTableUpdateCompanionBuilder,
          (Analytic, BaseReferences<_$UzaDatabase, $AnalyticsTable, Analytic>),
          Analytic,
          PrefetchHooks Function()
        > {
  $$AnalyticsTableTableManager(_$UzaDatabase db, $AnalyticsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalyticsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalyticsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalyticsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> interactionType = const Value.absent(),
                Value<int> entityId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnalyticsCompanion(
                id: id,
                entityType: entityType,
                interactionType: interactionType,
                entityId: entityId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String interactionType,
                required int entityId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnalyticsCompanion.insert(
                id: id,
                entityType: entityType,
                interactionType: interactionType,
                entityId: entityId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnalyticsTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $AnalyticsTable,
      Analytic,
      $$AnalyticsTableFilterComposer,
      $$AnalyticsTableOrderingComposer,
      $$AnalyticsTableAnnotationComposer,
      $$AnalyticsTableCreateCompanionBuilder,
      $$AnalyticsTableUpdateCompanionBuilder,
      (Analytic, BaseReferences<_$UzaDatabase, $AnalyticsTable, Analytic>),
      Analytic,
      PrefetchHooks Function()
    >;
typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      required String phone,
      Value<String?> name,
      Value<String?> avatarUrl,
      Value<bool> isPhoneVerified,
      Value<DateTime> createdAt,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String?> remoteId,
      Value<String> phone,
      Value<String?> name,
      Value<String?> avatarUrl,
      Value<bool> isPhoneVerified,
      Value<DateTime> createdAt,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$UzaDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPhoneVerified => $composableBuilder(
    column: $table.isPhoneVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$UzaDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPhoneVerified => $composableBuilder(
    column: $table.isPhoneVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$UzaDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<bool> get isPhoneVerified => $composableBuilder(
    column: $table.isPhoneVerified,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $UserProfilesTable,
          UserProfile,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfile,
            BaseReferences<_$UzaDatabase, $UserProfilesTable, UserProfile>,
          ),
          UserProfile,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$UzaDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isPhoneVerified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                remoteId: remoteId,
                phone: phone,
                name: name,
                avatarUrl: avatarUrl,
                isPhoneVerified: isPhoneVerified,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required String phone,
                Value<String?> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isPhoneVerified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                remoteId: remoteId,
                phone: phone,
                name: name,
                avatarUrl: avatarUrl,
                isPhoneVerified: isPhoneVerified,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $UserProfilesTable,
      UserProfile,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfile,
        BaseReferences<_$UzaDatabase, $UserProfilesTable, UserProfile>,
      ),
      UserProfile,
      PrefetchHooks Function()
    >;
typedef $$CartItemsTableCreateCompanionBuilder =
    CartItemsCompanion Function({
      Value<int> id,
      required int productId,
      Value<int> quantity,
      Value<DateTime> createdAt,
    });
typedef $$CartItemsTableUpdateCompanionBuilder =
    CartItemsCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<int> quantity,
      Value<DateTime> createdAt,
    });

final class $$CartItemsTableReferences
    extends BaseReferences<_$UzaDatabase, $CartItemsTable, CartItem> {
  $$CartItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$UzaDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.cartItems.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CartItemsTableFilterComposer
    extends Composer<_$UzaDatabase, $CartItemsTable> {
  $$CartItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CartItemsTableOrderingComposer
    extends Composer<_$UzaDatabase, $CartItemsTable> {
  $$CartItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CartItemsTableAnnotationComposer
    extends Composer<_$UzaDatabase, $CartItemsTable> {
  $$CartItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CartItemsTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $CartItemsTable,
          CartItem,
          $$CartItemsTableFilterComposer,
          $$CartItemsTableOrderingComposer,
          $$CartItemsTableAnnotationComposer,
          $$CartItemsTableCreateCompanionBuilder,
          $$CartItemsTableUpdateCompanionBuilder,
          (CartItem, $$CartItemsTableReferences),
          CartItem,
          PrefetchHooks Function({bool productId})
        > {
  $$CartItemsTableTableManager(_$UzaDatabase db, $CartItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CartItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CartItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CartItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CartItemsCompanion(
                id: id,
                productId: productId,
                quantity: quantity,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                Value<int> quantity = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CartItemsCompanion.insert(
                id: id,
                productId: productId,
                quantity: quantity,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CartItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$CartItemsTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$CartItemsTableReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CartItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $CartItemsTable,
      CartItem,
      $$CartItemsTableFilterComposer,
      $$CartItemsTableOrderingComposer,
      $$CartItemsTableAnnotationComposer,
      $$CartItemsTableCreateCompanionBuilder,
      $$CartItemsTableUpdateCompanionBuilder,
      (CartItem, $$CartItemsTableReferences),
      CartItem,
      PrefetchHooks Function({bool productId})
    >;
typedef $$UserContactsTableCreateCompanionBuilder =
    UserContactsCompanion Function({
      Value<int> id,
      required int shopId,
      required String userPhone,
      Value<String?> userName,
      required String contactType,
      Value<int?> productId,
      Value<DateTime> createdAt,
    });
typedef $$UserContactsTableUpdateCompanionBuilder =
    UserContactsCompanion Function({
      Value<int> id,
      Value<int> shopId,
      Value<String> userPhone,
      Value<String?> userName,
      Value<String> contactType,
      Value<int?> productId,
      Value<DateTime> createdAt,
    });

final class $$UserContactsTableReferences
    extends BaseReferences<_$UzaDatabase, $UserContactsTable, UserContact> {
  $$UserContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShopsTable _shopIdTable(_$UzaDatabase db) => db.shops.createAlias(
    $_aliasNameGenerator(db.userContacts.shopId, db.shops.id),
  );

  $$ShopsTableProcessedTableManager get shopId {
    final $_column = $_itemColumn<int>('shop_id')!;

    final manager = $$ShopsTableTableManager(
      $_db,
      $_db.shops,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$UzaDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.userContacts.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<int>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserContactsTableFilterComposer
    extends Composer<_$UzaDatabase, $UserContactsTable> {
  $$UserContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userPhone => $composableBuilder(
    column: $table.userPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactType => $composableBuilder(
    column: $table.contactType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShopsTableFilterComposer get shopId {
    final $$ShopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableFilterComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserContactsTableOrderingComposer
    extends Composer<_$UzaDatabase, $UserContactsTable> {
  $$UserContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userPhone => $composableBuilder(
    column: $table.userPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactType => $composableBuilder(
    column: $table.contactType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShopsTableOrderingComposer get shopId {
    final $$ShopsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableOrderingComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserContactsTableAnnotationComposer
    extends Composer<_$UzaDatabase, $UserContactsTable> {
  $$UserContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userPhone =>
      $composableBuilder(column: $table.userPhone, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get contactType => $composableBuilder(
    column: $table.contactType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ShopsTableAnnotationComposer get shopId {
    final $$ShopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableAnnotationComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserContactsTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $UserContactsTable,
          UserContact,
          $$UserContactsTableFilterComposer,
          $$UserContactsTableOrderingComposer,
          $$UserContactsTableAnnotationComposer,
          $$UserContactsTableCreateCompanionBuilder,
          $$UserContactsTableUpdateCompanionBuilder,
          (UserContact, $$UserContactsTableReferences),
          UserContact,
          PrefetchHooks Function({bool shopId, bool productId})
        > {
  $$UserContactsTableTableManager(_$UzaDatabase db, $UserContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> shopId = const Value.absent(),
                Value<String> userPhone = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<String> contactType = const Value.absent(),
                Value<int?> productId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserContactsCompanion(
                id: id,
                shopId: shopId,
                userPhone: userPhone,
                userName: userName,
                contactType: contactType,
                productId: productId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int shopId,
                required String userPhone,
                Value<String?> userName = const Value.absent(),
                required String contactType,
                Value<int?> productId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserContactsCompanion.insert(
                id: id,
                shopId: shopId,
                userPhone: userPhone,
                userName: userName,
                contactType: contactType,
                productId: productId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shopId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shopId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shopId,
                                referencedTable: $$UserContactsTableReferences
                                    ._shopIdTable(db),
                                referencedColumn: $$UserContactsTableReferences
                                    ._shopIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$UserContactsTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$UserContactsTableReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $UserContactsTable,
      UserContact,
      $$UserContactsTableFilterComposer,
      $$UserContactsTableOrderingComposer,
      $$UserContactsTableAnnotationComposer,
      $$UserContactsTableCreateCompanionBuilder,
      $$UserContactsTableUpdateCompanionBuilder,
      (UserContact, $$UserContactsTableReferences),
      UserContact,
      PrefetchHooks Function({bool shopId, bool productId})
    >;
typedef $$AppPreferencesTableCreateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<int> id,
      Value<bool> isDarkMode,
      Value<String> language,
      Value<bool> notificationsEnabled,
      Value<bool> isLiteMode,
      Value<bool> biometricEnabled,
      Value<String?> userCommune,
      Value<DateTime?> lastSync,
    });
typedef $$AppPreferencesTableUpdateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<int> id,
      Value<bool> isDarkMode,
      Value<String> language,
      Value<bool> notificationsEnabled,
      Value<bool> isLiteMode,
      Value<bool> biometricEnabled,
      Value<String?> userCommune,
      Value<DateTime?> lastSync,
    });

class $$AppPreferencesTableFilterComposer
    extends Composer<_$UzaDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLiteMode => $composableBuilder(
    column: $table.isLiteMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userCommune => $composableBuilder(
    column: $table.userCommune,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPreferencesTableOrderingComposer
    extends Composer<_$UzaDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLiteMode => $composableBuilder(
    column: $table.isLiteMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userCommune => $composableBuilder(
    column: $table.userCommune,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPreferencesTableAnnotationComposer
    extends Composer<_$UzaDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLiteMode => $composableBuilder(
    column: $table.isLiteMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userCommune => $composableBuilder(
    column: $table.userCommune,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$AppPreferencesTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $AppPreferencesTable,
          AppPreference,
          $$AppPreferencesTableFilterComposer,
          $$AppPreferencesTableOrderingComposer,
          $$AppPreferencesTableAnnotationComposer,
          $$AppPreferencesTableCreateCompanionBuilder,
          $$AppPreferencesTableUpdateCompanionBuilder,
          (
            AppPreference,
            BaseReferences<_$UzaDatabase, $AppPreferencesTable, AppPreference>,
          ),
          AppPreference,
          PrefetchHooks Function()
        > {
  $$AppPreferencesTableTableManager(
    _$UzaDatabase db,
    $AppPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isDarkMode = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> isLiteMode = const Value.absent(),
                Value<bool> biometricEnabled = const Value.absent(),
                Value<String?> userCommune = const Value.absent(),
                Value<DateTime?> lastSync = const Value.absent(),
              }) => AppPreferencesCompanion(
                id: id,
                isDarkMode: isDarkMode,
                language: language,
                notificationsEnabled: notificationsEnabled,
                isLiteMode: isLiteMode,
                biometricEnabled: biometricEnabled,
                userCommune: userCommune,
                lastSync: lastSync,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isDarkMode = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> isLiteMode = const Value.absent(),
                Value<bool> biometricEnabled = const Value.absent(),
                Value<String?> userCommune = const Value.absent(),
                Value<DateTime?> lastSync = const Value.absent(),
              }) => AppPreferencesCompanion.insert(
                id: id,
                isDarkMode: isDarkMode,
                language: language,
                notificationsEnabled: notificationsEnabled,
                isLiteMode: isLiteMode,
                biometricEnabled: biometricEnabled,
                userCommune: userCommune,
                lastSync: lastSync,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $AppPreferencesTable,
      AppPreference,
      $$AppPreferencesTableFilterComposer,
      $$AppPreferencesTableOrderingComposer,
      $$AppPreferencesTableAnnotationComposer,
      $$AppPreferencesTableCreateCompanionBuilder,
      $$AppPreferencesTableUpdateCompanionBuilder,
      (
        AppPreference,
        BaseReferences<_$UzaDatabase, $AppPreferencesTable, AppPreference>,
      ),
      AppPreference,
      PrefetchHooks Function()
    >;
typedef $$WishlistProductsTableCreateCompanionBuilder =
    WishlistProductsCompanion Function({
      Value<int> id,
      required int productId,
      Value<DateTime> createdAt,
    });
typedef $$WishlistProductsTableUpdateCompanionBuilder =
    WishlistProductsCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<DateTime> createdAt,
    });

final class $$WishlistProductsTableReferences
    extends
        BaseReferences<_$UzaDatabase, $WishlistProductsTable, WishlistProduct> {
  $$WishlistProductsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$UzaDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.wishlistProducts.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WishlistProductsTableFilterComposer
    extends Composer<_$UzaDatabase, $WishlistProductsTable> {
  $$WishlistProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WishlistProductsTableOrderingComposer
    extends Composer<_$UzaDatabase, $WishlistProductsTable> {
  $$WishlistProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WishlistProductsTableAnnotationComposer
    extends Composer<_$UzaDatabase, $WishlistProductsTable> {
  $$WishlistProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WishlistProductsTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $WishlistProductsTable,
          WishlistProduct,
          $$WishlistProductsTableFilterComposer,
          $$WishlistProductsTableOrderingComposer,
          $$WishlistProductsTableAnnotationComposer,
          $$WishlistProductsTableCreateCompanionBuilder,
          $$WishlistProductsTableUpdateCompanionBuilder,
          (WishlistProduct, $$WishlistProductsTableReferences),
          WishlistProduct,
          PrefetchHooks Function({bool productId})
        > {
  $$WishlistProductsTableTableManager(
    _$UzaDatabase db,
    $WishlistProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WishlistProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WishlistProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WishlistProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WishlistProductsCompanion(
                id: id,
                productId: productId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => WishlistProductsCompanion.insert(
                id: id,
                productId: productId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WishlistProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$WishlistProductsTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$WishlistProductsTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WishlistProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $WishlistProductsTable,
      WishlistProduct,
      $$WishlistProductsTableFilterComposer,
      $$WishlistProductsTableOrderingComposer,
      $$WishlistProductsTableAnnotationComposer,
      $$WishlistProductsTableCreateCompanionBuilder,
      $$WishlistProductsTableUpdateCompanionBuilder,
      (WishlistProduct, $$WishlistProductsTableReferences),
      WishlistProduct,
      PrefetchHooks Function({bool productId})
    >;
typedef $$FollowedShopsTableCreateCompanionBuilder =
    FollowedShopsCompanion Function({
      Value<int> id,
      required int shopId,
      Value<DateTime> createdAt,
    });
typedef $$FollowedShopsTableUpdateCompanionBuilder =
    FollowedShopsCompanion Function({
      Value<int> id,
      Value<int> shopId,
      Value<DateTime> createdAt,
    });

final class $$FollowedShopsTableReferences
    extends BaseReferences<_$UzaDatabase, $FollowedShopsTable, FollowedShop> {
  $$FollowedShopsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShopsTable _shopIdTable(_$UzaDatabase db) => db.shops.createAlias(
    $_aliasNameGenerator(db.followedShops.shopId, db.shops.id),
  );

  $$ShopsTableProcessedTableManager get shopId {
    final $_column = $_itemColumn<int>('shop_id')!;

    final manager = $$ShopsTableTableManager(
      $_db,
      $_db.shops,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FollowedShopsTableFilterComposer
    extends Composer<_$UzaDatabase, $FollowedShopsTable> {
  $$FollowedShopsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShopsTableFilterComposer get shopId {
    final $$ShopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableFilterComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FollowedShopsTableOrderingComposer
    extends Composer<_$UzaDatabase, $FollowedShopsTable> {
  $$FollowedShopsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShopsTableOrderingComposer get shopId {
    final $$ShopsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableOrderingComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FollowedShopsTableAnnotationComposer
    extends Composer<_$UzaDatabase, $FollowedShopsTable> {
  $$FollowedShopsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ShopsTableAnnotationComposer get shopId {
    final $$ShopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shopId,
      referencedTable: $db.shops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShopsTableAnnotationComposer(
            $db: $db,
            $table: $db.shops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FollowedShopsTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $FollowedShopsTable,
          FollowedShop,
          $$FollowedShopsTableFilterComposer,
          $$FollowedShopsTableOrderingComposer,
          $$FollowedShopsTableAnnotationComposer,
          $$FollowedShopsTableCreateCompanionBuilder,
          $$FollowedShopsTableUpdateCompanionBuilder,
          (FollowedShop, $$FollowedShopsTableReferences),
          FollowedShop,
          PrefetchHooks Function({bool shopId})
        > {
  $$FollowedShopsTableTableManager(_$UzaDatabase db, $FollowedShopsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowedShopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowedShopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowedShopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> shopId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FollowedShopsCompanion(
                id: id,
                shopId: shopId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int shopId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FollowedShopsCompanion.insert(
                id: id,
                shopId: shopId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FollowedShopsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shopId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shopId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shopId,
                                referencedTable: $$FollowedShopsTableReferences
                                    ._shopIdTable(db),
                                referencedColumn: $$FollowedShopsTableReferences
                                    ._shopIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FollowedShopsTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $FollowedShopsTable,
      FollowedShop,
      $$FollowedShopsTableFilterComposer,
      $$FollowedShopsTableOrderingComposer,
      $$FollowedShopsTableAnnotationComposer,
      $$FollowedShopsTableCreateCompanionBuilder,
      $$FollowedShopsTableUpdateCompanionBuilder,
      (FollowedShop, $$FollowedShopsTableReferences),
      FollowedShop,
      PrefetchHooks Function({bool shopId})
    >;
typedef $$ProductReviewsTableCreateCompanionBuilder =
    ProductReviewsCompanion Function({
      Value<int> id,
      required int productId,
      Value<String?> userName,
      required String comment,
      required double rating,
      Value<DateTime> createdAt,
    });
typedef $$ProductReviewsTableUpdateCompanionBuilder =
    ProductReviewsCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<String?> userName,
      Value<String> comment,
      Value<double> rating,
      Value<DateTime> createdAt,
    });

final class $$ProductReviewsTableReferences
    extends BaseReferences<_$UzaDatabase, $ProductReviewsTable, ProductReview> {
  $$ProductReviewsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$UzaDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.productReviews.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductReviewsTableFilterComposer
    extends Composer<_$UzaDatabase, $ProductReviewsTable> {
  $$ProductReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductReviewsTableOrderingComposer
    extends Composer<_$UzaDatabase, $ProductReviewsTable> {
  $$ProductReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductReviewsTableAnnotationComposer
    extends Composer<_$UzaDatabase, $ProductReviewsTable> {
  $$ProductReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductReviewsTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $ProductReviewsTable,
          ProductReview,
          $$ProductReviewsTableFilterComposer,
          $$ProductReviewsTableOrderingComposer,
          $$ProductReviewsTableAnnotationComposer,
          $$ProductReviewsTableCreateCompanionBuilder,
          $$ProductReviewsTableUpdateCompanionBuilder,
          (ProductReview, $$ProductReviewsTableReferences),
          ProductReview,
          PrefetchHooks Function({bool productId})
        > {
  $$ProductReviewsTableTableManager(
    _$UzaDatabase db,
    $ProductReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String?> userName = const Value.absent(),
                Value<String> comment = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProductReviewsCompanion(
                id: id,
                productId: productId,
                userName: userName,
                comment: comment,
                rating: rating,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                Value<String?> userName = const Value.absent(),
                required String comment,
                required double rating,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProductReviewsCompanion.insert(
                id: id,
                productId: productId,
                userName: userName,
                comment: comment,
                rating: rating,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$ProductReviewsTableReferences
                                    ._productIdTable(db),
                                referencedColumn:
                                    $$ProductReviewsTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProductReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $ProductReviewsTable,
      ProductReview,
      $$ProductReviewsTableFilterComposer,
      $$ProductReviewsTableOrderingComposer,
      $$ProductReviewsTableAnnotationComposer,
      $$ProductReviewsTableCreateCompanionBuilder,
      $$ProductReviewsTableUpdateCompanionBuilder,
      (ProductReview, $$ProductReviewsTableReferences),
      ProductReview,
      PrefetchHooks Function({bool productId})
    >;
typedef $$StoryMediaTableCreateCompanionBuilder =
    StoryMediaCompanion Function({
      Value<int> id,
      required int storyId,
      required String mediaUrl,
      Value<String> mediaType,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });
typedef $$StoryMediaTableUpdateCompanionBuilder =
    StoryMediaCompanion Function({
      Value<int> id,
      Value<int> storyId,
      Value<String> mediaUrl,
      Value<String> mediaType,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$StoryMediaTableReferences
    extends BaseReferences<_$UzaDatabase, $StoryMediaTable, StoryMediaData> {
  $$StoryMediaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoriesTable _storyIdTable(_$UzaDatabase db) => db.stories
      .createAlias($_aliasNameGenerator(db.storyMedia.storyId, db.stories.id));

  $$StoriesTableProcessedTableManager get storyId {
    final $_column = $_itemColumn<int>('story_id')!;

    final manager = $$StoriesTableTableManager(
      $_db,
      $_db.stories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoryMediaTableFilterComposer
    extends Composer<_$UzaDatabase, $StoryMediaTable> {
  $$StoryMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoriesTableFilterComposer get storyId {
    final $$StoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableFilterComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryMediaTableOrderingComposer
    extends Composer<_$UzaDatabase, $StoryMediaTable> {
  $$StoryMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoriesTableOrderingComposer get storyId {
    final $$StoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableOrderingComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryMediaTableAnnotationComposer
    extends Composer<_$UzaDatabase, $StoryMediaTable> {
  $$StoryMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$StoriesTableAnnotationComposer get storyId {
    final $$StoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoryMediaTableTableManager
    extends
        RootTableManager<
          _$UzaDatabase,
          $StoryMediaTable,
          StoryMediaData,
          $$StoryMediaTableFilterComposer,
          $$StoryMediaTableOrderingComposer,
          $$StoryMediaTableAnnotationComposer,
          $$StoryMediaTableCreateCompanionBuilder,
          $$StoryMediaTableUpdateCompanionBuilder,
          (StoryMediaData, $$StoryMediaTableReferences),
          StoryMediaData,
          PrefetchHooks Function({bool storyId})
        > {
  $$StoryMediaTableTableManager(_$UzaDatabase db, $StoryMediaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryMediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storyId = const Value.absent(),
                Value<String> mediaUrl = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StoryMediaCompanion(
                id: id,
                storyId: storyId,
                mediaUrl: mediaUrl,
                mediaType: mediaType,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storyId,
                required String mediaUrl,
                Value<String> mediaType = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StoryMediaCompanion.insert(
                id: id,
                storyId: storyId,
                mediaUrl: mediaUrl,
                mediaType: mediaType,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoryMediaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({storyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (storyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.storyId,
                                referencedTable: $$StoryMediaTableReferences
                                    ._storyIdTable(db),
                                referencedColumn: $$StoryMediaTableReferences
                                    ._storyIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StoryMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$UzaDatabase,
      $StoryMediaTable,
      StoryMediaData,
      $$StoryMediaTableFilterComposer,
      $$StoryMediaTableOrderingComposer,
      $$StoryMediaTableAnnotationComposer,
      $$StoryMediaTableCreateCompanionBuilder,
      $$StoryMediaTableUpdateCompanionBuilder,
      (StoryMediaData, $$StoryMediaTableReferences),
      StoryMediaData,
      PrefetchHooks Function({bool storyId})
    >;

class $UzaDatabaseManager {
  final _$UzaDatabase _db;
  $UzaDatabaseManager(this._db);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db, _db.shops);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db, _db.stories);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$OfflineQueueTableTableManager get offlineQueue =>
      $$OfflineQueueTableTableManager(_db, _db.offlineQueue);
  $$AnalyticsTableTableManager get analytics =>
      $$AnalyticsTableTableManager(_db, _db.analytics);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$CartItemsTableTableManager get cartItems =>
      $$CartItemsTableTableManager(_db, _db.cartItems);
  $$UserContactsTableTableManager get userContacts =>
      $$UserContactsTableTableManager(_db, _db.userContacts);
  $$AppPreferencesTableTableManager get appPreferences =>
      $$AppPreferencesTableTableManager(_db, _db.appPreferences);
  $$WishlistProductsTableTableManager get wishlistProducts =>
      $$WishlistProductsTableTableManager(_db, _db.wishlistProducts);
  $$FollowedShopsTableTableManager get followedShops =>
      $$FollowedShopsTableTableManager(_db, _db.followedShops);
  $$ProductReviewsTableTableManager get productReviews =>
      $$ProductReviewsTableTableManager(_db, _db.productReviews);
  $$StoryMediaTableTableManager get storyMedia =>
      $$StoryMediaTableTableManager(_db, _db.storyMedia);
}
