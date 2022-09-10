import 'package:colla_chat/pages/chat/chat/widget/ui.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/common/image_widget.dart';
import 'contact_view.dart';

typedef OnAdd = void Function(String v);
typedef OnCancel = void Function(String v);

///联系人列表项
class ContactItem extends StatefulWidget {
  final String avatar;
  final String title;
  final String identifier;
  final String groupTitle;
  final bool isLine;
  final ClickType type;
  final OnAdd add;
  final OnCancel cancel;

  ContactItem({
    required this.avatar,
    required this.title,
    required this.identifier,
    this.isLine = true,
    required this.groupTitle,
    this.type = ClickType.open,
    required this.add,
    required this.cancel,
  });

  ContactItemState createState() => ContactItemState();
}

class ContactItemState extends State<ContactItem> {
  // ‘添加好友’ 横纵间距
  static const double MARGIN_VERTICAL = 6.0;
  static const double MARGIN_HORIZONTAL = 16.0;

  // ‘ABC...’ 高度
  static const double GROUP_TITLE_HEIGHT = 34.0;

  // items的高度 纵向高度*2+头像高度+分割线高度
  static double heightItem(bool hasGroupTitle) {
    final _buttonHeight = MARGIN_VERTICAL * 2 + 32 + 1.0;
    if (hasGroupTitle) return _buttonHeight + GROUP_TITLE_HEIGHT;

    return _buttonHeight;
  }

  bool isSelect = false;

  //Map<String, dynamic> mapData;

  bool isLine() {
    if (widget.isLine) {
      if (widget.title != '公众号') {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 定义左边图标Widget
    Widget _avatarIcon = ImageWidget(
      image: widget.avatar,
      width: 32,
      height: 32,
      fit: BoxFit.cover,
    );

    /// 头像圆角
    _avatarIcon = _avatarIcon;

    var content = [
      _avatarIcon,

      ///  头像离名字的距离
      Space(width: 15.0),
      Expanded(
        child: Container(
          padding: const EdgeInsets.only(right: MARGIN_HORIZONTAL),
          height: heightItem(false),

          /// 名字的显示位置
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: !isLine()
                ? null
                : Border(
                    bottom: BorderSide(

                        /// 下划线粗细及颜色
                        width: 1,
                        color: Colors.cyan),
                  ),
          ),

          /// 姓名
          child: Text(widget.title,
              style: TextStyle(fontWeight: FontWeight.w400), maxLines: 1),
        ),
      ),
      widget.type == ClickType.select
          ? InkWell(
              child: Image.asset(
                'assets/images/login/${isSelect ? 'ic_select_have.webp' : 'ic_select_no.png'}',
                width: 25.0,
                height: 25.0,
                fit: BoxFit.cover,
              ),
              onTap: () {
                setState(() => isSelect = !isSelect);
                if (isSelect) widget.add(widget.identifier);
                if (!isSelect) widget.cancel(widget.identifier);
              },
            )
          : Container()
    ];

    /// 列表项主体部分
    Widget button = TextButton(
      onPressed: () {
        if (widget.type == ClickType.select) {
          setState(() => isSelect = !isSelect);
          if (isSelect) widget.add(widget.identifier);
          if (!isSelect) widget.cancel(widget.identifier);
          return;
        }
        if (widget.title == '新的朋友') {
          //routePush(NewFriendPage());
        } else if (widget.title == '群聊') {
          //routePush(GroupListPage());
        } else if (widget.title == '标签') {
          //routePush(AllLabelPage());
        } else if (widget.title == '公众号') {
          //routePush(PublicPage());
        } else {
          // routePush(ContactsDetailsPage(
          //     id: widget.identifier,
          //     avatar: widget.avatar,
          //     title: widget.title));
        }
      },
      child: Row(children: content),
    );

    /// 定义分组标签（左边的ABC...）
    Widget itemBody;
    if (widget.groupTitle != null) {
      itemBody = Column(
        children: <Widget>[
          Container(
              height: GROUP_TITLE_HEIGHT,
              padding: EdgeInsets.only(left: 16.0, right: 16.0),
              decoration: BoxDecoration(
                color: Colors.cyan,
                border: Border(
                  top: BorderSide(color: Colors.cyan, width: 0.2),
                  bottom: BorderSide(color: Colors.cyan, width: 0.2),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(widget.groupTitle)),
          button,
        ],
      );
    } else {
      itemBody = button;
    }

    return itemBody;
  }
}
