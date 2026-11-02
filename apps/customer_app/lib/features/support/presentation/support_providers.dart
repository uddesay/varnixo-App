import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/support_repository.dart';

final Provider<SupportRepository> supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(apiClientProvider)),
);
