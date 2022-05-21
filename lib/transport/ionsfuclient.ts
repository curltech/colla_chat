import {TypeUtil, UUID} from '@/libs/tool/util'
import {config} from '@/libs/conf'
import {Client, LocalStream, Signal, Trickle} from 'ion-sdk-js'
import {Configuration} from 'ion-sdk-js/lib/client'
// @ts-ignore
//import {IonSignalAction} from '../chain/action/ionsignal'

/**
 * ion sfu自定义的信号实现
 */
export class IonSfuSignal implements Signal {
  onnegotiate?: (jsep: RTCSessionDescriptionInit) => void;
  ontrickle?: (trickle: Trickle) => void;

  private _ionSfuClient: IonSfuClient

  constructor() {
  }

  set ionSfuClient(ionSfuClient: IonSfuClient) {
    this._ionSfuClient = ionSfuClient
  }

  receive(data: any) {
    if (data.type === 'offer') {
      if (this.onnegotiate) this.onnegotiate(data)
    } else if (data.type === 'trickle') {
      let trickle: any = {}
      trickle.candidate = data.candidate
      if (!data.target) {
        data.target = 0
      }
      trickle.target = data.target
      if (this.ontrickle) this.ontrickle(trickle)
    }
  }

  async call<T>(params: any): Promise<T> {
    const id = UUID.string(12, 1)
    params.id = id
    let result = await ionSfuClientPool.emitEvent('signal', {
      data: params, source: this._ionSfuClient
    })

    return result
  }

  async notify(params: any) {
    await ionSfuClientPool.emitEvent('signal', {
      data: params, source: this._ionSfuClient
    })
  }

  /**
   * 假设会返回answer
   * @param sid
   * @param offer
   */
  async join(sid: string, uid: null | string, offer: RTCSessionDescriptionInit): Promise<RTCSessionDescriptionInit> {
    let response: any = await this.call<RTCSessionDescriptionInit>({type: 'join', sid: sid, sdp: offer.sdp})
    if (response && response.sdp) {
      return response.sdp
    }
    throw new Error('NoSdpResponse')
  }

  trickle(trickle: Trickle) {
    this.notify({type: 'trickle', target: trickle.target, candidate: trickle.candidate})
  }

  /**
   * 假设会返回answer
   * @param offer
   */
  async offer(offer: RTCSessionDescriptionInit) {
    let response: any = await this.call<RTCSessionDescriptionInit>({type: 'offer', sdp: offer.sdp})
    if (response && response.sdp) {
      return response.sdp
    }
    throw new Error('NoSdpResponse')
  }

  answer(answer: RTCSessionDescriptionInit) {
    this.notify({type: 'answer', sdp: answer.sdp})
  }

  close() {
    console.error('libp2p websocket canot be closed!')
  }
}

export class IonSfuClient {
  private _signal: IonSfuSignal
  private _client: Client
  private _targetPeerId: string
  private _connectPeerId: string
  private _connectSessionId: string
  private _iceServer: RTCIceServer[]
  private _dataChannel: RTCDataChannel
  private _remoteStreams: any[] = []
  private _router: any
  private _connected: boolean = false
  private _start: number
  private _end: number
  private _pc: RTCPeerConnection

  get client() {
    return this._client
  }

  get targetPeerId() {
    return this._targetPeerId
  }

  get connectSessionId() {
    return this._connectSessionId
  }

  get connectPeerId() {
    return this._connectPeerId
  }

  set connectSessionId(connectSessionId: string) {
    this._connectSessionId = connectSessionId
  }

  set connectPeerId(connectPeerId: string) {
    this._connectPeerId = connectPeerId
  }

  constructor(targetPeerId: string, router: any, config: Configuration) {
    this.init(targetPeerId, router, config)
  }

  init(targetPeerId: string, router: any, conf: Configuration) {
    this._targetPeerId = targetPeerId
    this._router = router
    if (!conf) {
      conf = {codec: 'vp8'}
    }
    if (!conf.iceServers) {
      conf.iceServers = config.appParams.iceServers[0]
    }
    this._iceServer = conf.iceServers
    this._start = Date.now()
    this._signal = new IonSfuSignal()
    this._client = new Client(this._signal, conf)
    this.ondatachannel()
    this._signal.ionSfuClient = this
    this.join(this._router.roomId)
    if (this._client && this._client.transports && this._client.transports[0]) {
      let transport: any = this._client.transports[0]
      this._pc = transport.pc
      let _that = this
      this._pc.onconnectionstatechange = () => {
        console.info('onconnectionstatechange:' + _that._pc.connectionState)
        if (_that._pc.connectionState === 'connected') {
          _that._connected = true
          this._end = Date.now()
        } else {
          _that._connected = false
        }
      }
      this._pc.oniceconnectionstatechange = () => {
        console.info('oniceconnectionstatechange:' + this._pc.iceConnectionState)
      }
      this._pc.onicecandidateerror = (ev) => {
        console.info('onicecandidateerror:' + ev.type)
      }
      this._pc.onicegatheringstatechange = () => {
        console.info('onicegatheringstatechange:' + this._pc.iceGatheringState)
      }
      this._pc.onsignalingstatechange = () => {
        console.info('onsignalingstatechange:' + this._pc.signalingState)
      }
      this._pc.onicecandidate = (ev) => {
        console.info('onicecandidate:' + this._pc.iceConnectionState)
      }
    }
  }

  /**
   * 获取本地设备流（摄像头）
   * {
			audio: true,
			video: true,
			simulcast: true, // enable simulcast
		}
   * @param options
   */
  getUserMedia(options: any): Promise<LocalStream> {
    // Get a local stream
    const local = LocalStream.getUserMedia(options)

    return local
  }

  /**
   * {
			codec: 'VP8',
			resolution: 'hd',
			audio: false,
			video: true,
			simulcast: false,
		}
   * @param options
   */
  getDisplayMedia(options: any): Promise<LocalStream> {
    // Get a local stream
    const local = LocalStream.getDisplayMedia(options)

    return local
  }

  join(sid: string) {
    if (this._connected === true) {
      console.error('connected,canot rejoin')
      return
    }
    if (this._client)
      this._client.join(sid, '')
  }

  /**
   * 发布本地流
   * @param local
   */
  publish(local: any) {
    // Publish local stream
    if (this._client)
      this._client.publish(local)
  }

  leave() {
    if (this._client)
      this._client.leave()
  }

  close() {
    // Close client connection
    if (this._client)
      this._client.close()
    ionSfuClientPool.remove(this._targetPeerId, this._connectPeerId, this._connectSessionId)
  }

  getPubStats(selector?: MediaStreamTrack): Promise<RTCStatsReport> {
    if (this._client)
      return this._client.getPubStats(selector)
    return undefined
  }

  getSubStats(selector?: MediaStreamTrack): Promise<RTCStatsReport> {
    if (this._client)
      return this._client.getSubStats(selector)
    return undefined
  }

  /**
   * {
			codec: 'VP8',
			resolution: 'hd'
		}
   * @param options
   */
  buildLocalStream(stream: any, options: any): LocalStream {
    let myself = new LocalStream(stream, options)

    return myself
  }

  attachStream(element: any, stream: any) {
    if ('srcObject' in element) {
      element.srcObject = stream
      element.autoplay = true
      element.controls = true
      element.muted = true
    }
    element.play()
  }

  // create a datachannel
  createDataChannel(label: string) {
    if (this._client)
      this._dataChannel = this._client.createDataChannel(label)
  }

  onopen(handler: any) {
    this._dataChannel.onopen = handler
  }

  ontrack(handler: any) {
    // 	if (track.kind === "video") {
    // 		// prefer a layer
    // 		stream.preferLayer('low' | 'medium' | 'high')
    // 	}
    // }
    if (this._client)
      this._client.ontrack = handler
  }

  ondatachannel() {
    let _that = this
    if (this._client)
      this._client.ondatachannel = function (event: RTCDataChannelEvent) {
        event.channel.onopen = function () {
          console.log('Data channel is open and ready to be used.')
        }
        event.channel.onmessage = function (event: MessageEvent) {
          console.log('Data is received')
          ionSfuClientPool.emitEvent('data', {data: event.data, source: _that})
        }
        event.channel.onerror = function (event) {
          console.log('datachannel err')
        }
        event.channel.onclose = function (event) {
          console.log('Data channel is close')
        }
      }
  }

  send(data: any) {
    this._dataChannel.send(data)
  }

  signal(data: any) {
    try {
      this._signal.receive(data)
    } catch (err) {
      console.error(err)
    }
  }

  get connected(): boolean {
    return this._connected
  }
}

/**
 * webrtc的连接池，键值是对方的peerId
 */
export class IonSfuClientPool {
  private _clients = new Map<string, IonSfuClient>()
  private _events: Map<string, any> = new Map<string, any>()
  private _ionSignalAction: any = null
  private protocolHandlers = new Map()

  constructor() {
    this.registEvent('signal', this.sendSignal)
    this.registEvent('data', this.receiveData)
  }

  registSignalAction(ionSignalAction: any) {
    ionSfuClientPool._ionSignalAction = ionSignalAction
    ionSfuClientPool._ionSignalAction.registReceiver('ionSfuClientPool', ionSfuClientPool.receive)
  }

  registProtocolHandler(protocol: string, receiveHandler: any) {
    this.protocolHandlers.set(protocol, {
      receiveHandler: receiveHandler
    })
  }

  getProtocolHandler(protocol: string): any {
    return this.protocolHandlers.get(protocol)
  }

  /**
   * 获取peerId的webrtc连接，可能是多个
   * 如果不存在，创建一个新的连接，发起连接尝试
   * 否则，根据connected状态判断连接是否已经建立
   * @param peerId
   */
  get(peerId: string): IonSfuClient {
    if (ionSfuClientPool._clients.has(peerId)) {
      return ionSfuClientPool._clients.get(peerId)
    }

    return undefined
  }

  create(peerId: string, router: any): IonSfuClient {
    let client: IonSfuClient = undefined
    if (ionSfuClientPool._clients.has(peerId)) {
      client = ionSfuClientPool._clients.get(peerId)
      if (client && client.connected === true) {
        console.error('IonSfuClientExist:' + peerId)

        return client
      } else {
        if (client)
          client.close()
        this._clients.delete(peerId)
      }
    }
    client = new IonSfuClient(peerId, router, undefined)
    ionSfuClientPool._clients.set(peerId, client)

    return client
  }

  remove(peerId: string, connectPeerId: string, connectSessionId: string): boolean {
    if (ionSfuClientPool._clients.has(peerId)) {
      let client: IonSfuClient = ionSfuClientPool._clients.get(peerId)
      if (client) {
        ionSfuClientPool._clients.delete(peerId)
      }

      return true
    } else {
      return false
    }
  }

  getAll(): IonSfuClient[] {
    let clients: IonSfuClient[] = []
    ionSfuClientPool._clients.forEach((peer, key) => {
      clients.push(peer)
    })
    return clients
  }

  /**
   * 接收到signal的场景，有如下多张场景
   * 1.自己是被动方，而且同peerId的连接从没有创建过
   * @param peerId
   * @param connectSessionId
   * @param data
   */
  async receive(peerId: string, connectPeerId: string, connectSessionId: string, data: any) {
    let type = data.type
    if (type) {
      console.info('client:' + peerId + ' receive signal type:' + type)
    }
    let router = data.router
    let client: IonSfuClient = undefined
    // 被动方创建client，同peerId的连接从没有创建过，
    // 被动创建连接，设置peerId和connectPeerId，connectSessionId
    if (!ionSfuClientPool._clients.has(peerId)) {
      console.info('client:' + peerId + ' not exist, will create receiver')
      client = ionSfuClientPool.create(peerId, router)
      client.connectPeerId = connectPeerId
      client.connectSessionId = connectSessionId
    } else {
      client = ionSfuClientPool.get(peerId)
    }
    if (client) {
      console.info('client signal data:' + JSON.stringify(data))
      client.signal(data)
    }
  }

  /**
   * 向peer发送信息
   * @param peerId
   * @param data
   */
  async send(peerId: string, data: string | Uint8Array) {
    let client: IonSfuClient = ionSfuClientPool.get(peerId)
    if (client) {
      client.send(data)
    }
  }

  async receiveData(event: any) {
    let source = event.source
    let {
      receiveHandler
    } = ionSfuClientPool.getProtocolHandler(config.appParams.chainProtocolId)
    if (receiveHandler) {
      let remotePeerId = source.targetPeerId()
      /**
       * 调用注册的接收处理器处理接收的原始数据
       */
      let data: Uint8Array = await receiveHandler(event.data, remotePeerId, null)
      /**
       * 如果有返回的响应数据，则发送回去，不可以调用同步的发送方法send
       */
      if (data) {
        ionSfuClientPool.send(remotePeerId, data)
      }
    }
  }


  registEvent(name: string, func: any): boolean {
    if (func && TypeUtil.isFunction(func)) {
      this._events.set(name, func)
      return true
    }
    return false
  }

  unregistEvent(name: string) {
    this._events.delete(name)
  }

  async emitEvent(name: string, evt: any): Promise<any> {
    if (this._events.has(name)) {
      let func: any = this._events.get(name)
      if (func && TypeUtil.isFunction(func)) {
        return await func(evt)
      } else {
        console.error('event:' + name + ' is not func')
      }
    }
  }

  async sendSignal(evt: any): Promise<any> {
    try {
      let targetPeerId = evt.source.targetPeerId
      let type = evt.data.type
      console.info('client:' + targetPeerId + ' send signal:' + JSON.stringify(evt.data))
      let result = await ionSfuClientPool._ionSignalAction.signal(null, evt.data, targetPeerId)
      if (result === 'ERROR') {
        console.error('signal err:' + result)
      }
      return result
    } catch (err) {
      console.error('signal err:' + err)
    }

    return null
  }
}

export let ionSfuClientPool = new IonSfuClientPool()
