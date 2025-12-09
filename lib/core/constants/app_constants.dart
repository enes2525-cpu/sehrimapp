/// Uygulama genelinde kullanılan sabit değerler
class AppConstants {
  // Uygulama Bilgileri
  static const String appName = 'ŞehrimApp';
  static const String appVersion = '4.0.0';
  static const String appTagline = 'Şehrinin Pazaryeri';

  // Token Sistemi
  static const int tokenPerAdCreate = 10;
  static const int tokenPerAdFeatured = 20;
  static const int tokenPerMessage = 1;
  static const int tokenPerLike = 1;
  static const int tokenWelcomeBonus = 50;
  static const int tokenReferralBonus = 50;
  static const int tokenDailyBonus = 5;

  // İlan Limitleri
  static const int maxAdImages = 5;
  static const int maxAdTitleLength = 100;
  static const int maxAdDescriptionLength = 1000;
  static const int minAdPrice = 0;
  static const int maxAdPrice = 999999999;

  // Kullanıcı Limitleri
  static const int maxNameLength = 50;
  static const int minPasswordLength = 6;
  static const int maxBioLength = 200;

  // Feed Limitleri
  static const int maxPostLength = 500;
  static const int maxPostImages = 4;
  static const int maxCommentLength = 200;

  // Dükkan Limitleri
  static const int maxShopNameLength = 50;
  static const int maxShopDescriptionLength = 500;
  static const double minRating = 0.0;
  static const double maxRating = 5.0;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Cache Süreleri (dakika)
  static const int adsCacheDuration = 5;
  static const int userCacheDuration = 10;
  static const int shopsCacheDuration = 15;

  // API & Firebase
  static const int requestTimeout = 30; // saniye
  static const int maxRetryAttempts = 3;

  // Dosya Yükleme
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 80;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Kategoriler
  static const List<String> categories = [
    'Elektronik',
    'Moda',
    'Ev & Yaşam',
    'Kitap & Hobi',
    'Spor',
    'Kozmetik',
    'Otomotiv',
    'Emlak',
    'Hizmetler',
    'Diğer',
  ];

  // Şehirler (örnek - tümünü ekleyebilirsin)
  static const List<String> cities = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Antalya',
    'Adana',
    'Konya',
    'Gaziantep',
    'Kayseri',
    'Erzurum',
    // ... diğer şehirler
  ];

  // Bildirim Tipleri
  static const String notificationTypeMessage = 'message';
  static const String notificationTypeLike = 'like';
  static const String notificationTypeComment = 'comment';
  static const String notificationTypeAppointment = 'appointment';
  static const String notificationTypeFollow = 'follow';
  static const String notificationTypeDiscount = 'discount';

  // Rozet Tipleri
  static const String badgeVerified = 'verified';
  static const String badgePremium = 'premium';
  static const String badgeTopSeller = 'top_seller';
  static const String badgeNewUser = 'new_user';
  static const String badgePopular = 'popular';

  // Hata Mesajları
  static const String errorGeneric = 'Bir hata oluştu. Lütfen tekrar deneyin.';
  static const String errorNetwork = 'İnternet bağlantınızı kontrol edin.';
  static const String errorAuth = 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.';
  static const String errorInsufficientTokens = 'Yetersiz token. Lütfen token satın alın.';
  static const String errorPermission = 'Bu işlem için yetkiniz yok.';

  // Başarı Mesajları
  static const String successAdCreated = 'İlan başarıyla oluşturuldu!';
  static const String successAdUpdated = 'İlan güncellendi!';
  static const String successAdDeleted = 'İlan silindi!';
  static const String successProfileUpdated = 'Profil güncellendi!';

  // Firebase Collection İsimleri
  static const String collectionUsers = 'users';
  static const String collectionAds = 'ads';
  static const String collectionShops = 'businesses';
  static const String collectionChats = 'chats';
  static const String collectionMessages = 'messages';
  static const String collectionPosts = 'posts';
  static const String collectionComments = 'comments';
  static const String collectionNotifications = 'notifications';
  static const String collectionFollows = 'follows';
  static const String collectionBlocks = 'blocks';
  static const String collectionRatings = 'ratings';
  static const String collectionReports = 'reports';
  static const String collectionReferrals = 'referrals';
  static const String collectionAppointments = 'appointments';
  static const String collectionViewHistory = 'view_history';

  // Routes (sayfa isimleri)
  static const String routeHome = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeAdDetail = '/ad-detail';
  static const String routeCreateAd = '/create-ad';
  static const String routeProfile = '/profile';
  static const String routeChat = '/chat';
  static const String routeNotifications = '/notifications';

  AppConstants._(); // Private constructor - instantiate edilemez
}
