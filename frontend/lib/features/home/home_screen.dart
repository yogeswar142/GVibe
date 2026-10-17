import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import 'tabs/home_feed_tab.dart';
import '../discovery/discovery_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/socket_service.dart';

import '../globe/presentation/globe_screen.dart';
import '../../core/providers/navigation_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      // Socket connection is normally established in auth_service.saveUser().
      // This call is a safe fallback for cold-start (app killed and reopened
      // while already logged in, bypassing the login screen).
      SocketService.instance.connect(token);
    }
  }

  final List<Widget> _tabs = const [
    HomeFeedTab(),
    DiscoveryScreen(),
    MessagesScreen(),
    ProfileScreen(),
    GlobeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeNavIndexProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: GVibeNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
