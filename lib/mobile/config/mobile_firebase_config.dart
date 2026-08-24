// Configuración Firebase compilada en la variante móvil.
import 'package:firebase_core/firebase_core.dart';

import '../../config/app_config.dart';

class MobileFirebaseConfig {
  MobileFirebaseConfig._();

  static bool get isConfigured => AppConfig.firebaseConfigured;

  static FirebaseOptions get options => const FirebaseOptions(
    apiKey: AppConfig.firebaseApiKey,
    appId: AppConfig.firebaseAppId,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
  );
}
