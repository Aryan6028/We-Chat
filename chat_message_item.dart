import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:we_chat_app/constants/color_constants.dart';
import 'package:we_chat_app/constants/type_message.dart';
import 'package:we_chat_app/models/message_chat.dart';
import 'package:we_chat_app/pages/full_photo_page.dart';
import 'package:we_chat_app/providers/chat_provider.dart';

class ChatMessageItem extends StatelessWidget {
  final MessageChat message;
  final String messageId;
  final String currentUserId;
  final String peerAvatar;
  final int index;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onTapIfSelecting;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.messageId,
    required this.currentUserId,
    required this.peerAvatar,
    required this.index,
    required this.isSelected,
    required this.onLongPress,
    required this.onTapIfSelecting,
  });

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();

    Widget bubble;

    if (message.idFrom == currentUserId) {
      // Sent message (right)
      if (message.type == TypeMessage.text) {
        bubble = Container(
          child: Text(
            message.content,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.chatBubbleSent,
                ColorConstants.gradientStart,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.chatBubbleSent.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          margin: EdgeInsets.only(bottom: 10, right: 10),
        );
      } else if (message.type == TypeMessage.image) {
        bubble = Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: GestureDetector(
            child: Image.network(
              message.content,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullPhotoPage(url: message.content),
              ),
            ),
          ),
          margin: EdgeInsets.only(bottom: 10, right: 10),
        );
      } else {
        bubble = Container(
          child: Image.asset(
            'images/${message.content}.gif',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          margin: EdgeInsets.only(bottom: 10, right: 10),
        );
      }

      bubble = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [bubble],
      );
    } else {
      // Received (left)
      final avatar = ClipOval(
        child: Image.network(
          peerAvatar,
          width: 35,
          height: 35,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.account_circle,
            size: 35,
            color: ColorConstants.greyColor,
          ),
        ),
      );

      Widget content;
      if (message.type == TypeMessage.text) {
        content = Container(
          child: Text(
            message.content,
            style: TextStyle(color: Colors.grey[800], fontSize: 15),
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          margin: EdgeInsets.only(left: 10),
        );
      } else if (message.type == TypeMessage.image) {
        content = Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: GestureDetector(
            child: Image.network(
              message.content,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullPhotoPage(url: message.content),
              ),
            ),
          ),
          margin: EdgeInsets.only(left: 10),
        );
      } else {
        content = Container(
          child: Image.asset(
            'images/${message.content}.gif',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          margin: EdgeInsets.only(bottom: 10, right: 10),
        );
      }

      bubble = Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [avatar, content]),
            Container(
              margin: EdgeInsets.only(left: 50, top: 5, bottom: 5),
              child: Text(
                DateFormat('dd MMM kk:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(
                    int.parse(message.timestamp),
                  ),
                ),
                style: TextStyle(
                  color: ColorConstants.greyColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectable = Material(
      color: isSelected ? Colors.blue.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onTapIfSelecting,
        child: bubble,
      ),
    );

    // compute deterministic groupChatId locally
    String groupChatId;
    if (currentUserId.compareTo(message.idTo) > 0) {
      groupChatId = '$currentUserId-${message.idTo}';
    } else {
      groupChatId = '${message.idTo}-$currentUserId';
    }

    return Dismissible(
      key: Key(messageId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final should = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete message'),
            content: const Text('Delete this message? This cannot be undone.'),
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
        return should == true;
      },
      onDismissed: (direction) async {
        try {
          await chatProvider.deleteMessage(groupChatId, messageId);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Message deleted')));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: selectable,
    );
  }
}
