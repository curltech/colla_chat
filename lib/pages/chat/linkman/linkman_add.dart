import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/provider/linkman_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../entity/chat/contact.dart';
import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';

/// 用户注册组件，一个card下的录入框和按钮组合
class LinkmanAddWidget extends StatefulWidget {
  const LinkmanAddWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanAddWidgetState();
}

class _LinkmanAddWidgetState extends State<LinkmanAddWidget> {
  final _formKey = GlobalKey<FormState>();
  String _name = '胡劲松';
  String _peerId = '';
  String _mobile = '';
  String _email = '';
  String _giveName = '';

  @override
  Widget build(BuildContext context) {
    Provider.of<LinkmanProvider>(context).linkmen;
    // TextEditingController nameController = TextEditingController();
    // nameController.addListener(() {
    //   setState(() {
    //     _name = nameController.text;
    //   });
    // });
    // TextEditingController peerIdController = TextEditingController();
    // peerIdController.addListener(() {
    //   setState(() {
    //     _peerId = peerIdController.text;
    //   });
    // });
    // TextEditingController mobileController = TextEditingController();
    // mobileController.addListener(() {
    //   setState(() {
    //     _mobile = mobileController.text;
    //   });
    // });
    // TextEditingController emailController = TextEditingController();
    // emailController.addListener(() {
    //   setState(() {
    //     _email = emailController.text;
    //   });
    // });
    // TextEditingController giveNameController = TextEditingController();
    // giveNameController.addListener(() {
    //   setState(() {
    //     _giveName = giveNameController.text;
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
                  labelText: AppLocalizations.t('name'),
                  prefixIcon: Icon(Icons.person),
                ),
                initialValue: _name,
                onChanged: (String val) {
                  setState(() {
                    _name = val;
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
                  labelText: AppLocalizations.t('giveName'),
                  prefixIcon: Icon(Icons.desktop_mac),
                ),
                initialValue: _giveName,
                onChanged: (String val) {
                  setState(() {
                    _giveName = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('Email'),
                  prefixIcon: Icon(Icons.email),
                ),
                initialValue: _email,
                onChanged: (String val) {
                  setState(() {
                    _email = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                //controller: emailController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('mobile'),
                  prefixIcon: Icon(Icons.mobile_friendly),
                ),
                initialValue: _mobile,
                onChanged: (String val) {
                  setState(() {
                    _mobile = val;
                  });
                },
                onFieldSubmitted: (String val) {},
              )),
          SizedBox(height: 10.0),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                keyboardType: TextInputType.text,
                //controller: passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('peerId'),
                  prefixIcon: Icon(Icons.lock),
                ),
                initialValue: _peerId,
                onChanged: (String val) {
                  setState(() {
                    _peerId = val;
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
    if (_name != '') {
      var keyPair = await cryptoGraphy.generateKeyPair();
      var publicKey = await cryptoGraphy.exportPublicKey(keyPair);
      var linkman = Linkman(myself.peerId!, publicKey, _name);
      linkman.givenName = _giveName;
      linkman.peerId = publicKey;
      linkman.email = _email;
      linkman.mobile = _mobile;
      LinkmanService.instance.insert(linkman).then((value) {
        Provider.of<LinkmanProvider>(context, listen: false).add([linkman]);
      });
    } else {
      logger.e('name is null');
    }
  }
}
