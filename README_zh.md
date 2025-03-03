### colla_chat是一个开源的去中心化的，端到端加密聊天软件

[![use](https://avatars.githubusercontent.com/u/50282063?s=48&v=4)](https://github.com/flutter-webrtc/flutter-webrtc)
[![use](https://avatars.githubusercontent.com/u/69438833?s=48&v=4)](https://github.com/livekit/client-sdk-flutter)
[![use](https://avatars.githubusercontent.com/u/33363991?s=48&v=4)](https://github.com/MixinNetwork/libsignal_protocol_dart)

# 目录

- [介绍](#介绍)
- [开源协议](#开源协议)

# 介绍

Colla Chat是一个开源的去中心化的，端到端加密聊天软件。在开发的过程中出于兴趣的原因，增加了一些附属的功能

聊天功能
为保证消息的安全性，所有的消息都是采用端到端webrtc协议且加密传输，加密采用AES256对称加密算法，消息传输采用一会话一密钥的棘轮加密协议
本地帐号，ECC的非对称密码体系生成本地的私钥，私钥通过密码加密存放在本地，公钥发布到服务器，所有的消息以加密方式存放在sqlite3的数据库中
采用webrtc技术，实现了去中心化的点对点和群的文本，语音和视频聊天
基于livekit服务器的SFU的视频会议的功能
去中心化的频道的发布订阅功能，内容可以是包含富文本，音频和视频
集成chatgpt和llama的大语言模型聊天

由于webrtc的连接需要turn和signal服务器进行定位，同时视频会议需要livekit服务器，因此colla_chat需要结合go-colla-node服务器进行使用
go-colla-node(https://github.com/curltech/go-colla-node)
是一个go语言开发的去中心化，带有区块链功能的服务器，实现了webrtc的turn和signal服务器，同时能够连接管理livekit服务器，从而创建视频会议的房间

附属功能
加密邮件，能够利用现有的邮件系统，比如163或者google mail对邮件内容进行端对端的加密传输，这样邮件服务器存放的是加密过的邮件，保证安全的邮件传输
多媒体处理，音频和视频播放器，音频录音，以及基于ffmpeg的图片和视频处理
游戏，18m麻将，类似广东麻将，是自己平常和同事们经常完的麻将做成了一个游戏，纯属游戏之作，支持单人和多人游戏，基于现成的去中心化的消息传送功能，因此不需要游戏服务器
元建模，图形化的建模功能，通过建立自己的元模型，从而实现自己定制化的图形化建模工具，在定制自己的元模型的时候，节点可以是定制化的图像或者图形，作为演示，自带三个元模型
类建模器，类似UML的类建模器，支持类的属性，方法和多种关联关系
流程建模器，绘制流程图
产品建模器，绘制金融产品的模型，其思想来源于IAA的PSD，而且可以配合go-colla-biz的产品工厂的功能实现银行或者保险产品的定制化
数据源，管理sqlite3和postgresql数据源，包括表，字段和索引的管理以及数据的查询和修改，执行sql语句
文件系统，管理终端的文件系统，类似macos的finder和windows的explorer
股票，在go-colla-stock(https://github.com/curltech/go-colla-stock)服务器的支持下，可以实时对中国A股进行分析和筛选
诗词，在go-colla-stock(https://github.com/curltech/go-colla-stock)服务器的支持下，可以实时查询80万首中国古代诗词

安全考虑

安装和部署
colla_chat支持Android，IOS，Windows，Linux和MacOS平台，在网站http:
//43.135.164.104/index.html，你可以下载各种平台的colla_chat发布版本
作为测试用途，colla_chat内置连接了go-colla-node服务器，可以直接使用

如果想自己部署，则需要部署自己的go-colla-node服务器和livekit服务器，然后在高级设置中设置自己的定位服务器地址

开发环境
Android Studio或者Intelli IDEA CE
Windows平台，需要Visual studio2002
MacOS平台，需要xcode

详细的配置，参见flutter的安装文档

# 开源协议

Copyright 2020-2025 CURL TECH PTE. LTD.

Licensed under the AGPLv3: https://www.gnu.org/licenses/agpl-3.0.html
