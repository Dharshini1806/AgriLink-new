import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class UserLocationState {
  final double? latitude;
  final double? longitude;
  final String label;
  final bool isLoading;

  UserLocationState({
    this.latitude,
    this.longitude,
    this.label = 'Detecting Location...',
    this.isLoading = false,
  });

  UserLocationState copyWith({
    double? latitude,
    double? longitude,
    String? label,
    bool? isLoading,
  }) =>
      UserLocationState(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        label: label ?? this.label,
        isLoading: isLoading ?? this.isLoading,
      );
}

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  UserLocationNotifier() : super(UserLocationState()) {
    detectLocation();
  }

  Future<void> detectLocation() async {
    state = state.copyWith(isLoading: true, label: 'Locating...');
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 4));
        state = UserLocationState(
          latitude: pos.latitude,
          longitude: pos.longitude,
          label: '📍 GPS Location',
          isLoading: false,
        );
      } else {
        state = UserLocationState(
          label: '📍 Location Denied (Tap to Set)',
          isLoading: false,
        );
      }
    } catch (_) {
      state = UserLocationState(
        label: '📍 Tap to Set Location',
        isLoading: false,
      );
    }
  }

  void setCustomLocation(double lat, double lng) {
    state = UserLocationState(
      latitude: lat,
      longitude: lng,
      label: '📍 Custom (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})',
      isLoading: false,
    );
  }
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  return UserLocationNotifier();
});
