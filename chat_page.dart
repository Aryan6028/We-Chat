import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/constants/firestore_constants.dart';
import 'package:we_chat_app/constants/type_message.dart';
import 'package:we_chat_app/models/message_chat.dart';
import 'package:we_chat_app/pages/login_page.dart';
import 'package:we_chat_app/providers/auth_provider.dart';
import 'package:we_chat_app/providers/chat_provider.dart';
import 'package:we_chat_app/widgets/loading_view.dart';
import 'package:we_chat_app/widgets/chat_app_bar.dart';
import 'package:we_chat_app/widgets/chat_input.dart';
import 'package:we_chat_app/widgets/chat_message_item.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.arguments});
  final ChatPageArguments arguments;
  @override
  ChatPageState createState() => ChatPageState();
}
class ChatPageState extends State<ChatPage> {
  late final String _currentUserId;
  List<QueryDocumentSnapshot> _listMessage = [];
  int _limit = 20;
  final int _limitIncrement = 20;
  String _groupChatId = "";

  File? _imageFile;
  bool _isLoading = false;
  bool _isShowSticker = false;
  String _imageUrl = "";

  final _chatInputController = TextEditingController();
  final _listScrollController = ScrollController();
  final _focusNode = FocusNode();

  final Set<String> _selectedMessageIds = <String>{};
  bool _selectionMode = false;

  ChatProvider get _chatProvider => context.read<ChatProvider>();
  AuthProvider get _authProvider => context.read<AuthProvider>();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _listScrollController.addListener(_scrollListener);
    _readLocal();
  }
  void _scrollListener() {
    if (!_listScrollController.hasClients) return;
    if (_listScrollController.offset >=
            _listScrollController.position.maxScrollExtent &&
        !_listScrollController.position.outOfRange &&
        _limit <= _listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _isShowSticker = false;
      });
    }
  }
  void _readLocal() {
    if (_authProvider.userFirebaseId?.isNotEmpty == true) {
      _currentUserId = _authProvider.userFirebaseId!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (_) => false,
      );
    }
    final String peerId = widget.arguments.peerId;
    if (_currentUserId.compareTo(peerId) > 0) {
      _groupChatId = '$_currentUserId-$peerId';
    } else {
      _groupChatId = '$peerId-$_currentUserId';
    }
    _chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      _currentUserId,
      {FirestoreConstants.chattingWith: peerId},
    );
  }
  Future<bool> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedXFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
          Fluttertoast.showToast(msg: err.toString());
          return null;
        });
    if (pickedXFile != null) {
      final imageFile = File(pickedXFile.path);
      setState(() {
        _imageFile = imageFile;
        _isLoading = true;
      });
      return true;
    }
    return false;
  }
  void _getSticker() {
    _focusNode.unfocus();
    setState(() {
      _isShowSticker = !_isShowSticker;
    });
  }
  Future<void> _uploadFile() async {
    if (_imageFile == null) return;
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final uploadTask = _chatProvider.uploadFile(_imageFile!, fileName);
    try {
      final snapshot = await uploadTask;
      _imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _isLoading = false;
      });
      _onSendMessage(_imageUrl, TypeMessage.image);
    } on FirebaseException catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }
  void _onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      _chatInputController.clear();
      _chatProvider.sendMessage(
        content,
        type,
        _groupChatId,
        _currentUserId,
        widget.arguments.peerId,
      );
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Nothing to send',
        backgroundColor: ColorConstants.greyColor,
      );
    }
  }
  Future<void> _addSampleChatData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _chatProvider.addSampleChatData(
        _currentUserId,
        widget.arguments.peerId,
      );
      Fluttertoast.showToast(
        msg: "Sample chat data added successfully!",
        backgroundColor: ColorConstants.greyColor,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error adding sample data: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _onBackPress() {
    _chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      _currentUserId,
      {FirestoreConstants.chattingWith: null},
    );
    Navigator.pop(context);
  }
  Widget _buildStickers() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ColorConstants.greyColor2, width: 0.5),
        ),
        color: Colors.white,
      ),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildItemSticker("mimi1"),
              _buildItemSticker("mimi2"),
              _buildItemSticker("mimi3"),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildItemSticker("mimi4"),
              _buildItemSticker("mimi5"),
              _buildItemSticker("mimi6"),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildItemSticker("mimi7"),
              _buildItemSticker("mimi8"),
              _buildItemSticker("mimi9"),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildItemSticker(String name) {
    return TextButton(
      onPressed: () => _onSendMessage(name, TypeMessage.sticker),
      child: Image.asset(
        'images/$name.gif',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }
  Widget _buildListMessage() {
    return Flexible(
      child: _groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: _chatProvider.getChatStream(_groupChatId, _limit),
              builder: (_, snapshot) {
                if (snapshot.hasData) {
                  _listMessage = snapshot.data!.docs;
                  if (_listMessage.isNotEmpty) {
                    return ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemBuilder: (_, index) {
                        final doc = snapshot.data!.docs[index];
                        final msg = MessageChat.fromDocument(doc);
                        final id = doc.id;
                        return ChatMessageItem(
                          message: msg,
                          messageId: id,
                          currentUserId: _currentUserId,
                          peerAvatar: widget.arguments.peerAvatar,
                          index: index,
                          isSelected: _selectedMessageIds.contains(id),
                          onLongPress: () {
                            setState(() {
                              _selectionMode = true;
                              if (_selectedMessageIds.contains(id)) {
                                _selectedMessageIds.remove(id);
                                if (_selectedMessageIds.isEmpty)
                                  _selectionMode = false;
                              } else {
                                _selectedMessageIds.add(id);
                              }
                            });
                          },
                          onTapIfSelecting: () {
                            if (_selectionMode) {
                              setState(() {
                                if (_selectedMessageIds.contains(id)) {
                                  _selectedMessageIds.remove(id);
                                  if (_selectedMessageIds.isEmpty)
                                    _selectionMode = false;
                                } else {
                                  _selectedMessageIds.add(id);
                                }
                              });
                            }
                          },
                        );
                      },
                      itemCount: snapshot.data!.docs.length,
                      reverse: true,
                      controller: _listScrollController,
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                ColorConstants.gradientStart.withOpacity(0.1),
                                ColorConstants.gradientEnd.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: ColorConstants.gradientStart,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "No message here yet...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorConstants.gradientStart,
                                ColorConstants.gradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.gradientStart.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _addSampleChatData,
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Add Sample Messages",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(
                    color: ColorConstants.gradientStart,
                  ),
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(
                color: ColorConstants.gradientStart,
              ),
            ),
    );
  }
  @override
  void dispose() {
    _chatInputController.dispose();
    _listScrollController
      ..removeListener(_scrollListener)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, ColorConstants.chatBackground],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ChatAppBar(
                title: widget.arguments.peerNickname,
                selectionMode: _selectionMode,
                selectedCount: _selectedMessageIds.length,
                onBack: _onBackPress,
                onCancelSelection: () {
                  setState(() {
                    _selectedMessageIds.clear();
                    _selectionMode = false;
                  });
                },
                onDeleteSelected: () async {
                  if (_selectedMessageIds.isEmpty) return;
                  final should = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete messages'),
                      content: Text(
                        'Delete ${_selectedMessageIds.length} selected message(s)? This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (should == true) {
                    try {
                      setState(() {
                        _isLoading = true;
                      });
                      await _chatProvider.deleteMessages(
                        _groupChatId,
                        _selectedMessageIds.toList(),
                      );
                      Fluttertoast.showToast(msg: 'Selected messages deleted');
                      setState(() {
                        _selectedMessageIds.clear();
                        _selectionMode = false;
                      });
                    } catch (e) {
                      Fluttertoast.showToast(msg: e.toString());
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                onDeleteChat: () async {
                  final should = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete chat'),
                      content: const Text(
                        'Delete all messages in this chat? This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (should == true) {
                    try {
                      await _chatProvider.deleteChatHistory(
                        _currentUserId,
                        widget.arguments.peerId,
                      );
                      Fluttertoast.showToast(msg: 'Chat deleted');
                    } catch (e) {
                      Fluttertoast.showToast(msg: e.toString());
                    }
                  }
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(child: _buildListMessage()),
                        _isShowSticker ? _buildStickers() : SizedBox.shrink(),
                        ChatInput(
                          controller: _chatInputController,
                          focusNode: _focusNode,
                          isLoading: _isLoading,
                          onPickImage: _pickImage,
                          onGetSticker: _getSticker,
                          onUploadFile: _uploadFile,
                          onSend: _onSendMessage,
                        ),
                      ],
                    ),
                    Positioned(
                      child: _isLoading ? LoadingView() : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ChatPageArguments {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  ChatPageArguments({
    required this.peerId,
    required this.peerAvatar,
    required this.peerNickname,
  });
}