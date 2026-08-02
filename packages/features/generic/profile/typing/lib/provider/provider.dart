import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/i_profile_service.dart';

/// Profile contract provider; the module overrides it.
final Provider<IProfileService> profileServiceProvider =
    Provider<IProfileService>(
      (Ref ref) => throw UnimplementedError('profileServiceProvider'),
    );
