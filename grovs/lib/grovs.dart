
import 'grovs_platform_interface.dart';

class Grovs {
  Future<String?> getPlatformVersion() {
    return GrovsPlatform.instance.getPlatformVersion();
  }
}
