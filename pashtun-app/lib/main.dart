import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app.dart';
import 'core/constants/api_constants.dart';
import 'features/checkout/services/stripe_service.dart';
import 'features/wishlist/providers/wishlist_provider.dart';

// Global navigator key for FCM deep linking
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await initWishlistBox();

  // Initialize Firebase
  // NOTE: Requires google-services.json (Android) and GoogleService-Info.plist (iOS)
  // from a NEW Firebase project called 'pashtun-collections'
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // uncomment after running flutterfire configure
  );

  // Initialize Stripe
  StripeService.init();

  runApp(
    const ProviderScope(
      child: PashtunCollectionsApp(),
    ),
  );
}
