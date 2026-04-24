import 'package:flutter/material.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/pages/ai_chat_page.dart';
import 'package:we_chat_app/pages/settings_page.dart';

class AppDrawer extends StatelessWidget {
  final String userNickname;
  final String userPhotoUrl;
  final String userAboutMe;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.userNickname,
    required this.userPhotoUrl,
    required this.userAboutMe,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [ColorConstants.gradientStart, ColorConstants.gradientEnd])),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 47,
                        backgroundImage: userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
                        child: userPhotoUrl.isEmpty ? Icon(Icons.person, size: 50, color: ColorConstants.gradientStart) : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(userNickname, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(userAboutMe, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Divider(color: Colors.white54, height: 1),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // AI Assistant
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorConstants.gradientBlue,
                                ColorConstants.gradientPurple,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.gradientBlue.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                        ),
                        title: const Text(
                          'AI Assistant',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'ChatGPT/Gemini like AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AiChatPage()),
                          );
                        },
                      ),
                      const Divider(),
                      // Settings
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorConstants.gradientStart,
                                ColorConstants.gradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.settings, color: Colors.white, size: 20),
                        ),
                        title: const Text(
                          'Settings',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsPage()),
                          );
                        },
                      ),
                      const Divider(),
                      // Logout
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorConstants.accentPink,
                                ColorConstants.accentOrange,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.logout, color: Colors.white, size: 20),
                        ),
                        title: const Text(
                          'Log out',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onLogout();
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
