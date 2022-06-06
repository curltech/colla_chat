import {TypeUtil} from '../../util/util';
import {WebrtcPeer} from '../transport/webrtc-peer';
import {config} from '../conf/conf';
import {SignalAction} from '../chain/action/signal';
import {logService} from '../db/log';
import {LRUCache} from 'js-lru';

/**
 * webrtc的连接池，键值是对方的peerId
 */
export class WebrtcPeerPool {
    public peerId: string;
    public peerPublicKey: string;
    public clientId: string;
    private webrtcPeers = new LRUCache(100);
    private _events: Map<string, any> = new Map<string, any>();
    private _signalAction: SignalAction = null;
    private protocolHandlers = new Map();

    constructor() {
        this.registEvent('signal', this.sendSignal);
        this.registEvent('data', this.receiveData);
    }

    registSignalAction(signalAction: SignalAction) {
        webrtcPeerPool._signalAction = signalAction;
        webrtcPeerPool._signalAction.registReceiver('webrtcPeerPool', webrtcPeerPool.receive);
    }

    registProtocolHandler(protocol: string, receiveHandler: any) {
        this.protocolHandlers.set(protocol, {
            receiveHandler: receiveHandler
        });
    }

    getProtocolHandler(protocol: string): any {
        return this.protocolHandlers.get(protocol);
    }

    /**
     * 获取peerId的webrtc连接，可能是多个
     * 如果不存在，创建一个新的连接，发起连接尝试
     * 否则，根据connected状态判断连接是否已经建立
     * @param peerId
     */
    async get(peerId: string): Promise<WebrtcPeer[]> {
        if (webrtcPeerPool.webrtcPeers.find(peerId)) {
            return webrtcPeerPool.webrtcPeers.get(peerId);
        }

        return null;
    }

    getOne(peerId: string, connectPeerId: string, connectSessionId: string): WebrtcPeer {
        let webrtcPeers: WebrtcPeer[] = webrtcPeerPool.webrtcPeers.get(peerId);
        if (webrtcPeers && webrtcPeers.length > 0) {
            for (let webrtcPeer of webrtcPeers) {
                if (webrtcPeer.connectPeerId === connectPeerId
                    && webrtcPeer.connectSessionId === connectSessionId) {
                    return webrtcPeer;
                }
            }
        }

        return null;
    }

    async create(peerId: string, options: any, router: any): Promise<WebrtcPeer> {
        let webrtcPeers: WebrtcPeer[] = null;
        if (webrtcPeerPool.webrtcPeers.find(peerId)) {
            webrtcPeers = webrtcPeerPool.webrtcPeers.get(peerId);
        }
        let webrtcPeer = new WebrtcPeer(peerId, null, true, options, router);
        if (!webrtcPeers) {
            webrtcPeers = [];
        } else if (webrtcPeers.length > 0) {
            //清除未建立连接的rtcpeer
            for (let i = webrtcPeers.length - 1; i >= 0; i--) {
                webrtcPeers.splice(i, 1);
                await webrtcPeers[i].destroy({});
            }
        }
        webrtcPeers.push(webrtcPeer);
        webrtcPeerPool.webrtcPeers.put(peerId, webrtcPeers);
        return webrtcPeer;
    }

    async remove(peerId: string, clientId: string): Promise<boolean> {
        if (webrtcPeerPool.webrtcPeers.find(peerId)) {
            let webrtcPeers: WebrtcPeer[] = webrtcPeerPool.webrtcPeers.get(peerId);
            if (webrtcPeers && webrtcPeers.length > 0) {
                for (let i = webrtcPeers.length - 1; i >= 0; i--) {
                    let webrtcPeer = webrtcPeers[i];
                    if (!clientId || !webrtcPeer.clientId || clientId === webrtcPeer.clientId) {
                        webrtcPeers.splice(i, 1);
                        await webrtcPeer.destroy({});
                    }
                }
                if (webrtcPeers && webrtcPeers.length === 0) {
                    webrtcPeerPool.webrtcPeers.remove(peerId);
                }
            }
            return true;
        } else {
            return false;
        }
    }

    async removeWebrtcPeer(peerId: string, webrtcPeer: WebrtcPeer): Promise<boolean> {
        if (webrtcPeerPool.webrtcPeers.find(peerId)) {
            let webrtcPeers: WebrtcPeer[] = webrtcPeerPool.webrtcPeers.get(peerId);
            if (webrtcPeers && webrtcPeers.length > 0) {
                let _connected: boolean = false;
                for (let i = webrtcPeers.length - 1; i >= 0; i--) {
                    let _webrtcPeer = webrtcPeers[i];
                    if (_webrtcPeer === webrtcPeer) {
                        console.log('emit removeWebrtcPeer self');
                        webrtcPeers.splice(i, 1);
                        await webrtcPeer.destroy({});
                    } else {
                        console.log('emit do not removeWebrtcPeer,because other');
                        if (_webrtcPeer.connected) {
                            _connected = true;
                            console.log('other && connected');
                        }
                    }
                }
                if (webrtcPeers && webrtcPeers.length === 0) {
                    webrtcPeerPool.webrtcPeers.remove(peerId);
                }
                if (!_connected) {
                    await webrtcPeerPool.emitEvent('close', {source: webrtcPeer});
                }
            }
            return true;
        } else {
            return false;
        }


    }

    /**
     * 获取连接已经建立的连接，可能是多个
     * @param peerId
     */
    getConnected(peerId: string): WebrtcPeer[] {
        let peers: WebrtcPeer[] = [];
        if (webrtcPeerPool.webrtcPeers.find(peerId)) {
            let webrtcPeers: WebrtcPeer[] = webrtcPeerPool.webrtcPeers.get(peerId);
            if (webrtcPeers && webrtcPeers.length > 0) {
                for (let webrtcPeer of webrtcPeers) {
                    if (webrtcPeer.connected === true) {
                        peers.push(webrtcPeer);
                    }
                }
            }
        }
        if (peers.length > 0) {
            return peers;
        }

        return null;
    }

    async clearPeer(peerId: string) {
        if (webrtcPeerPool.webrtcPeers.find(peerId)) {
            let webrtcPeers: WebrtcPeer[] = webrtcPeerPool.webrtcPeers.get(peerId);
            if (webrtcPeers && webrtcPeers.length > 0) {
                for (let webrtcPeer of webrtcPeers) {
                    await webrtcPeerPool.removeWebrtcPeer(peerId, webrtcPeer);
                }
            }
        }
    }

    getAll(): WebrtcPeer[] {
        let webrtcPeers: WebrtcPeer[] = [];
        webrtcPeerPool.webrtcPeers.forEach((key, peers) => {
            for (let peer of peers) {
                webrtcPeers.push(peer);
            }
        });
        return webrtcPeers;
    }

    async clear() {
        let webrtcPeers = this.getAll();
        for (let peer of webrtcPeers) {
            await webrtcPeerPool.removeWebrtcPeer(peer.targetPeerId, peer);
        }
    }

    /**
     * 接收到signal的处理
     * @param peerId
     * @param connectSessionId
     * @param data
     */
    async receive(peerId: string, connectPeerId: string, connectSessionId: string, data: any) {
        let type = data.type;
        if (type) {
            console.info('receive signal type: ' + type + ' from webrtcPeer: ' + peerId);
        }
        let clientId: string;
        if (type === 'offer' || type === 'answer') {
            if (data.extension && data.extension.clientId) {
                clientId = data.extension.clientId;
            }
            if (type === 'offer' && data.extension.force) {
                await webrtcPeerPool.remove(peerId, clientId);
            }

        }
        let router = data.router;
        let webrtcPeer: WebrtcPeer = null;
        // peerId的连接不存在，被动方创建WebrtcPeer，被动创建WebrtcPeer
        if (!webrtcPeerPool.webrtcPeers.find(peerId)) {
            console.info('webrtcPeer:' + peerId + ' not exist, will create receiver');
            let iceServer = null;
            if (data.extension && data.extension.iceServer) {
                iceServer = [];
                for (let iceServerItem of data.extension.iceServer) {
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
            let webrtcPeers: WebrtcPeer[] = [];
            webrtcPeers.push(webrtcPeer);
            webrtcPeerPool.webrtcPeers.put(peerId, webrtcPeers);
        } else {// peerId的连接存在
            let webrtcPeers: WebrtcPeer[] = webrtcPeerPool.webrtcPeers.get(peerId);
            if (webrtcPeers && webrtcPeers.length > 0) {
                let found: boolean = false;
                for (webrtcPeer of webrtcPeers) {
                    // 如果连接没有完成
                    if (!webrtcPeer.connectPeerId) {
                        webrtcPeer.connectPeerId = connectPeerId;
                        webrtcPeer.connectSessionId = connectSessionId;
                        found = true;
                        break;
                    } else if (webrtcPeer.connectPeerId === connectPeerId
                        && webrtcPeer.connectSessionId === connectSessionId) {
                        found = true;
                        break;
                    }
                }
                // 没有匹配的连接被发现，说明有多个客户端实例回应，这时创建新的主动连接请求，尝试建立新的连接
                // if (found === false) {
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


    /**
     * 向peer发送信息，如果是多个，遍历发送
     * @param peerId
     * @param data
     */
    async send(peerId: string, data: string | Uint8Array) {
        let webrtcPeers: WebrtcPeer[] = await this.get(peerId);
        if (webrtcPeers && webrtcPeers.length > 0) {
            let ps = [];
            for (let webrtcPeer of webrtcPeers) {
                let p = webrtcPeer.send(data);
                ps.push(p);
            }
            await Promise.all(ps);
        }
    }

    async receiveData(event: any) {
        let {
            receiveHandler
        } = webrtcPeerPool.getProtocolHandler(config.p2pParams.chainProtocolId);
        if (receiveHandler) {
            let remotePeerId = event.source.targetPeerId;
            /**
             * 调用注册的接收处理器处理接收的原始数据
             */
            let data: Uint8Array = await receiveHandler(event.data, remotePeerId, null);
            /**
             * 如果有返回的响应数据，则发送回去，不可以调用同步的发送方法send
             */
            if (data) {
                webrtcPeerPool.send(remotePeerId, data);
            }
        }
    }

    registEvent(name: string, func: any): boolean {
        if (func && TypeUtil.isFunction(func)) {
            this._events.set(name, func);
            return true;
        }
        return false;
    }

    unregistEvent(name: string) {
        this._events.delete(name);
    }

    async emitEvent(name: string, evt: any): Promise<any> {
        if (this._events.has(name)) {
            let func: any = this._events.get(name);
            if (func && TypeUtil.isFunction(func)) {
                return await func(evt);
            } else {
                console.error('event:' + name + ' is not func');
            }
        }
    }

    async sendSignal(evt: any): Promise<any> {
        try {
            let targetPeerId = evt.source.targetPeerId;
            //console.info('webrtcPeer:' + targetPeerId + ' send signal:' + JSON.stringify(evt.data))
            let result = await webrtcPeerPool._signalAction.signal(null, evt.data, targetPeerId);
            if (result === 'ERROR') {
                console.error('signal err:' + result);
            }
            return result;
        } catch (err) {
            console.error('signal err:' + err);
            await logService.log(err, 'signalError', 'error');
        }
        return null;
    }
}

export let webrtcPeerPool = new WebrtcPeerPool();