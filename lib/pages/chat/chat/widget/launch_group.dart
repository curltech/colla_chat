import 'package:colla_chat/provider/app_data.dart';
import 'package:flutter/material.dart';

import '../../../../tool/util.dart';

class LaunchGroupItem extends StatelessWidget {
  final item;

  LaunchGroupItem(this.item);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 0.3),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: FlatButton(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 15.0),
        onPressed: () {
          if (item == '选择一个群') {
            //routePush(GroupSelectPage());
          } else {
            DialogUtil.showToast('敬请期待');
          }
        },
        child: Container(
          width: appDataProvider.size.width, //appDataProvider.size.width,
          padding: EdgeInsets.only(left: 20.0),
          child: Text(item),
        ),
      ),
    );
  }
}

class LaunchSearch extends StatelessWidget {
  final FocusNode? searchF;
  final TextEditingController searchC;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final GestureTapCallback delOnTap;

  LaunchSearch({
    this.searchF,
    required this.searchC,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    required this.delOnTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 10.0),
          child: Image.asset('assets/images/search_black.webp',
              color: Colors.black),
        ),
        Expanded(
          child: TextField(
            focusNode: searchF,
            controller: searchC,
            style: TextStyle(textBaseline: TextBaseline.alphabetic),
            decoration: InputDecoration(
              hintText: '搜索',
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
            onTap: onTap ?? () {},
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
          ),
        ),
        StringUtil.isNotEmpty(searchC.text)
            ? InkWell(
                child: Image.asset('assets/images/ic_delete.webp'),
                onTap: () {
                  searchC.text = '';
                  delOnTap();
                },
              )
            : Container()
      ],
    );
  }
}
