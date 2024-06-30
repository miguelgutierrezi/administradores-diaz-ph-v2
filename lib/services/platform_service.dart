import 'dart:io' show Platform;

class PlatformService {
  static bool isWeb() => identical(0, 0.0);

  static bool isMobile() => !isWeb();
}
