// ignore_for_file: constant_identifier_names

enum Flavor { dev, staging, prod }

class FlavorService {
  static const String SERVER_URL = "http://103.150.190.227:8010/";

  static late FlavorService _instance;

  final Flavor flavor;
  final String name;
  final String apiBaseUrl;

  factory FlavorService({
    required Flavor flavor,
    required String name,
    required String apiBaseUrl,
  }) {
    _instance = FlavorService._internal(flavor, name, apiBaseUrl);
    return _instance;
  }

  FlavorService._internal(this.flavor, this.name, this.apiBaseUrl);

  static FlavorService get instance => _instance;

  static Flavor fromString(String value) {
    switch (value.toLowerCase()) {
      case 'dev':
        return Flavor.dev;
      case 'staging':
        return Flavor.staging;
      case 'prod':
        return Flavor.prod;
      default:
        return Flavor.dev;
    }
  }

  static String getFlavorName(Flavor flavor) {
    return flavor.name.toUpperCase();
  }

  static String getBaseUrl(Flavor flavor) {
    switch (flavor) {
      case Flavor.dev:
        return 'http://10.0.2.2:8000/';
      case Flavor.staging:
        return 'http://103.150.190.227:8010/';
      case Flavor.prod:
        return 'http://103.150.190.227:8010/';
    }
  }

  static bool shouldShowBanner(Flavor flavor) => flavor != Flavor.prod;
}
