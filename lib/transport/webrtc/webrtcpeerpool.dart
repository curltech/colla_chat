

import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/webrtc_peer.dart';
import 'package:cryptography/cryptography.dart';

import '../../p2p/chain/action/signal.dart';
import '../../provider/app_data.dart';

class LruQueue<T>{
    int _maxLength=200;
    final Map<String,T> _elements={};
    //指向比自己新的元素的键值，只有最新的键值例外，指向第二新的键值
    final Map<String,String> _nexts={};
    //最新的元素的键值
    String? _head;
    //最老的元素的键值
    String? _tail;
    LruQueue({int maxLength=200}){
        _maxLength=_maxLength;
    }

    //把key的元素变为最新，当前的最新的变为第二新
    T? use(String key){
        var element=_elements[key];
        if (element==null){
            return null;
        }
        if (key==_tail){
            _tail=_nexts[_tail];
        }
        var head=_head;
        if (head!=null) {
            _nexts[key] = head;
        }
        _head=key;

        return element;
    }

    // 放置新的元素，并成为最新的，如果有溢出元素，则返回溢出的元素
    T? put(String key,T element){
        T? tail;
        _elements[key]=element;
        if (_head==null){
            _head=key;
        }
        if (_tail==null){
            _tail=key;
        }
        if (_elements.length>_maxLength){
            tail=_elements[_tail];
            _elements.remove(_tail);
            _tail=_nexts[_tail];
        }
        use(key);

        return tail;
    }

    //移除元素，并返回
    T? remove(String key){
        T? out=_elements.remove(key);
        if (out!=null){
            if (key==_head){
                var second=_nexts[_head];
                var third=_nexts[second];
                _head=second;
                if (second!=null && third!=null) {
                    _nexts[second] = third;
                }
            }
            if (key==_tail){
                _tail=_nexts[_tail];
            }
        }

        return out;
    }

    get(String key){
        return _elements[key];
    }

    containsKey(String key){
        return _elements.containsKey(key);
    }

    int get length{
        return _elements.length;
    }

    List<T> get all{
        return _elements.values.toList();
    }
}


/// webrtc的连接池，键值是对方的peerId
class WebrtcPeerPool {
    String? peerId;
    SimplePublicKey? peerPublicKey;
    String? clientId;
    LruQueue<List<WebrtcPeer>> webrtcPeers = LruQueue();
    Map<String, dynamic> events  = {};
    late SignalAction _signalAction;
    Map<String,dynamic> protocolHandlers ={};

    WebrtcPeerPool() {
        peerId=myself.peerId;
        clientId=myself.clientId;
        peerPublicKey=myself.peerPublicKey;
        _signalAction = signalAction;
        registEvent('signal', sendSignal);
        registEvent('data', receiveData);
    }

    registerSignalAction(SignalAction signalAction ) {
        _signalAction.registerReceiver('webrtcPeerPool', webrtcPeerPool.receive);
    }

    registerProtocolHandler(String protocol, dynamic receiveHandler) {
        protocolHandlers[protocol]= {
            'receiveHandler': receiveHandler
        };
    }

    dynamic getProtocolHandler(String protocol) {
        return protocolHandlers[protocol];
    }

    /// 获取peerId的webrtc连接，可能是多个
    /// 如果不存在，创建一个新的连接，发起连接尝试
    /// 否则，根据connected状态判断连接是否已经建立
    /// @param peerId
    List<WebrtcPeer>? get(String peerId)  {
        if (webrtcPeers.containsKey(peerId)) {
            return webrtcPeers.use(peerId);
        }

        return null;
    }

    WebrtcPeer? getOne(String peerId, String connectPeerId, String connectSessionId) {
        List<WebrtcPeer>? webrtcPeers= get(peerId);
        if (webrtcPeers!=null && webrtcPeers.isNotEmpty) {
            for (WebrtcPeer webrtcPeer in webrtcPeers) {
                if (webrtcPeer.connectPeerId == connectPeerId
                    && webrtcPeer.connectSessionId == connectSessionId) {
                    return webrtcPeer;
                }
            }
        }

        return null;
    }

    ///主动方创建
    Future<WebrtcPeer> create(String peerId, String clientId,dynamic options, String roomId) async  {
        List<WebrtcPeer>? webrtcPeers=this.webrtcPeers.get(peerId);
        if (webrtcPeers==null) {
            webrtcPeers = [];
        }
        var webrtcPeer = WebrtcPeer(peerId,clientId,  true, options:options, roomId:roomId);
        webrtcPeers.add(webrtcPeer);
        List<WebrtcPeer>? outs=this.webrtcPeers.put(peerId, webrtcPeers);
        if (outs!=null && outs.isNotEmpty){
            for (WebrtcPeer out in outs){
                await out.destroy('over max webrtc peer number, knocked out');
            }
        }
        return webrtcPeer;
    }

    Future<bool> remove(String peerId,{ String? clientId}) async  {
        List<WebrtcPeer>? webrtcPeers=this.webrtcPeers.get(peerId);
        if (webrtcPeers==null) {
            return false;
        }
        if (webrtcPeers.isNotEmpty) {
            for (WebrtcPeer webrtcPeer in webrtcPeers){
                if (clientId==null || webrtcPeer.clientId==null || clientId == webrtcPeer.clientId) {
                    webrtcPeers.remove(webrtcPeer);
                    await webrtcPeer.destroy('remove webrtcPeer');
                }
            }
            if (webrtcPeers.isEmpty) {
                this.webrtcPeers.remove(peerId);
            }

            return true;
        }
        return false;
    }

    Future<bool>  removeWebrtcPeer(String peerId, WebrtcPeer webrtcPeer ) async  {
        List<WebrtcPeer>? webrtcPeers=this.webrtcPeers.get(peerId);
            if (webrtcPeers!=null && webrtcPeers.isNotEmpty) {
                bool _connected=false;
                for (WebrtcPeer _webrtcPeer in webrtcPeers){
                    if (_webrtcPeer == webrtcPeer) {
                        logger.i('emit removeWebrtcPeer self');
                        webrtcPeers.remove(webrtcPeer);
                        await webrtcPeer.destroy('rmoved');
                    } else {
                        logger.i('emit do not removeWebrtcPeer,because other');
                        if (_webrtcPeer.connected) {
                            _connected = true;
                            logger.i('other && connected');
                        }
                    }
                }
                if (webrtcPeers.isEmpty) {
                    webrtcPeerPool.webrtcPeers.remove(peerId);
                }
                if (!_connected) {
                    await webrtcPeerPool.emitEvent('close', {'source': webrtcPeer});
                }

                return true;
        } else {
            return false;
        }
    }

    /// 获取连接已经建立的连接，可能是多个
    /// @param peerId
    List<WebrtcPeer>? getConnected(String peerId) {
        List<WebrtcPeer> peers=[];
        List<WebrtcPeer>? webrtcPeers=this.webrtcPeers.get(peerId);
        if (webrtcPeers!=null && webrtcPeers.isNotEmpty) {
            for (WebrtcPeer webrtcPeer in webrtcPeers){
                    if (webrtcPeer.connected) {
                        peers.add(webrtcPeer);
                    }
                }
            }
        if (peers.isNotEmpty) {
            return peers;
        }

        return null;
    }

    List<WebrtcPeer> getAll() {
        List<WebrtcPeer> webrtcPeers= [];
        for (var peers in this.webrtcPeers.all) {
            for (var peer in peers) {
                webrtcPeers.add(peer);
            }
        }
        return webrtcPeers;
    }

     clear() async{
        var webrtcPeers = getAll();
        for (var peer in webrtcPeers) {
            var peerId=peer.targetPeerId;
            if (peerId!=null) {
                await remove(peerId);
            }
        }
    }

    /// 接收到signal的处理
    /// @param peerId
    /// @param connectSessionId
    /// @param data
     receive(String peerId,String connectPeerId,String connectSessionId, dynamic data) async{
        var type = data.type;
        if (type) {
            console.info('receive signal type: ' + type + ' from webrtcPeer: ' + peerId);
        }
        var clientId: string;
        if (type == 'offer' || type == 'answer') {
            if (data.extension && data.extension.clientId) {
                clientId = data.extension.clientId;
            }
            if (type == 'offer' && data.extension.force) {
                await webrtcPeerPool.remove(peerId, clientId);
            }

        }
        var router = data.router;
        var webrtcPeer: WebrtcPeer = null;
        // peerId的连接不存在，被动方创建WebrtcPeer，被动创建WebrtcPeer
        if (!webrtcPeerPool.webrtcPeers.find(peerId)) {
            console.info('webrtcPeer:' + peerId + ' not exist, will create receiver');
            var iceServer = null;
            if (data.extension && data.extension.iceServer) {
                iceServer = [];
                for (var iceServerItem of data.extension.iceServer) {
                    if (iceServerItem.username) {
                        iceServerItem.username = webrtcPeerPool.peerId;
                        iceServerItem.credential = webrtcPeerPool.peerPublicKey;
                    }
                    iceServer.push(iceServerItem);
                }
                iceServer = data.extension.iceServer;
            }
            webrtcPeer = new WebrtcPeer(peerId, iceServer, false, null, null);
            webrtcPeer.connectPeerId = connectPeerId;
            webrtcPeer.connectSessionId = connectSessionId;
            if (clientId) {
                webrtcPeer.clientId = clientId;
            }
            var webrtcPeers: WebrtcPeer[] = [];
            webrtcPeers.push(webrtcPeer);
            webrtcPeerPool.webrtcPeers.put(peerId, webrtcPeers);
        } else {// peerId的连接存在
            var webrtcPeers: WebrtcPeer[] = webrtcPeerPool.webrtcPeers.get(peerId);
            if (webrtcPeers && webrtcPeers.length > 0) {
                var found: boolean = false;
                for (webrtcPeer of webrtcPeers) {
                    // 如果连接没有完成
                    if (!webrtcPeer.connectPeerId) {
                        webrtcPeer.connectPeerId = connectPeerId;
                        webrtcPeer.connectSessionId = connectSessionId;
                        found = true;
                        break;
                    } else if (webrtcPeer.connectPeerId == connectPeerId
                        && webrtcPeer.connectSessionId == connectSessionId) {
                        found = true;
                        break;
                    }
                }
                // 没有匹配的连接被发现，说明有多个客户端实例回应，这时创建新的主动连接请求，尝试建立新的连接
                // if (found == false) {
                // 	console.info('match webrtcPeer:' + peerId + ' not exist, will create sender')
                // 	webrtcPeer = new WebrtcPeer(peerId, null, true, null, router)
                // 	webrtcPeer.connectPeerId = connectPeerId
                // 	webrtcPeer.connectSessionId = connectSessionId
                // 	webrtcPeers.push(webrtcPeer)
                // 	webrtcPeer = null
                // }
            }
            console.info('webrtcPeer:' + peerId + ' exist, connected:');
            //console.info('webrtcPeer:' + peerId + ' exist, connected:' + webrtcPeer.connected)
        }
        if (webrtcPeer) {
            if (clientId) {
                webrtcPeer.clientId = clientId;
            }
            //console.info('webrtcPeer signal data:' + JSON.stringify(data))
            webrtcPeer.signal(data);
        }
    }


    /// 向peer发送信息，如果是多个，遍历发送
    /// @param peerId
    /// @param data
     send(String peerId, Uint8List data) async{
        var webrtcPeers: WebrtcPeer[] = await this.get(peerId);
        if (webrtcPeers && webrtcPeers.length > 0) {
            var ps = [];
            for (var webrtcPeer of webrtcPeers) {
                var p = webrtcPeer.send(data);
                ps.push(p);
            }
            await Future.all(ps);
        }
    }

     receiveData(dynamic event) async{
        var {
            receiveHandler
        } = webrtcPeerPool.getProtocolHandler(config.p2pParams.chainProtocolId);
        if (receiveHandler) {
            var remotePeerId = event.source.targetPeerId;
            /**
             * 调用注册的接收处理器处理接收的原始数据
             */
            var data: Uint8Array = await receiveHandler(event.data, remotePeerId, null);
            /**
             * 如果有返回的响应数据，则发送回去，不可以调用同步的发送方法send
             */
            if (data) {
                webrtcPeerPool.send(remotePeerId, data);
            }
        }
    }

    bool registEvent(String name, dynamic func) {
        if (func && TypeUtil.isFunction(func)) {
            events.set(name, func);
            return true;
        }
        return false;
    }

    unregistEvent(String name) {
        events.delete(name);
    }

    Future<dynamic> emitEvent(String name, dynamic evt)  async{
        if (events.has(name)) {
            var func: any = events.get(name);
            if (func && TypeUtil.isFunction(func)) {
                return await func(evt);
            } else {
                logger.e('event:' + name + ' is not func');
            }
        }
    }

    Future<dynamic> sendSignal(dynamic evt) async {
        try {
            var targetPeerId = evt.source.targetPeerId;
            //console.info('webrtcPeer:' + targetPeerId + ' send signal:' + JSON.stringify(evt.data))
            var result = await webrtcPeerPool._signalAction.signal(null, evt.data, targetPeerId);
            if (result == 'ERROR') {
                logger.e('signal err:' + result);
            }
            return result;
        } catch (err) {
            logger.e('signal err:' + err);
            await logService.log(err, 'signalError', 'error');
        }
        return null;
    }
}

var webrtcPeerPool = WebrtcPeerPool();