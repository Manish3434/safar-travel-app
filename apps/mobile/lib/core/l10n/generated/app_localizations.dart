import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
    Locale('hi'),
  ];

  String get appTitle;
  String get whereDoYouWantToGo;
  String get searchHint;
  String get popularDestinations;
  String get savedPlaces;
  String get noSavedPlaces;
  String get explorePlaces;
  String get weather;
  String get stays;
  String get transport;
  String get distance;
  String get travelTime;
  String get howToReach;
  String get bestSeason;
  String get permitRequired;
  String get guideRequired;
  String get sensitiveSpotWarning;
  String get savePlace;
  String get saved;
  String get login;
  String get logout;
  String get email;
  String get password;
  String get search;
  String get categories;
  String get hillStation;
  String get waterfall;
  String get heritage;
  String get forest;
  String get beaches;
  String get birdSanctuary;
  String get wildlife;
  String get museum;
  String get city;
  String get all;
  String get exploreDistricts;
  String get allSpots;
  String get perNight;
  String get lastUpdated;
  String get viewOnMap;
  String get noResultsFound;
  String get errorLoading;
  String get retry;
  String get offlineMaps;
  String get downloadedMaps;
  String get noOfflineMaps;
  String get downloadMapHint;
  String get clearAllMaps;
  String get clearAllConfirm;
  String get deleteMap;
  String get storageUsed;
  String get totalTiles;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ta', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'ta':
      return AppLocalizationsTa();
    case 'hi':
      return AppLocalizationsHi();
    case 'en':
    default:
      return AppLocalizationsEn();
  }
}

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override String get appTitle => 'Safar';
  @override String get whereDoYouWantToGo => 'Where do you want to go?';
  @override String get searchHint => 'Search cities, waterfalls, villages...';
  @override String get popularDestinations => 'Popular Destinations';
  @override String get savedPlaces => 'Saved Places';
  @override String get noSavedPlaces => 'No saved places yet';
  @override String get explorePlaces => 'Explore Places';
  @override String get weather => 'Weather';
  @override String get stays => 'Nearby Stays';
  @override String get transport => 'Transport & Bus Timings';
  @override String get distance => 'Distance';
  @override String get travelTime => 'Est. Travel Time';
  @override String get howToReach => 'How to Reach';
  @override String get bestSeason => 'Best Season';
  @override String get permitRequired => 'Permit Required';
  @override String get guideRequired => 'Guide Required';
  @override String get sensitiveSpotWarning => 'Sensitive ecological area. Exact coordinates are protected.';
  @override String get savePlace => 'Save';
  @override String get saved => 'Saved';
  @override String get login => 'Login';
  @override String get logout => 'Logout';
  @override String get email => 'Email';
  @override String get password => 'Password';
  @override String get search => 'Search';
  @override String get categories => 'Categories';
  @override String get hillStation => 'Hill Stations';
  @override String get waterfall => 'Waterfalls';
  @override String get heritage => 'Heritage';
  @override String get forest => 'Forests';
  @override String get beaches => 'Beaches';
  @override String get birdSanctuary => 'Bird Sanctuaries';
  @override String get wildlife => 'Wildlife & Sanctuaries';
  @override String get museum => 'Museums';
  @override String get city => 'Cities';
  @override String get all => 'All';
  @override String get exploreDistricts => 'Explore Districts';
  @override String get allSpots => 'All Spots';
  @override String get perNight => 'per night';
  @override String get lastUpdated => 'Last updated';
  @override String get viewOnMap => 'View on Map';
  @override String get noResultsFound => 'No places found';
  @override String get errorLoading => 'Something went wrong';
  @override String get retry => 'Retry';
  @override String get offlineMaps => 'Offline Maps';
  @override String get downloadedMaps => 'Downloaded Maps';
  @override String get noOfflineMaps => 'No offline maps downloaded';
  @override String get downloadMapHint => 'Download regional map tiles from any place page for seamless offline navigation without internet.';
  @override String get clearAllMaps => 'Clear All Maps';
  @override String get clearAllConfirm => 'Are you sure you want to delete all downloaded offline maps?';
  @override String get deleteMap => 'Delete Map';
  @override String get storageUsed => 'Storage Used';
  @override String get totalTiles => 'Total Tiles';
}

class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override String get appTitle => 'சஃபார்';
  @override String get whereDoYouWantToGo => 'எங்கு செல்ல விரும்புகிறீர்கள்?';
  @override String get searchHint => 'நகரங்கள், அருவிகள், கிராமங்களை தேடுங்கள்...';
  @override String get popularDestinations => 'பிரபலமான இடங்கள்';
  @override String get savedPlaces => 'சேமிக்கப்பட்ட இடங்கள்';
  @override String get noSavedPlaces => 'சேமிக்கப்பட்ட இடங்கள் எதுவும் இல்லை';
  @override String get explorePlaces => 'இடங்களை ஆராயுங்கள்';
  @override String get weather => 'வானிலை';
  @override String get stays => 'அருகிலுள்ள தங்கும் இடங்கள்';
  @override String get transport => 'பேருந்து மற்றும் போக்குவரத்து நேரங்கள்';
  @override String get distance => 'தூரம்';
  @override String get travelTime => 'பயண நேரம்';
  @override String get howToReach => 'எப்படி அடைவது';
  @override String get bestSeason => 'சிறந்த பருவம்';
  @override String get permitRequired => 'அனுமதி தேவை';
  @override String get guideRequired => 'வழிகாட்டி தேவை';
  @override String get sensitiveSpotWarning => 'சுற்றுச்சூழல் பாதுகாப்பு பகுதி. துல்லியமான இடம் மறைக்கப்பட்டுள்ளது.';
  @override String get savePlace => 'சேமி';
  @override String get saved => 'சேமிக்கப்பட்டது';
  @override String get login => 'உள்நுழை';
  @override String get logout => 'வெளியேறு';
  @override String get email => 'மின்னஞ்சல்';
  @override String get password => 'கடவுச்சொல்';
  @override String get search => 'தேடு';
  @override String get categories => 'வகைகள்';
  @override String get hillStation => 'மலைவாசஸ்தலங்கள்';
  @override String get waterfall => 'அருவிகள்';
  @override String get heritage => 'பாரம்பரியம்';
  @override String get forest => 'காடுகள்';
  @override String get beaches => 'கடற்கரைகள்';
  @override String get birdSanctuary => 'பறவைகள் சரணாலயம்';
  @override String get wildlife => 'வனவிலங்கு சரணாலயம்';
  @override String get museum => 'அருங்காட்சியகங்கள்';
  @override String get city => 'நகரங்கள்';
  @override String get all => 'அனைத்தும்';
  @override String get exploreDistricts => 'மாவட்டங்களை ஆராயுங்கள்';
  @override String get allSpots => 'அனைத்து இடங்கள்';
  @override String get perNight => 'இரவுக்கு';
  @override String get lastUpdated => 'கடைசியாக புதுப்பிக்கப்பட்டது';
  @override String get viewOnMap => 'வரைபடத்தில் காண்க';
  @override String get noResultsFound => 'இடங்கள் எதுவும் கிடைக்கவில்லை';
  @override String get errorLoading => 'பிழை ஏற்பட்டது';
  @override String get retry => 'மீண்டும் முயற்சி செய்';
  @override String get offlineMaps => 'பதிவிறக்கிய வரைபடங்கள்';
  @override String get downloadedMaps => 'பதிவிறக்கப்பட்ட வரைபடங்கள்';
  @override String get noOfflineMaps => 'பதிவிறக்கப்பட்ட வரைபடங்கள் எதுவும் இல்லை';
  @override String get downloadMapHint => 'இணையம் இல்லாமல் வரைபடத்தைப் பார்க்க எந்த இடத்தின் பக்கத்திலிருந்தும் வரைபடத்தை பதிவிறக்குங்கள்.';
  @override String get clearAllMaps => 'அனைத்து வரைபடங்களையும் நீக்கு';
  @override String get clearAllConfirm => 'அனைத்து பதிவிறக்கப்பட்ட வரைபடங்களையும் நீக்க விரும்புகிறீர்களா?';
  @override String get deleteMap => 'வரைபடத்தை நீக்கு';
  @override String get storageUsed => 'பயன்படுத்தப்பட்ட சேமிப்பு';
  @override String get totalTiles => 'மொத்த வரைபடத் துண்டுகள்';
}

class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override String get appTitle => 'सफ़र';
  @override String get whereDoYouWantToGo => 'आप कहाँ जाना चाहते हैं?';
  @override String get searchHint => 'शहर, झरने, गाँव खोजें...';
  @override String get popularDestinations => 'लोकप्रिय गंतव्य';
  @override String get savedPlaces => 'सहेजे गए स्थान';
  @override String get noSavedPlaces => 'अभी तक कोई सहेजा गया स्थान नहीं';
  @override String get explorePlaces => 'स्थान देखें';
  @override String get weather => 'मौसम';
  @override String get stays => 'आस-पास के होटल';
  @override String get transport => 'परिवहन और बस समय';
  @override String get distance => 'दूरी';
  @override String get travelTime => 'अनुमानित यात्रा समय';
  @override String get howToReach => 'कैसे पहुंचे';
  @override String get bestSeason => 'सर्वोत्तम मौसम';
  @override String get permitRequired => 'परमिट आवश्यक';
  @override String get guideRequired => 'गाइड आवश्यक';
  @override String get sensitiveSpotWarning => 'संवेदनशील पारिस्थितिक क्षेत्र। सटीक निर्देशांक सुरक्षित हैं।';
  @override String get savePlace => 'सहेजें';
  @override String get saved => 'सहेजा गया';
  @override String get login => 'लॉगिन';
  @override String get logout => 'लॉगआउट';
  @override String get email => 'ईमेल';
  @override String get password => 'पासवर्ड';
  @override String get search => 'खोजें';
  @override String get categories => 'श्रेणियाँ';
  @override String get hillStation => 'हिल स्टेशन';
  @override String get waterfall => 'झरने';
  @override String get heritage => 'धरोहर';
  @override String get forest => 'वन';
  @override String get beaches => 'समुद्र तट';
  @override String get birdSanctuary => 'पक्षी अभयारण्य';
  @override String get wildlife => 'वन्यजीव अभयारण्य';
  @override String get museum => 'संग्रहालय';
  @override String get city => 'शहर';
  @override String get all => 'सभी';
  @override String get exploreDistricts => 'ज़िले देखें';
  @override String get allSpots => 'सभी स्थान';
  @override String get perNight => 'प्रति रात';
  @override String get lastUpdated => 'अंतिम अद्यतन';
  @override String get viewOnMap => 'मानचित्र पर देखें';
  @override String get noResultsFound => 'कोई स्थान नहीं मिला';
  @override String get errorLoading => 'कुछ गलत हो गया';
  @override String get retry => 'पुनः प्रयास करें';
  @override String get offlineMaps => 'ऑफ़लाइन मानचित्र';
  @override String get downloadedMaps => 'डाउनलोड किए गए मानचित्र';
  @override String get noOfflineMaps => 'कोई ऑफ़लाइन मानचित्र डाउनलोड नहीं किया गया';
  @override String get downloadMapHint => 'बिना इंटरनेट के नेविगेशन के लिए किसी भी स्थान पृष्ठ से क्षेत्रीय मानचित्र डाउनलोड करें।';
  @override String get clearAllMaps => 'सभी मानचित्र हटाएं';
  @override String get clearAllConfirm => 'क्या आप वाकई सभी डाउनलोड किए गए ऑफ़लाइन मानचित्र हटाना चाहते हैं?';
  @override String get deleteMap => 'मानचित्र हटाएं';
  @override String get storageUsed => 'प्रयुक्त मेमोरी';
  @override String get totalTiles => 'कुल टाइल्स';
}

class Intl {
  static String canonicalizedLocale(String a) => a;
}
