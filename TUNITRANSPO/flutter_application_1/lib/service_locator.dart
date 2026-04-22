import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'services/bus_service_repository.dart';
import 'services/settings_service.dart';
import 'services/station_repository.dart';

final GetIt sl = GetIt.instance;

/// Registers all app-wide singletons.
/// Call once in main() before runApp().
void setupServiceLocator({
  FirebaseFirestore? firestore,
  SettingsService? settingsService,
}) {
  sl.registerLazySingleton<FirebaseFirestore>(
    () => firestore ?? FirebaseFirestore.instance,
  );
  sl.registerLazySingleton<BusServiceRepository>(
    () => BusServiceRepository(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<StationRepository>(
    () => StationRepository(sl<FirebaseFirestore>()),
  );
  if (settingsService != null) {
    sl.registerSingleton<SettingsService>(settingsService);
  }
}
