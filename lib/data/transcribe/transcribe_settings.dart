import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUrlKey = 'transcribe_url';
const _kLanUrlKey = 'transcribe_lan_url';
const _kTokenKey = 'transcribe_token';
const _kRouteKey = 'transcribe_route';

/// Defaults point at the Mac over Tailscale; all editable in Settings.
const defaultTranscribeUrl = 'http://100.x.y.z:8765';

/// The LAN default is the Mac's mDNS (Bonjour) hostname rather than a fixed
/// IP: DHCP hands out a new address whenever the router re-leases, which would
/// silently break a hardcoded IP. `.local` follows the Mac automatically.
const defaultTranscribeLanUrl = 'http://your-mac.local:8765';
const defaultTranscribeToken =
    'change-me';

/// Which address to reach the Mac on.
enum TranscribeRoute {
  /// Try the LAN address first (fast, reliable at home), fall back to Tailscale.
  auto,

  /// Always use the LAN address.
  lan,

  /// Always use the Tailscale address.
  tailscale,
}

extension TranscribeRouteLabel on TranscribeRoute {
  String get label => switch (this) {
    TranscribeRoute.auto => 'Auto (LAN, then Tailscale)',
    TranscribeRoute.lan => 'Wi-Fi / LAN only',
    TranscribeRoute.tailscale => 'Tailscale only',
  };
}

class TranscribeSettings {
  /// Tailscale address — works anywhere the tailnet is up.
  final String url;

  /// Local-network address — fastest at home, useless away from it.
  final String lanUrl;
  final String token;
  final TranscribeRoute route;

  const TranscribeSettings({
    required this.url,
    required this.lanUrl,
    required this.token,
    required this.route,
  });

  /// Addresses to try, in order, for the configured route.
  List<String> get candidates => switch (route) {
    TranscribeRoute.auto => [
      if (lanUrl.trim().isNotEmpty) lanUrl,
      if (url.trim().isNotEmpty) url,
    ],
    TranscribeRoute.lan => [if (lanUrl.trim().isNotEmpty) lanUrl],
    TranscribeRoute.tailscale => [if (url.trim().isNotEmpty) url],
  };

  /// Human label for an address, for status display.
  String labelFor(String candidate) {
    if (candidate == lanUrl) return 'Wi-Fi / LAN';
    if (candidate == url) return 'Tailscale';
    return candidate;
  }

  TranscribeSettings copyWith({
    String? url,
    String? lanUrl,
    String? token,
    TranscribeRoute? route,
  }) => TranscribeSettings(
    url: url ?? this.url,
    lanUrl: lanUrl ?? this.lanUrl,
    token: token ?? this.token,
    route: route ?? this.route,
  );
}

class TranscribeSettingsController extends AsyncNotifier<TranscribeSettings> {
  static const _fallback = TranscribeSettings(
    url: defaultTranscribeUrl,
    lanUrl: defaultTranscribeLanUrl,
    token: defaultTranscribeToken,
    route: TranscribeRoute.auto,
  );

  /// Fixed-IP LAN defaults shipped before the mDNS switch; they break as soon
  /// as DHCP re-leases, so migrate anyone still carrying one.
  static const _staleLanDefaults = {'http://192.168.1.100:8765'};

  @override
  Future<TranscribeSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final routeName = prefs.getString(_kRouteKey);
    final storedLan = prefs.getString(_kLanUrlKey);
    if (storedLan != null && _staleLanDefaults.contains(storedLan.trim())) {
      await prefs.remove(_kLanUrlKey);
    }
    return TranscribeSettings(
      url: prefs.getString(_kUrlKey) ?? defaultTranscribeUrl,
      lanUrl:
          (storedLan != null && !_staleLanDefaults.contains(storedLan.trim()))
          ? storedLan
          : defaultTranscribeLanUrl,
      token: prefs.getString(_kTokenKey) ?? defaultTranscribeToken,
      route: TranscribeRoute.values.firstWhere(
        (r) => r.name == routeName,
        orElse: () => TranscribeRoute.auto,
      ),
    );
  }

  Future<void> setUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUrlKey, url);
    state = AsyncData((state.value ?? _fallback).copyWith(url: url));
  }

  Future<void> setLanUrl(String lanUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanUrlKey, lanUrl);
    state = AsyncData((state.value ?? _fallback).copyWith(lanUrl: lanUrl));
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    state = AsyncData((state.value ?? _fallback).copyWith(token: token));
  }

  Future<void> setRoute(TranscribeRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRouteKey, route.name);
    state = AsyncData((state.value ?? _fallback).copyWith(route: route));
  }
}
