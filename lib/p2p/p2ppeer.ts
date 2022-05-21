// Libp2p Core
import libp2p from 'libp2p';
import {Libp2pOptions} from 'libp2p';
// Transports
// @ts-ignore
import websockets from 'libp2p-websockets-curltech';
//const websockets = require('libp2p-websockets')
// Stream Muxer
// @ts-ignore
import mplex from 'libp2p-mplex-curltech';
// Connection Encryption
import {NOISE, Noise} from '@chainsafe/libp2p-noise';
// Peer Discovery
import bootstrap from 'libp2p-bootstrap';
import kaddht from 'libp2p-kad-dht';
// Gossipsub
import gossipsub from 'libp2p-gossipsub';

import {config} from '@/libs/conf';
import {EntityStatus} from '@/libs/datastore/base';
import {myself, Myself, myselfPeerService} from '@/libs/p2p/dht/myselfpeer';
import {peerProfileService} from '@/libs/p2p/dht/peerprofile';
import {openpgp} from '@/libs/crypto/openpgp';
import {dispatchDatastore, dispatchPool} from '@/libs/p2p/datastore/ds';
import {libp2pClientPool, Libp2pPipe} from '@/libs/transport/libp2p';

//const webrtcDirect = require('libp2p-webrtc-direct')
//const multiaddr = require('multiaddr')
//const pipe = require('pull-stream')
//const { collect } = require('streaming-iterables')
const PeerId = require('peer-id');
const libp2pcrypto = require('libp2p-crypto');
const {FaultTolerance} = require('libp2p/src/transport-manager');

export class P2pPeer {
  public host: any;
  public peerId!: any;
  public multiaddrs!: string[];
  public rendezvous!: string;
  public connectionManager: any;
  public chainProtocolId: string = config.appParams.chainProtocolId;
  public webrtcstarHost!: string;
  public topic!: string;

  /**
   * 启动p2p节点，返回本节点对象
   * @param bootstrapAddrs
   */
  async start(bootstrapAddrs: string[], opts = {
    WebSockets: {
      debug: false,
      timeoutInterval: 5000,
      binaryType: 'arraybuffer'
    }
  }) {
    if (this.host && this.host.isStarted() === true) {
      console.warn('p2pPeer has started! will restart');
      await this.stop();
    }
    if (!bootstrapAddrs) {
      bootstrapAddrs = config.appParams.connectPeerId;
    }
    let addresses = {
      listen: config.appParams.addrs
    };
    // custom noise configuration, pass it instead of NOISE instance
    //const noise = new Noise(privateKey, Buffer.alloc(x))
    let modules = {
      transport: [websockets],
      streamMuxer: [mplex],
      connEncryption: [NOISE], // or above custom noise
      peerDiscovery: [bootstrap],
      dht: kaddht,
      pubsub: gossipsub
      // contentRouting: [
      //   new DelegatedContentRouter(peerId)
      // ],
      // peerRouting: [
      //   new DelegatedPeerRouter()
      // ],
    };
    let dialer = {
      maxParallelDials: 100,
      maxDialsPerPeer: 4,
      dialTimeout: 30e3
    };
    let connectionManager = {
      maxConnections: Infinity,
      minConnections: 0,
      pollInterval: 2000,
      defaultPeerValue: 1,
      // The below values will only be taken into account when Metrics are enabled
      maxData: Infinity,
      maxSentData: Infinity,
      maxReceivedData: Infinity,
      maxEventLoopDelay: Infinity,
      movingAverageInterval: 60000
    };
    let transportManager = {
      faultTolerance: FaultTolerance.NO_FATAL
    };
    let optionConfig = {
      peerDiscovery: {
        autoDial: true, // Auto connect to discovered peers (limited by ConnectionManager minConnections)
        // The `tag` property will be searched when creating the instance of your Peer Discovery service.
        // The associated object, will be passed to the service when it is instantiated.
        bootstrap: {
          enabled: true,
          interval: 60e3,
          list: bootstrapAddrs // Libp2pParams.BootstrapAddrs
        },
        // [MulticastDNS.tag]: {
        //   interval: 1000,
        //   enabled: true
        // }
        // [WebRTCStar.tag]: {
        //   enabled: true
        // }
      },
      // pubsub: {                     // The pubsub options (and defaults) can be found in the pubsub router documentation
      //   enabled: true,
      //   emitSelf: true,             // whether the node should emit to self on publish
      //   signMessages: true,         // if messages should be signed
      //   strictSigning: true         // if message signing should be required
      // }
      relay: {                   // Circuit Relay options (this config is part of libp2p core configurations)
        enabled: true,           // Allows you to dial and accept relayed connections. Does not make you a relay.
        hop: {
          enabled: true,         // Allows you to be a relay for other peers
          active: true           // You will attempt to dial destination peers if you are not connected to them
        },
      },
      transport: {
        WebSockets: opts ? opts.WebSockets : {}
        //   [transportKey]: {
        //     wrtc // You can use `wrtc` when running in Node.js
        //   }
      },
      dht: {                        // The DHT options (and defaults) can be found in its documentation
        //   kBucketSize: 20,
        enabled: true,
        randomWalk: {
          enabled: true,            // Allows to disable discovery (enabled by default)
          interval: 300e3,
          timeout: 10e3
        }
      }
    };
    let metrics = {
      enabled: true,
      computeThrottleMaxQueueSize: 1000,
      computeThrottleTimeout: 2000,
      movingAverageIntervals: [
        60 * 1000, // 1 minute
        5 * 60 * 1000, // 5 minutes
        15 * 60 * 1000 // 15 minutes
      ],
      maxOldPeersRetention: 50
    };
    let keychain = {
      pass: '123456',
      //datastore: new LevelStore('path/to/store')
    };

    //let datastore = new LevelStore('path/to/store')
    let peerStore = {
      persistence: true,
      threshold: 1 // default 5, browser nodes should use a threshold of 1
    };
    dispatchPool.init();
    let options: any = {
      peerId: this.peerId,
      addresses: addresses,
      modules: modules,
      config: optionConfig,
      datastore: dispatchDatastore,
      keychain: keychain,
      metrics: metrics
    };
    this.host = await libp2p.create(options);

    this.host.handle(this.chainProtocolId, libp2pClientPool.handleRaw);
    this.registEvent();
    await this.host.start();
  }

  async stop() {
    if (this.host.isStarted() === true) {
      await this.host.stop();
    }
  }

  async initMyself(password: string, myselfPeer: any): Promise<Myself> {
    if (!myselfPeer) {
      throw new Error("NoMyselfPeer");
    }
    if (!myselfPeer.name) {
      throw new Error("NoMyselfPeerName");
    }
    if (!password) {
      throw new Error("NoPassword");
    }
    /**
     perrId对应的密钥对
     */
      // 'RSA', 'ed25519', and secp256k1
    let peerPrivateKey = await libp2pcrypto.keys.generateKeyPair('ed25519');
    let pub = peerPrivateKey.public;
    myselfPeer.peerPrivateKey = await peerPrivateKey.export(password, 'libp2p-key');
    let buf: Uint8Array = await libp2pcrypto.keys.marshalPublicKey(pub, 'ed25519');
    myselfPeer.peerPublicKey = openpgp.encodeBase64(buf);
    let peerId = await PeerId.createFromPrivKey(peerPrivateKey.bytes);
    let id = await peerId.toB58String();
    myselfPeer.peerId = id;
    /**
     加密对应的密钥对openpgp
     */
    let userIds: any = [{name: myselfPeer.name, mobile: myselfPeer.mobile, peerId: myselfPeer.peerId}];
    let keyPair = await openpgp.generateKey({
      userIds: userIds,
      namedCurve: 'ed25519',
      passphrase: password
    });

    let privateKey = keyPair.privateKey;
    myselfPeer.privateKey = await openpgp.export(keyPair.privateKey, password);
    //let privateKey = await openpgp.import(myselfPeer.privateKey, { password: password })
    myselfPeer.publicKey = await openpgp.export(keyPair.publicKey, '');

    myselfPeer.securityContext = JSON.stringify({
      Protocol: 'OpenPGP',
      KeyPairType: 'Ed25519',
    });

    myself.myselfPeer = myselfPeer;
    myself.peerProfile = undefined;
    myself.password = password;
    myself.peerPrivateKey = peerPrivateKey;
    myself.peerPublicKey = pub;

    if (privateKey) {
      let isDecrypted = privateKey.isDecrypted();
      console.log('isDecrypted:' + isDecrypted);
      if (!isDecrypted) {
        await privateKey.decrypt(password);
      }
    }
    //myself.privateKey = keyPair.privateKey
    myself.privateKey = privateKey;
    myself.publicKey = keyPair.publicKey;

    return myself;
  }

  /*async startWebrtcDirect() {
    const addr = multiaddr('/ip4/127.0.0.1/tcp/4710/http/p2p-webrtc-direct')

    const webrtc = new webrtcDirect()

    const listener = webrtc.createListener((socket) => {
      console.log('new connection opened')
      pipe(
        ['hello'],
        socket
      )
    })
    await listener.listen(addr)

    const conn = await webrtc.dial(addr)
    const values = await pipe(
      conn,
      collect
    )
    console.log(`Value: ${values.toString()}`)

    // Close connection after reading
    // await listener.close()
  }*/

  /**
   * 获取自己节点的记录，并解开私钥
   */
  async getMyself(password: string, peerId: string, mobile: string, name: string): Promise<Myself> {
    if (!password) {
      throw new Error("NoPassword");
    }
    if (!peerId && !mobile && !name) {
      throw new Error("NoPeerIdAndMobileAndName");
    }
    let param: any = {status: EntityStatus[EntityStatus.Effective]};
    if (peerId) {
      param.peerId = peerId;
    }
    if (mobile) {
      param.mobile = mobile;
    }
    if (name) {
      param.name = name;
    }
    let myselfPeer = await myselfPeerService.findOne(param, null, null);
    if (!myselfPeer) {
      throw new Error("AccountNotExists");
    }
    if (!myselfPeer.peerId) {
      console.error('!myselfPeer.peerId');
      throw new Error("InvalidAccount");
    }
    if (!peerId) {
      peerId = myselfPeer.peerId;
    }
    let publicKey = await openpgp.import(myselfPeer.publicKey);
    let buf = openpgp.decodeBase64(myselfPeer.peerPublicKey);
    let pub = await libp2pcrypto.keys.unmarshalPublicKey(buf);
    let privateKey: any = null;
    let priv: any = null;
    try {
      privateKey = await openpgp.import(myselfPeer.privateKey, {password: password});
      if (!privateKey) {
        console.error('!import(myselfPeer.privateKey)');
        throw new Error("InvalidAccount");
      }
      let isDecrypted = privateKey.isDecrypted();
      console.log('isDecrypted:' + isDecrypted);
      if (!isDecrypted) {
        await privateKey.decrypt(password);
      }
      priv = await libp2pcrypto.keys.import(myselfPeer.peerPrivateKey, password);
    } catch (e) {
      console.error(e);
      throw new Error('WrongPassword');
    }
    this.peerId = await PeerId.createFromPrivKey(priv.bytes);
    if (peerId !== this.peerId.toB58String()) {
      console.error('peerId !== PeerId.createFromPrivKey(priv.bytes).toB58String()');
      throw new Error("InvalidAccount");
    }
    let timestamp_ = new Date().getTime();
    let random_ = await openpgp.getRandomAsciiString();
    let key = timestamp_ + random_;
    let signature = await openpgp.sign(key, privateKey);
    let pass = await openpgp.verify(key, signature, publicKey);
    if (!pass) {
      throw new Error('VerifyNotPass');
    }
    param = {status: EntityStatus[EntityStatus.Effective]};
    param.peerId = peerId;
    let peerProfile = await peerProfileService.findOne(param, null, null);

    myself.myselfPeer = myselfPeer;
    myself.peerProfile = peerProfile;
    myself.password = password;
    myself.peerPrivateKey = priv;
    myself.peerPublicKey = pub;
    myself.privateKey = privateKey;
    myself.publicKey = publicKey;

    return myself;
  }

  upsertMyselfPeer() {
    let myselfPeer: any = myself.myselfPeer;
    let id: number = myselfPeer._id;
    if (!id) { //新的
      myselfPeer.status = EntityStatus[EntityStatus.Effective];
      let saddrs = this.host.addressManager.getListenAddrs();
      myselfPeer.address = JSON.stringify(saddrs);
      myselfPeer = myselfPeerService.insert(myselfPeer);
    } else {
      let needUpdate = false;
      let saddrs = this.host.addressManager.getListenAddrs();
      let addrs: string = JSON.stringify(saddrs);
      console.log('address:' + addrs);
      if (myselfPeer.address !== addrs) {
        needUpdate = true;
        myselfPeer.address = addrs;
      }

      if (needUpdate === true) {
        myselfPeer = myselfPeerService.update(myselfPeer);
      }
    }
    myself.myselfPeer = myselfPeer;
  }

  registEvent() {
    this.host.on('peer:discovery', (peerId: any) => {
      console.log('Found peer', peerId.toB58String());
    });
    this.host.connectionManager.on('peer:connect', (connection: any) => {
      console.log('Connected to', connection.remotePeer.toB58String());
    });
    this.host.connectionManager.on('peer:disconnect', (connection: any) => {
      console.log('Disconnected from', connection.remotePeer.toB58String());
    });
    this.host.on('error', (err: any) => {
      console.error('p2pPeer error:' + err);
    });
    /*this.host.peerStore.on('peer', (peerId) => {
      console.info('p2pPeer peerStore peer:' + peerId.toB58String())
    })
    this.host.peerStore.on('change:multiaddrs', ({ peerId, multiaddrs }) => {
      console.info('p2pPeer peerStore change multiaddrs:' + peerId.toB58String() + ',' + multiaddrs)
    })
    this.host.peerStore.on('change:protocols', ({ peerId, protocols }) => {
      console.info('p2pPeer peerStore change protocols:' + peerId.toB58String() + ',' + protocols)
    })
    this.host.addressManager.on('change:addresses', () => {
      console.info('p2pPeer peerStore change addresses')
    })*/
  }

  /**
   * Sends the updated stats to the pubsub network
   * @param {Array<string>} connectedPeers
   */
  async sendStats(connectedPeers: any) {
    try {
      await this.host.pubsub.publish(this.topic, '');
    } catch (err) {
      console.error('Could not publish stats update');
    }
  }

  async createStream(remotePeer: string, protocolId: string): Promise<Libp2pPipe> {
    const conn = await this.host.dial(remotePeer);
    const {stream, protocol} = await conn.newStream([protocolId]);
    let libp2pPipe = new Libp2pPipe();
    libp2pPipe.connection = conn;
    libp2pPipe.protocol = protocol;
    libp2pPipe.stream = stream;

    return libp2pPipe;
  }

  /**
   * for (const [peerId, connections] of libp2p.connections) {
        for (const connection of connections) {
          console.log(peerId, connection.remoteAddr.toString())
          // Logs the PeerId string and the observed remote multiaddr of each Connection
        }
      }
   */
  get connections() {
    return this.host.connections;
  }

  /**
   * peer  PeerId|Multiaddr|string
   * const conn = await libp2p.dial(remotePeerId)
   * const { stream, protocol } = await conn.newStream(['/echo/1.1.0', '/echo/1.0.0'])
   * await conn.close()
   */
  async dial(peer: any, options: any): Promise<any> {
    return await this.host.dial(peer, options);
  }

  /**
   * peer, protocols, options
   * peer  PeerId|Multiaddr|string
   * const pipe = require('it-pipe')
   const { stream, protocol } = await libp2p.dialProtocol(remotePeerId, protocols)
   pipe([1, 2, 3], stream, consume)
   */
  async dialProtocol(peer: any, protocols: string[], options: any): Promise<{ stream: any, protocol: string }> {
    return await this.host.dialProtocol(peer, protocols, options);
  }

  /**
   * await libp2p.hangUp(remotePeerId)
   */
  async hangUp(peer: any): Promise<void> {
    await this.host.hangUp(peer);
  }

  /**
   * const handler = ({ connection, stream, protocol }) => {
      }
   libp2p.handle('/echo/1.0.0', handler)
   */
  handle(protocols: string[], handler: any) {
    return this.host.handle(protocols, handler);
  }

  /**
   * libp2p.unhandle(['/echo/1.0.0'])
   */
  unhandle(protocols: string[]) {
    return this.host.unhandle(protocols);
  }

  /**
   * const latency = await libp2p.ping(otherPeerId)
   */
  async ping(peer: any, timeoutInterval: number): Promise<number> {
    let latency = null;
    timeoutInterval = timeoutInterval ? timeoutInterval : 5000;
    try {
      let p1 = this.host.ping(peer);
      let p2 = new Promise((resolve, reject) => {
        setTimeout(() => {
          reject('timeout');
        }, timeoutInterval);
      });
      latency = await Promise.race([p1, p2]);
    } catch (err) {
      console.error(err);
    } finally {
      if (!latency) {
        latency = 999999999;
      }
      return latency;
    }
  }

  /**
   * const listenMa = libp2p.multiaddrs
   // [ <Multiaddr 047f00000106f9ba - /ip4/127.0.0.1/tcp/63930> ]
   */
  get hostMultiaddrs() {
    return this.host.multiaddrs;
  }

  get addressManager() {
    return this.host.addressManager;
  }

  get transportManager() {
    return this.host.transportManager;
  }

  get contentRouting() {
    return this.host.contentRouting;
  }

  get peerRouting() {
    return this.host.peerRouting;
  }

  get peerStore() {
    return this.host.peerStore;
  }

  get addressBook() {
    return this.host.peerStore.addressBook;
  }

  get pubsub() {
    return this.host.pubsub;
  }

  get hostconnectionManager() {
    return this.host.connectionManager;
  }

  get keychain() {
    return this.host.keychain;
  }

  get metrics() {
    return this.host.metrics;
  }

  /**
   * libp2p.on('error', (err) => {})
   * libp2p.on('peer:discovery', (peer) => {})
   */
  on(name: string, fn: any) {
    this.host.on(name, fn);
  }

  /**
   * 'peer:connect', (connection) => {}
   * 'peer:disconnect', (connection) => {}
   * @param name
   * @param fn
   */
  onConnection(name: string, fn: any) {
    this.host.connectionManager.on(name, fn);
  }

  /**
   * 'peer', (peerId) => {}
   * 'change:multiaddrs', ({ peerId, multiaddrs}) => {}
   * 'change:protocols', ({ peerId, protocols}) => {}
   * @param name
   * @param fn
   */
  onPeerStore(name: string, fn: any) {
    this.host.peerStore.on(name, fn);
  }
}

export let p2pPeer = new P2pPeer();
