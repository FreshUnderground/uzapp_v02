/// Shop interaction types synced to the server (`shop_analytics` table).
class ShopStatsTypes {
  ShopStatsTypes._();

  static const view = 'view';
  static const share = 'share';
  static const catalogShare = 'catalog_share';
  static const qrShare = 'qr_share';
  static const storyShare = 'story_share';
  static const whatsappStatus = 'whatsapp_status';
  static const facebookStatus = 'facebook_status';
  static const tiktokStatus = 'tiktok_status';

  static const Set<String> synced = {
    view,
    share,
    catalogShare,
    qrShare,
    storyShare,
    whatsappStatus,
    facebookStatus,
    tiktokStatus,
  };

  static bool isSynced(String type) => synced.contains(type);

  static bool isShare(String type) =>
      type != view && synced.contains(type);
}
