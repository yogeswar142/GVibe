import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active tab index for HomeScreen IndexedStack.
/// 0: Feed, 1: Discover, 2: Messages, 3: Profile, 4: 3D Globe
final homeNavIndexProvider = StateProvider<int>((ref) => 0);
