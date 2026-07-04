import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import 'tabs/home_feed_tab.dart';
import '../discovery/discovery_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/encryption_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      SocketService.instance.connect(token);
      // Proactively upload public key to server
      try {
        final myPub = await EncryptionService.instance.getMyPublicKeyBase64();
        await ApiService().dio.put('/messages/keys/public', data: {'x25519': myPub});
        print('🔑 [E2EE] Proactively uploaded public key: $myPub');
      } catch (e) {
        print('🔑 [E2EE Error] Failed to proactively upload public key: $e');
      }
    }
  }

  final List<Widget> _tabs = const [
    HomeFeedTab(),
    DiscoveryScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: GVibeNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
