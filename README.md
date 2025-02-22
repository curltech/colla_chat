### colla_chat is an open source decentralized, end-to-end encrypted chat software

[![use](https://avatars.githubusercontent.com/u/50282063?s=48&v=4)](https://github.com/flutter-webrtc/flutter-webrtc)
[![use](https://avatars.githubusercontent.com/u/69438833?s=48&v=4)](https://github.com/livekit/client-sdk-flutter)
[![use](https://avatars.githubusercontent.com/u/33363991?s=48&v=4)](https://github.com/MixinNetwork/libsignal_protocol_dart)

# Contents

- [Introduction](#Introduction)
- [Open Source Protocol](#Open Source Protocol)

# Introduction

Colla Chat is an open source decentralized, end-to-end encrypted chat software. During the development process, some additional functions were added for interest.

Chat function
To ensure the security of messages, all messages are encrypted using the end-to-end webrtc protocol. The encryption uses the AES256 symmetric encryption algorithm, and the message transmission uses the ratchet encryption protocol with one session and one key.
Local account, ECC asymmetric cryptographic system generates a local private key, which is encrypted and stored locally. The public key is published to the server, and all messages are encrypted and stored in the sqlite3 database.
Using webrtc technology, decentralized point-to-point and group text, voice and video chat are realized.
Video conferencing function of SFU based on livekit server
Publish and subscribe function of decentralized channels, the content can be rich text, audio and video
Integrated chatgpt Chat with llama's large language model

Since webrtc connections require turn and signal servers for positioning, and video conferencing requires livekit servers, colla_chat needs to be used in conjunction with go-colla-node servers
go-colla-node (https://github.com/curltech/go-colla-node)

It is a decentralized server with blockchain functions developed in go language, which implements webrtc's turn and signal servers, and can connect to and manage livekit servers to create video conferencing rooms

Additional functions
Encrypted emails can use existing email systems, such as 163 or google mail performs end-to-end encrypted transmission of email content, so that the mail server stores encrypted emails to ensure secure email transmission
Multimedia processing, audio and video players, audio recording, and image and video processing based on ffmpeg
Games, 18m Mahjong, similar to Guangdong Mahjong, is a game made from the Mahjong that I often play with my colleagues. It is a pure game that supports single-player and multiplayer games. It is based on the existing decentralized messaging function, so there is no need for a game server
Metamodeling, graphical modeling function, by establishing your own metamodel, you can realize your own customized graphical modeling tool. When customizing your own metamodel Nodes can be customized images or graphics. As a demonstration, it comes with three meta models. Class modeler, similar to UML class modeler, supports class attributes, methods and multiple relationships. Process modeler, draws flow charts. Product modeler, draws models of financial products. Its idea comes from IAA's PSD, and can be used with the product factory function of go-colla-biz to customize bank or insurance products. Data source, manages sqlite3 and postgresql data sources, including table, field and index management, data query and modification, and executes sql statements. File system, manages the terminal's file system, similar to m acos finder and windows explorer
Stocks, with the support of go-colla-stock (https://github.com/curltech/go-colla-stock) server, you can analyze and screen Chinese A shares in real time
Poetry, with the support of go-colla-stock (https://github.com/curltech/go-colla-stock) server, you can query 800,000 ancient Chinese poems in real time

Safety considerations

Installation and deployment
colla_chat supports Android, IOS, Windows, Linux and MacOS platforms. You can download the colla_chat release version for various platforms at the website http://43.135.164.104/index.html
For testing purposes, colla_chat has a built-in connection to the go-colla-node server and can be used directly

If you want to deploy it yourself, you need to deploy your own go-colla-node server and livekit server, and then set your own positioning server address in the advanced settings

Development environment
Android Studio or Intelli IDEA CE
Windows platform, requires Visual studio2002
MacOS platform, requires xcode

For detailed configuration, see the flutter installation document

# Open Source Agreement

Copyright 2020-2025 CURL TECH PTE. LTD.

Licensed under the AGPLv3: https://www.gnu.org/licenses/agpl-3.0.html