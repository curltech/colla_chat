import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../entity/chat/chat.dart';
import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../provider/chat_messages_provider.dart';
import '../../../service/chat/chat.dart';

/// 消息增加组件组件，模拟发送和接受消息，方便测试，一个card下的录入框和按钮组合
class ChatMessageAddWidget extends StatefulWidget {
  const ChatMessageAddWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatMessageAddWidgetState();
}

class _ChatMessageAddWidgetState extends State<ChatMessageAddWidget> {
  final _formKey = GlobalKey<FormState>();
  String _messageId = '';
  String _targetPeerId = '';
  String _targetName = '';
  String _title = '';
  String _content = '';

  @override
  Widget build(BuildContext context) {
    Provider.of<ChatMessagesProvider>(context).chatMessages;
    // TextEditingController messageIdController = TextEditingController();
    // messageIdController.addListener(() {
    //   setState(() {
    //     _messageId = messageIdController.text;
    //   });
    // });
    // TextEditingController targetPeerIdController = TextEditingController();
    // targetPeerIdController.addListener(() {
    //   setState(() {
    //     _targetPeerId = targetPeerIdController.text;
    //   });
    // });
    // TextEditingController targetNameController = TextEditingController();
    // targetNameController.addListener(() {
    //   setState(() {
    //     _targetName = targetNameController.text;
    //   });
    // });
    // TextEditingController titleController = TextEditingController();
    // titleController.addListener(() {
    //   setState(() {
    //     _title = titleController.text;
    //   });
    // });
    // TextEditingController contentController = TextEditingController();
    // contentController.addListener(() {
    //   setState(() {
    //     _content = contentController.text;
    //   });
    // });
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('messageId'),
                  prefixIcon: Icon(Icons.message),
                ),
                initialValue: _messageId,
                onChanged: (String val) {
                  setState(() {
                    _messageId = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: loginNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('targetPeerId'),
                  prefixIcon: Icon(Icons.person),
                ),
                initialValue: _targetPeerId,
                onChanged: (String val) {
                  setState(() {
                    _targetPeerId = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('targetName'),
                  prefixIcon: Icon(Icons.person),
                ),
                initialValue: _targetName,
                onChanged: (String val) {
                  setState(() {
                    _targetName = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('title'),
                  prefixIcon: Icon(Icons.title),
                ),
                initialValue: _title,
                onChanged: (String val) {
                  setState(() {
                    _title = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('content'),
                  prefixIcon: Icon(Icons.content_copy),
                ),
                initialValue: _content,
                onChanged: (String val) {
                  setState(() {
                    _content = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(children: [
              TextButton(
                child: Text(AppLocalizations.t('Add')),
                onPressed: () async {
                  await _add();
                },
              ),
              TextButton(
                child: Text(AppLocalizations.t('Reset')),
                onPressed: () async {},
              )
            ]),
          )
        ],
      ),
    );
  }

  Future<void> _add() async {
    if (_targetName != '') {
      var chatMessage = ChatMessage();
      chatMessage.ownerPeerId = myself.peerId;
      chatMessage.messageId = _messageId;
      chatMessage.targetPeerId = _targetPeerId;
      chatMessage.targetName = _targetName;
      chatMessage.title = _title;
      chatMessage.content = _content;
      ChatMessageService.instance.insert(chatMessage).then((value) {
        Provider.of<ChatMessagesProvider>(context, listen: false)
            .add([chatMessage]);
      });
    } else {
      logger.e('name is null');
    }
  }
}
