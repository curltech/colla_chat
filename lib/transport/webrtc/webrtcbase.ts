import { chainMessageHandler } from '../chain/chainmessagehandler'
import { rtcCandidateAction } from '../chain/action/rtccandidate'
import { rtcOfferAction } from '../chain/action/rtcoffer'
import { rtcAnswerAction } from '../chain/action/rtcanswer'
import { myself } from '../dht/myselfpeer'
import Worker from './webrtc.worker'
import { webrtcEncrypt } from './webrtc-encrypt'

const repeatAttemptLimit = 0
const repeatAttemptTimeOut = 60000

/**
 * 本类没有完成，不推荐使用
 * 一个webrtc的连接，包含数据通道，推荐使用webrtc-peer
 */
export class Webrtc {
    private _targetPeerId: string
    private _connectAddress: string
    private _peerConnection: RTCPeerConnection
    private _dataChannel: RTCDataChannel
    private _status: boolean
    private _attemptingTag: boolean = false
    constructor() {
    }

    get peerConnection() {
        return this._peerConnection
    }

    get dataChannel() {
        return this._dataChannel
    }

    get status(): boolean {
        return this._status
    }

    get targetPeerId(): string {
        return this._targetPeerId
    }

    isConnected() {
        return this._peerConnection.connectionState === 'connected'
            && this._dataChannel
            && this._dataChannel.readyState === 'open'
    }

    /**
     * 创建PeerConnection
     * @param targetPeerId 
     * @param connectAddress 
     */
    createPeerConnection(targetPeerId, connectAddress) {
        this._targetPeerId = targetPeerId
        this._connectAddress = connectAddress
        let configuration = {
            "iceServers": [
                {
                    urls: 'stun:' + connectAddress + ':3478'
                },
                {
                    urls: 'turn:' + connectAddress + ':3478',
                    username: 'guest',
                    credential: 'guest'
                }
            ]
        }
        this._peerConnection = new RTCPeerConnection(configuration)
        this._peerConnection.onicecandidate = this.onIceCandidate
        this._peerConnection.onconnectionstatechange = this.onConnectionStateChange
        this._peerConnection.ontrack = this.onTrack
        this._peerConnection.ondatachannel = this.onDataChannel
        this._peerConnection.onicegatheringstatechange = this.onIceGatheringStateChange
        this._peerConnection.onnegotiationneeded = this.onNegotiationNeeded
        this._peerConnection.onsignalingstatechange = this.onSignalingStateChange
    }

    async repeatAttempt(type: string) {
        let _that = this
        if (type !== 'error' || (type === 'error' && this._targetPeerId > myself.myselfPeer.peerId)) {//两方手动尝试或者出现异常时单向尝试
            this.createPeerConnection(this._targetPeerId, this._connectAddress)
            this.createDataChannel("")
            await this.sendOffer("")
        }
    }

    async onIceCandidate(evt) {
        if (evt.candidate) {
            let payload = JSON.stringify(evt.candidate)
            await rtcCandidateAction.candidate(null, payload, this.targetPeerId)
        }
    }

    onConnectionStateChange(evt) {
        switch (this._peerConnection.connectionState) {
            case "connected":
                console.log('webrtc connected---------')
                if (this._dataChannel && this._dataChannel.readyState === 'open') {
                    this.onDataChannelOpen(evt, this._targetPeerId)
                }
                break;
            case "disconnected":
                console.log('webrtc disconnected---------')//activeStatus->down
                this.onDataChannelClose(evt, this._targetPeerId)
                break;
            case "failed":
                console.log('webrtc failed---------')//activeStatus->down
                // this.onDataChannelClose(evt)
                break;
            case "closed":
                console.log('webrtc closed---------')//activeStatus->down
                this.onDataChannelClose(evt, this._targetPeerId)
                break;
        }
    }
    onTrack(evt) {
        this.onAddStream(evt.streams[0])
    }
    onDataChannel(evt) {
        this._dataChannel = evt.channel
        this.addDataChannel()
    }

    onIceGatheringStateChange(evt) {
        console.info('icegatheringstatechange:' + this._peerConnection.iceGatheringState)
    }

    onNegotiationNeeded() {
        console.info('onnegotiationneeded:')
    }

    onSignalingStateChange(evt) {
        console.info('onsignalingstatechange:' + this._peerConnection.signalingState)
    }

    getVideoCodecs() {
        const senders = this._peerConnection.getSenders()
        let codecs = null
        senders.forEach((sender) => {
            if (sender.track.kind === 'video') {
                codecs = sender.getParameters().codecs

                return
            }
        })

        return codecs
    }
    changeVideoCodec(mimeType) {
        const transceivers = this._peerConnection.getTransceivers()
        transceivers.forEach(transceiver => {
            const kind = transceiver.sender.track.kind
            let sendCodecs = RTCRtpSender.getCapabilities(kind).codecs
            let recvCodecs = RTCRtpReceiver.getCapabilities(kind).codecs

            if (kind === 'video') {
                sendCodecs = this.preferCodec(sendCodecs, mimeType)
                recvCodecs = this.preferCodec(recvCodecs, mimeType)
                transceiver.setCodecPreferences([...sendCodecs, ...recvCodecs])
            }
        })
    }

    preferCodec(codecs, mimeType) {
        let otherCodecs = []
        let sortedCodecs = []
        let count = codecs.length

        codecs.forEach(codec => {
            if (codec.mimeType === mimeType) {
                sortedCodecs.push(codec)
            } else {
                otherCodecs.push(codec)
            }
        })

        return sortedCodecs.concat(otherCodecs)
    }

    createDataChannel(label) {
        try {
            this._dataChannel = this._peerConnection.createDataChannel(label)

            return this.addDataChannel()
        } catch (error) {
            console.error("data_channel_create_error", error)
        }
    }

    /**
     * 数据通道打开的回调函数
     * @param evt 
     */
    onAddStream(stream: any) {

    }

    /**
     * 数据通道打开的回调函数
     * @param evt 
     */
    onDataChannelOpen(evt: any, remotePeerId: string) {
        console.info('from ' + remotePeerId + ' event ' + evt)
    }

    /**
     * 数据通道关闭的回调函数
     * @param evt 
     */
    onDataChannelClose(evt: any, remotePeerId: string) {
        console.info('from ' + remotePeerId + ' event ' + evt)
    }

    async onMessage(data: Uint8Array, remotePeerId: string, remoteAddr: string) {
        chainMessageHandler.receiveRaw(data, remotePeerId, remoteAddr)
    }

    addDataChannel() {
        let _that = this;
        this._dataChannel.onopen = async function (evt) {
            console.log('channel open -------------')
            _that.onDataChannelOpen(evt, _that._targetPeerId)
        }
        this._dataChannel.onclose = function (evt) {
            console.log('channel close -------------')
            _that.onDataChannelClose(evt, _that._targetPeerId)
        }
        this._dataChannel.onmessage = async function (evt) {
            _that.onMessage(evt.data, _that._targetPeerId, null)
        }
        this._dataChannel.onerror = function (err) {
            console.error('data_channel_error', err)
            if (_that._dataChannel) {
                _that._dataChannel.close()
            }
        }
    }

    closeDataChannel() {
        if (this._dataChannel) {
            this._dataChannel.close()
        }
    }

    async sendOffer(mediaProperty) {
        let session_desc = await this._peerConnection.createOffer()
        let payload: any = {}
        payload.sdp = JSON.stringify(session_desc)
        payload.connectAddress = this._connectAddress
        if (mediaProperty) {
            payload.mediaProperty = mediaProperty
        }
        await rtcOfferAction.offer(null, payload, this._targetPeerId)
        await this._peerConnection.setLocalDescription(session_desc)
    }

    async receiveOffer(sourcePeerId, sdp, connectAddress, mediaProperty) {
        await this.sendAnswer(sourcePeerId, sdp, connectAddress, mediaProperty)
    };

    async sendAnswer(sourcePeerId, sdp, connectAddress, mediaProperty) {
        sdp = JSON.parse(sdp)
        try {
            await this._peerConnection.setRemoteDescription(new RTCSessionDescription(sdp))
        } catch (err) {
            console.log(err)
            await this.repeatAttempt('error')
        }
        let session_desc = await this._peerConnection.createAnswer() //async function (session_desc) {
        console.log("createAnswer")
        await this._peerConnection.setLocalDescription(session_desc)
        let payload: any = {}
        payload.sdp = JSON.stringify(session_desc) // sdp
        if (mediaProperty) {
            payload.mediaProperty = mediaProperty
        }
        await rtcAnswerAction.answer(null, payload, sourcePeerId)
        if (!mediaProperty && !this._attemptingTag[sourcePeerId]) {
            this._attemptingTag[sourcePeerId] = true
            let _that = this
            setTimeout(async function () {
                _that._attemptingTag[sourcePeerId] = false
                console.log(this._peerConnection)
                if (this._peerConnections[sourcePeerId].connectionState !== 'connected') {
                    await _that.repeatAttempt('error');
                }
            }, repeatAttemptTimeOut)
        }
    }

    async receiveAnswer(peerId, sdp, mediaProperty) {
        let _that = this
        let peerConnection = _that._peerConnection
        if (peerConnection) {
            sdp = JSON.parse(sdp);
            console.log("receiveAnswer")
            try {
                await peerConnection.setRemoteDescription(new RTCSessionDescription(sdp))
            } catch (err) {
                console.log(err)
                await _that.repeatAttempt('error')
            }
            if (!mediaProperty && !_that._attemptingTag) {
                _that._attemptingTag = true
                setTimeout(function () {
                    _that._attemptingTag = false
                    if (_that._peerConnection.connectionState !== 'connected') {
                        _that.repeatAttempt('error')
                    }
                }, repeatAttemptTimeOut)
            }
        } else {
            console.log('receiveAnswer_error_peerConnection_undefined' + peerId)
        }
    }

    async receiveCandidate(candidate) {
        //if (peerConnection && peerConnection.remoteDescription && peerConnection.remoteDescription && peerConnection.connectionState !== 'connected') {
        if (this._peerConnection && this._peerConnection.remoteDescription) {
            try {
                console.log('candidate:' + candidate + ', onsignalingstatechange:' + this._peerConnection.signalingState)
                candidate = JSON.parse(candidate)
                await this._peerConnection.addIceCandidate(new RTCIceCandidate(candidate))
            }
            catch (err) {
                console.log(err)
            }
        }
    }

    attachStream(stream, element) {
        element.srcObject = stream
        element.play()
        if (stream) {
            stream.onremovetrack = (event) => {
                console.log(`Video track: ${event.track.label} removed`)
            }
        }
    }

    async send(message: Uint8Array) {
        let _that = this
        if (_that._peerConnection
            && _that._peerConnection.connectionState.toLowerCase() === 'connected'
            && _that._dataChannel && _that._dataChannel.readyState.toLowerCase() === 'open') {
            await _that._dataChannel.send(message)
        } else {
            if (_that._peerConnection
                && _that._peerConnection.connectionState.toLowerCase() !== 'connected'
                && _that._dataChannel && _that._dataChannel.readyState.toLowerCase() === 'open') {
                // && _that.linkmanMap[peerId].activeStatus === 'UP'
                _that.onDataChannelClose('', _that._targetPeerId)
            }
            if (this._targetPeerId !== myself.myselfPeer.peerId) {
                await _that.repeatAttempt('')
            }
        }
    }
}

/**
 * webrtc的连接池，键值是对方的peerId
 */
export class WebrtcPool {
    private webrtcs = new Map<string, Webrtc>()
    constructor() { }

    /**
     * 此处peerId应该带有客户识别信息，用于多终端同时使用
     * @param peerId 
     */
    get(peerId: string): Webrtc {
        if (this.webrtcs.has(peerId)) {
            return this.webrtcs.get(peerId)
        } else {
            let webrtc = new Webrtc()
            if (webrtc.status) {
                this.webrtcs.set(peerId, webrtc)

                return webrtc
            }
        }

        return null
    }

    getAll(): Webrtc[] {
        let webrtcs: Webrtc[] = []
        for (let webrtc of this.webrtcs.values()) {
            webrtcs.push(webrtc)
        }
        return webrtcs
    }

    async sendRtcConnect(peerId: string, connectAddress: string) {
        let webrtc = new Webrtc()
        webrtc.createPeerConnection(peerId, connectAddress)
        webrtc.createDataChannel(peerId)
        await webrtc.sendOffer(peerId)
        for (let i = 0; i++; i <= repeatAttemptLimit) {
            setTimeout(async function () {
                if (webrtc.peerConnection.connectionState !== 'connected') {
                    await webrtc.repeatAttempt('')
                }
            }, repeatAttemptTimeOut)
        }
    }

    hasRTCPeerConnection() {
        window.RTCPeerConnection = window.RTCPeerConnection || window.webkitRTCPeerConnection || window.mozRTCPeerConnection
        window.RTCSessionDescription = window.RTCSessionDescription || window.webkitRTCSessionDescription || window.mozRTCSessionDescription
        window.RTCIceCandidate = window.RTCIceCandidate || window.webkitRTCIceCandidate || window.mozRTCIceCandidate

        return !!window.RTCPeerConnection
    }

    async send(peerId: string, data: Uint8Array) {
        let webrtc: Webrtc = await this.get(peerId)
        if (webrtc) {
            await webrtc.dataChannel.send(data)
        }
    }
}
export let webrtcPool = new WebrtcPool()

/**
 * 音视频流的端到端加密处理的配置
 */
class CryptoMessage {
    private worker: Worker = null
    constructor(isWorker: boolean) {
        this.worker = null
        if (isWorker === true) {
            this.worker = new Worker()
        }
    }
    /**
         * 对发送者安装加密函数，在视频中获取编码流，在编码流中加入Transform
         * pc.getSenders().forEach(setupSenderTransform);
         * let stream = await navigator.mediaDevices.getUserMedia({video:true});
         let [track] = stream.getTracks();
         let videoSender = pc.addTrack(track, stream)
         let senderStreams = videoSender.createEncodedStreams();
         // Do ICE and offer/answer exchange.
         senderStreams.readable
         .pipeThrough(senderTransform)
         .pipeTo(senderStreams.writable);
         * @param {*} RTCSender sender
         */
    setupSenderTransform(sender) {
        // 获取发送者的编码流
        let senderStreams
        if (webrtcEncrypt.supportInsertableStream() === true) {
            senderStreams = sender.createEncodedStreams()
        } else {
            senderStreams = sender.track.kind === 'video' ? sender.createEncodedVideoStreams() : sender.createEncodedAudioStreams()
        }
        let cryptoKey = webrtcEncrypt.getCryptoKey()
        if (this.worker === null) {
            const transformStream = new TransformStream({
                transform: async (chunk, controller) => {
                    webrtcEncrypt.encrypt(chunk, controller, cryptoKey)
                }
            })
            senderStreams.readableStream
                .pipeThrough(transformStream)
                .pipeTo(senderStreams.writableStream)
        } else {
            /**
             * 下面的代码是在工作线程做加解密的代码
             * 传递的消息包括操作方式和读写流
             * */
            this.worker.postMessage({
                operation: 'encypt', // 加密操作
                cryptoKey: cryptoKey,
                readableStream: senderStreams.readableStream,
                writableStream: senderStreams.writableStream
            }, [senderStreams.readableStream, senderStreams.writableStream])
        }
    }

    /**
     * 对接受者安装解密函数
     * @param {*} receiver
     * let pc = new RTCPeerConnection({encodedInsertableStreams: true});
     pc.ontrack = e => {
          let receiverStreams = e.receiver.createEncodedStreams();
          receiverStreams.readable
            .pipeThrough(receiverTransform)
            .pipeTo(receiverStreams.writable);
     */
    setupReceiverTransform(receiver) {
        let receiverStreams
        if (webrtcEncrypt.supportInsertableStream()) {
            receiverStreams = receiver.createEncodedStreams()
        } else {
            receiverStreams = receiver.track.kind === 'video' ? receiver.createEncodedVideoStreams() : receiver.createEncodedAudioStreams()
        }
        let cryptoKey = webrtcEncrypt.getCryptoKey()
        if (this.worker === null) {
            const transformStream = new TransformStream({
                transform: async (chunk, controller) => {
                    webrtcEncrypt.decrypt(chunk, controller, cryptoKey)
                }
            })
            receiverStreams.readableStream
                .pipeThrough(transformStream)
                .pipeTo(receiverStreams.writableStream)
        } else {
            // 下面的代码是在工作线程做加解密的代码
            this.worker.postMessage({
                operation: 'decrypt',
                cryptoKey: cryptoKey,
                readableStream: receiverStreams.readableStream,
                writableStream: receiverStreams.writableStream
            }, [receiverStreams.readableStream, receiverStreams.writableStream])
        }
    }
}