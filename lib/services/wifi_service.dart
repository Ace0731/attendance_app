import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiService {
  static final NetworkInfo _info = NetworkInfo();

  /// Get the current connected WiFi SSID
  static Future<String?> getConnectedWifiName() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.wifi) {
      String? wifiName = await _info.getWifiName();
      if (wifiName != null) {
        return wifiName.replaceAll('"', '').trim();
      }
    }
    return null;
  }

  /// Get the current connected WiFi BSSID (router MAC address)
  static Future<String?> getConnectedWifiBSSID() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.wifi) {
      String? bssid = await _info.getWifiBSSID();
      if (bssid != null) {
        return bssid.toUpperCase().trim(); // Normalize format
      }
    }
    return null;
  }
}
