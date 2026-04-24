import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_chat_app/constants/app_constants.dart';
import 'package:we_chat_app/constants/firestore_constants.dart';
import 'package:we_chat_app/models/user_chat.dart';
import 'package:we_chat_app/pages/chat_page.dart';
import 'package:we_chat_app/pages/login_page.dart';
import 'package:we_chat_app/pages/story_page.dart';
import 'package:we_chat_app/providers/auth_provider.dart';
import 'package:we_chat_app/providers/chat_provider.dart';
import 'package:we_chat_app/providers/setting_provider.dart';
import 'package:we_chat_app/utils/debouncer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:we_chat_app/widgets/app_drawer.dart';
import 'package:we_chat_app/widgets/search_bar.dart';
import 'package:we_chat_app/widgets/story_section.dart';
import 'package:we_chat_app/widgets/loading_view.dart';
import 'package:we_chat_app/widgets/users_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _listScrollController = ScrollController();
  final _searchDebouncer = Debouncer(milliseconds: 300);
  final _btnClearController = StreamController<bool>();
  final _searchBarController = TextEditingController();

  int _limit = 20;
  final int _limitIncrement = 20;
  String _textSearch = '';
  bool _isLoading = false;
  String _currentUserId = '';

  AuthProvider get _authProvider => context.read<AuthProvider>();
  SettingProvider get _settingProvider => context.read<SettingProvider>();

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_currentUserId.isEmpty) {
      final userId = _authProvider.userFirebaseId;

      if (userId != null && userId.isNotEmpty) {
        _currentUserId = userId;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        });
      }
    }
  }

  void _scrollListener() {
    if (_listScrollController.offset >=
            _listScrollController.position.maxScrollExtent &&
        !_listScrollController.position.outOfRange) {
      setState(() => _limit += _limitIncrement);
    }
  }

  // 🔥 BEAUTIFUL USER CARD
  Widget _buildItem(dynamic document) {
    final userChat = UserChat.fromDocument(document);

    if (_currentUserId.isEmpty || userChat.id == _currentUserId) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff667eea), Color(0xff764ba2)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 25,
            backgroundImage: userChat.photoUrl.isNotEmpty
                ? NetworkImage(userChat.photoUrl)
                : null,
            child: userChat.photoUrl.isEmpty
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
        ),
        title: Text(
          userChat.nickname,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          userChat.aboutMe.isNotEmpty
              ? userChat.aboutMe
              : "Available to chat",
          style: const TextStyle(color: Colors.white70),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                arguments: ChatPageArguments(
                  peerId: userChat.id,
                  peerAvatar: userChat.photoUrl,
                  peerNickname: userChat.nickname,
                ),
              ),
            ),
          );
        },
        trailing: PopupMenuButton<String>(
          color: Colors.white,
          onSelected: (value) async {
            if (value == 'sample') {
              await context.read<ChatProvider>().addSampleChatData(
                    _currentUserId,
                    userChat.id,
                  );
              Fluttertoast.showToast(msg: "Sample chat added");
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'sample',
              child: Text('Add sample chat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userNickname =
        _settingProvider.getPref(FirestoreConstants.nickname) ?? 'User';
    final userPhotoUrl =
        _settingProvider.getPref(FirestoreConstants.photoUrl) ?? '';
    final userAboutMe =
        _settingProvider.getPref(FirestoreConstants.aboutMe) ??
            'Available to chat';

    return Scaffold(
      drawer: AppDrawer(
        userNickname: userNickname,
        userPhotoUrl: userPhotoUrl,
        userAboutMe: userAboutMe,
        onLogout: () async {
          await _authProvider.handleSignOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        },
      ),

      // 🔥 GRADIENT APPBAR
      appBar: AppBar(
        title: const Text(AppConstants.homeTitle),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff667eea), Color(0xff764ba2)],
            ),
          ),
        ),
        elevation: 0,
      ),

      // 🔥 BODY
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff5f7fa), Color(0xffc3cfe2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            StorySection(
              onNavigateToStory: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoryPage()),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: SearchBarWidget(
                controller: _searchBarController,
                btnClearStream: _btnClearController.stream,
                onChangedDebounced: (value) {
                  _searchDebouncer.run(() {
                    setState(() => _textSearch = value);
                  });
                },
              ),
            ),

            Expanded(
              child: UsersList(
                listScrollController: _listScrollController,
                limit: _limit,
                textSearch: _textSearch,
                buildItem: _buildItem,
              ),
            ),

            if (_isLoading) const LoadingView(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _btnClearController.close();
    _searchBarController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }
}