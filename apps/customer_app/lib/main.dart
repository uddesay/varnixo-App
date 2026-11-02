import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env is optional for CI/dev without secrets configured — Env (see
    // core/config/env.dart) falls back to sane defaults when a key is
    // missing, so a missing file should never crash startup.
  }

  // A standalone container lets us await the persisted theme preference
  // before the first frame, avoiding a light->dark flash on launch.
  final ProviderContainer container = ProviderContainer();
  await container.read(themeModeProvider.notifier).bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VarnixoApp(),
    ),
  );
}
