import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  final String appName;
  final String version;
  final String buildNumber;
  final String environment;

  const AppInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.environment,
  });
}

final appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  
  // Assuming `.env` contains an ENVIRONMENT variable or we default to 'Development'
  final env = dotenv.env['ENVIRONMENT'] ?? 'Development';

  return AppInfo(
    appName: packageInfo.appName,
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
    environment: env,
  );
});
