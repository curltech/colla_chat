

import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/tool/util.dart';

import '../../crypto/util.dart';
import '../../provider/app_data.dart';

const int maxBufferSize = 64 * 1024;
const int iceCompleteTimeout = 5 * 1000;
const int channelClosingTimeout = 5 * 1000;

// HACK: Filter trickle lines when trickle is disabled #354
String filterTrickle (String sdp) {
  return sdp.replaceAll('/a=ice-options:trickle\s\n/g', '');
}

warn (String message) {
  logger.w(message);
}

/// WebRTC peer connection. Same API as node core `net.Socket`, plus a few extra methods.
/// Duplex stream.
/// @param {Object} opts
class WebrtcPeer  {
  String id;//=await cryptoGraphy.getRandomAsciiString(8);
  // 主叫方
  bool initiator=false;
  //如果是主叫方，则设置通道名，随机字符串
  String? channelName;//=await cryptoGraphy.getRandomAsciiString(20);
  dynamic channelConfig={};
  bool channelNegotiated=false;

  dynamic config= {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:global.stun.twilio.com:3478'
        ]
      }
    ],
    'sdpSemantics': 'unified-plan'
  };
  dynamic offerOptions;
  dynamic answerOptions;
  dynamic sdpTransform;
  List<dynamic> streams;
  bool trickle =true;
  bool allowHalfTrickle=false;
  int iceCompleteTimeout=5*1000;
  dynamic extension;
  bool destroyed = false;
  bool destroying = false;
  bool _connected = false;
  bool _connecting=false;
  String remoteAddress ;
  String remoteFamily ;
  String remotePort ;
  String localAddress ;
  String localFamily ;
  String localPort ;
  dynamic _wrtc;

  bool _pcReady = false;
  bool _channelReady = false;
  bool _iceComplete = false; // ice candidate trickle done (got null candidate)
  dynamic _iceCompleteTimer ; // send an offer/answer anyway after some timeout
  dynamic _channel ;
  List<dynamic> _pendingCandidates = [];

  bool _isNegotiating = false; // is this peer waiting for negotiation to complete?
  bool _firstNegotiation = true;
  bool _batchedNegotiation = false; // batch synchronous negotiations
  bool _queuedNegotiation = false; // is there a queued negotiation request?
  List<dynamic> _sendersAwaitingStable = [];
  Map _senderMap = {};
  int _closingInterval;

  List<dynamic> _remoteTracks = [];
  List<dynamic> _remoteStreams = [];

  dynamic _chunk ;
  dynamic _cb  ;
  int _interval ;
  dynamic _pc;
  WebrtcPeer () {
    try {
      this._pc = new (this._wrtc.RTCPeerConnection)(config);
    } catch (err) {
      this.destroy('ERR_PC_CONSTRUCTOR');
      return;
    }


    this._pc.oniceconnectionstatechange = () => {
      this._onIceStateChange()
    };
    this._pc.onicegatheringstatechange = () => {
      this._onIceStateChange()
    };
    this._pc.onconnectionstatechange = () => {
      this._onConnectionStateChange()
    };
    this._pc.onsignalingstatechange = () => {
      this._onSignalingStateChange()
    };
    this._pc.onicecandidate = (event) => {
      this._onIceCandidate(event)
    };

    // Other spec events, unused by this implementation:
    // - onconnectionstatechange
    // - onicecandidateerror
    // - onfingerprintfailure
    // - onnegotiationneeded

    if (initiator || channelNegotiated) {
      _setupData({
        'channel': this._pc.createDataChannel(channelName, this.channelConfig)
      });
    } else {
      _pc.ondatachannel = (event) => {
        _setupData(event);
      };
    }

    if (streams!=null) {
      streams.forEach((stream) => {
        addStream(stream)
      });
    }
    _pc.ontrack = (event) => {
      _onTrack(event)
    };

    logger.i('initial negotiation');
    this._needsNegotiation();

    this._onFinishBound = () => {
      _onFinish();
    };
    this.once('finish', this._onFinishBound);
  }

  get bufferSize {
    if (_channel!=null){
      return _channel.bufferedAmount;
    }
    return  0;
  }

  // HACK: it's possible channel.readyState is "closing" before peer.destroy() fires
  // https://bugs.chromium.org/p/chromium/issues/detail?id=882743
  get connected {
    return (this._connected && this._channel.readyState == 'open');
  }

  get address  {
    return { 'port': this.localPort, 'family': this.localFamily, 'address': this.localAddress };
  }

  //从信号服务器传回来远程的webrtcSignal信息，从signalAction回调
  signal (dynamic data) {
    if (destroying) return;
    if (destroyed) throw 'cannot signal after peer is destroyed,ERR_DESTROYED';
    if (data is String) {
      try {
        data = JsonUtil.toMap(data);
      } catch (err) {
        data = {};
      }
    }
    logger.i('signal()');

    if (data.renegotiate && this.initiator) {
      logger.i('got request to renegotiate');
      this._needsNegotiation();
    }
    if (data.transceiverRequest!=null && this.initiator) {
      logger.i('got request for transceiver');
      this.addTransceiver(data.transceiverRequest.kind, data.transceiverRequest.init);
    }
    if (data.candidate!=null) {
      if (this._pc.remoteDescription && this._pc.remoteDescription.type) {
        this._addIceCandidate(data.candidate);
      } else {
        _pendingCandidates.add(data.candidate);
      }
    }
    if (data.sdp!=null) {
      this._pc.setRemoteDescription(new (this._wrtc.RTCSessionDescription)(data))
        .then(() => {
          if (this.destroyed) return;

          this._pendingCandidates.forEach(candidate => {
            this._addIceCandidate(candidate);
          })
          this._pendingCandidates = [];

          if (this._pc.remoteDescription.type == 'offer') this._createAnswer();
        }).catch((err) => {
          this.destroy(errCode(err, 'ERR_SET_REMOTE_DESCRIPTION'))
        });
    }
    if (data.sdp==null && data.candidate==null && data.renegotiate==null && data.transceiverRequest==null) {
      this.destroy(errCode(new Error('signal() called with invalid signal data'), 'ERR_SIGNALING'));
    }
  }

  _addIceCandidate (dynamic candidate) {
    const iceCandidateObj = new this._wrtc.RTCIceCandidate(candidate);
    this._pc.addIceCandidate(iceCandidateObj)
      .catch((err) => {
        if (iceCandidateObj.address==null || iceCandidateObj.address.endsWith('.local')) {
          warn('Ignoring unsupported ICE candidate.')
        } else {
          logger.e(err)
          //this.destroy(errCode(err, 'ERR_ADD_ICE_CANDIDATE'))
        }
      });
  }

  /// Send text/binary data to the remote peer.
  /// @param {ArrayBufferView|ArrayBuffer|Buffer|string|Blob} chunk
  send (dynamic chunk) {
    if (destroying) return;
    if (destroyed) throw 'cannot send after peer is destroyed,ERR_DESTROYED';
    _channel.send(chunk);
  }

  /// Add a Transceiver to the connection.
  /// @param {String} kind
  /// @param {Object} init
  addTransceiver (kind, init) {
    if (destroying) return;
    if (destroyed) throw 'cannot addTransceiver after peer is destroyed,ERR_DESTROYED';
    logger.i('addTransceiver()');

    if (initiator) {
      try {
        if(this._pc.addTransceiver){
          this._pc.addTransceiver(kind, init);
        }
        this._needsNegotiation();
      } catch (err) {
        logger.e(err);
        //this.destroy(errCode(err, 'ERR_ADD_TRANSCEIVER'))
      }
    } else {
      if(!this._pc.remoteStreams!=null || JsonUtil.toJsonString(this._pc.remoteStreams) == "{}"){
        this.emit('signal', { // request initiator to renegotiate
          'type': 'transceiverRequest',
          'transceiverRequest': { kind, init }
        });
      }
    }
  }

  /// Add a MediaStream to the connection.
  /// @param {MediaStream} stream
  addStream (stream) {
    if (this.destroying) return;
    if (this.destroyed) throw 'cannot addStream after peer is destroyed,ERR_DESTROYED';
    logger.i('addStream()');

    stream.getTracks().forEach((track) => {
      this.addTrack(track, stream);
    });
  }

  /// Add a MediaStreamTrack to the connection.
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  addTrack (track, stream) {
    if (destroying) return;
    if (destroyed) throw 'cannot addTrack after peer is destroyed,ERR_DESTROYED';
    logger.i('addTrack()');

    var submap = this._senderMap[track];
    if (submap==null) {
      submap={}; // nested Maps map [track, stream] to sender
    }
    var sender = submap[stream];
    if (sender==null) {
      sender = this._pc.addTrack(track, stream);
      submap.set(stream, sender);
      this._senderMap[track]= submap;
      this._needsNegotiation();
    } else if (sender.removed) {
      throw errCode(new Error('Track has been removed. You should enable/disable tracks that you want to re-add.'), 'ERR_SENDER_REMOVED')
    } else {
      throw errCode(new Error('Track has already been added to that stream.'), 'ERR_SENDER_ALREADY_ADDED')
    }
  }

  /// Replace a MediaStreamTrack by another in the connection.
  /// @param {MediaStreamTrack} oldTrack
  /// @param {MediaStreamTrack} newTrack
  /// @param {MediaStream} stream
  replaceTrack (oldTrack, newTrack, stream) {
    if (destroying) return;
    if (destroyed) throw 'cannot replaceTrack after peer is destroyed,ERR_DESTROYED';
    logger.i('replaceTrack()');

    var submap = _senderMap[oldTrack];
    var sender = submap!=null ? submap[stream] : null;
    if (sender==null) {
      throw 'Cannot replace track that was never added.,ERR_TRACK_NOT_ADDED';
    }
    if (newTrack!=null) this._senderMap[newTrack]= submap;

    if (sender.replaceTrack != null) {
      sender.replaceTrack(newTrack);
    } else {
      this.destroy(errCode(new Error('replaceTrack is not supported in this browser'), 'ERR_UNSUPPORTED_REPLACETRACK'))
    }
  }

  /// Remove a MediaStreamTrack from the connection.
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  removeTrack (track, stream) {
    if (destroying) return;
    if (destroyed) throw 'cannot removeTrack after peer is destroyed,ERR_DESTROYED';
    logger.i('removeSender()');

    var submap = this._senderMap[track];
    var sender = submap!=null ? submap[stream] : null;
    if (sender==null) {
      throw 'Cannot remove track that was never added.,ERR_TRACK_NOT_ADDED';
    }
    try {
      sender.removed = true;
      this._pc.removeTrack(sender);
    } catch (err) {
      if (err.name == 'NS_ERROR_UNEXPECTED') {
        this._sendersAwaitingStable.add(sender); // HACK: Firefox must wait until (signalingState === stable) https://bugzilla.mozilla.org/show_bug.cgi?id=1133874
      } else {
        this.destroy(errCode(err, 'ERR_REMOVE_TRACK'));
      }
    }
    this._needsNegotiation();
  }

  /// Remove a MediaStream from the connection.
  /// @param {MediaStream} stream
  removeStream (stream) {
    if (destroying) return;
    if (destroyed) throw 'cannot removeStream after peer is destroyed,ERR_DESTROYED';
    logger.i('removeSenders()');

    stream.getTracks().forEach((track) => {
      this.removeTrack(track, stream);
    });
  }

  _needsNegotiation () {
    logger.i('_needsNegotiation');
    if (this._batchedNegotiation) return; // batch synchronous renegotiations
    this._batchedNegotiation = true;
    queueMicrotask(() => {
      _batchedNegotiation = false;
      if (this.initiator || !this._firstNegotiation) {
        this._debug('starting batched negotiation');
        this.negotiate();
      } else {
        this._debug('non-initiator initial negotiation request discarded');
      }
      this._firstNegotiation = false;
    });
  }

  negotiate () {
    if (this.destroying) return;
    if (this.destroyed) throw 'cannot negotiate after peer is destroyed,ERR_DESTROYED';

    if (this.initiator) {
      if (this._isNegotiating) {
        this._queuedNegotiation = true;
        this._debug('already negotiating, queueing');
      } else {
        this._debug('start negotiation');
        Future.delayed(Duration(seconds: 0),() => { // HACK: Chrome crashes if we immediately call createOffer
          this._createOffer();
        });
      }
    } else {
      if (this._isNegotiating) {
        this._queuedNegotiation = true;
        this._debug('already negotiating, queueing');
      } else {
        this._debug('requesting negotiation from initiator');
        this.emit('signal', { // request initiator to renegotiate
          'type': 'renegotiate',
          'renegotiate': true
        });
      }
    }
    this._isNegotiating = true;
  }

  // TODO: Delete this method once readable-stream is updated to contain a default
  // implementation of destroy() that automatically calls _destroy()
  // See: https://github.com/nodejs/readable-stream/issues/283
  destroy (String err) {
    this._destroy(err, () => {});
  }

  _destroy (String err, Function callback) {
    if (this.destroyed || this.destroying) return;
    this.destroying = true;

    this._debug('destroying (error: $err)');

    queueMicrotask(() => { // allow events concurrent with the call to _destroy() to fire (see #692)
      this.destroyed = true;
      this.destroying = false;

      this._debug('destroy (error: $err)');

      this.readable = this.writable = false;

      if (!this._readableState.ended) this.push(null);
      if (!this._writableState.finished) this.end();

      this._connected = false;
      this._pcReady = false;
      this._channelReady = false;
      this._remoteTracks = null;
      this._remoteStreams = null;
      this._senderMap = null;

      clearInterval(this._closingInterval);
      this._closingInterval = null;

      clearInterval(this._interval);
      this._interval = null;
      this._chunk = null;
      this._cb = null;

      if (this._onFinishBound) this.removeListener('finish', this._onFinishBound);
      this._onFinishBound = null;

      if (this._channel) {
        try {
          this._channel.close();
        } catch (err) {}

        // allow events concurrent with destruction to be handled
        this._channel.onmessage = null;
        this._channel.onopen = null;
        this._channel.onclose = null;
        this._channel.onerror = null;
      }
      if (this._pc) {
        try {
          this._pc.close();
        } catch (err) {}

        // allow events concurrent with destruction to be handled
        this._pc.oniceconnectionstatechange = null;
        this._pc.onicegatheringstatechange = null;
        this._pc.onsignalingstatechange = null;
        this._pc.onicecandidate = null;
        this._pc.ontrack = null;
        this._pc.ondatachannel = null;
      }
      this._pc = null;
      this._channel = null;

      if (err) this.emit('error', err);
      this.emit('close');
    callback();
    });
  }

  _setupData (event) {
    if (!event.channel) {
      // In some situations `pc.createDataChannel()` returns `undefined` (in wrtc),
      // which is invalid behavior. Handle it gracefully.
      // See: https://github.com/feross/simple-peer/issues/163
      return this.destroy('Data channel event is missing `channel` property,ERR_DATA_CHANNEL');
    }

    this._channel = event.channel;
    this._channel.binaryType = 'arraybuffer';

    if (this._channel.bufferedAmountLowThreshold is int) {
      this._channel.bufferedAmountLowThreshold = maxBufferSize;
    }

    this.channelName = this._channel.label;

    this._channel.onmessage = (event) => {
      this._onChannelMessage(event);
    };
    this._channel.onbufferedamountlow = () => {
      this._onChannelBufferedAmountLow()
    };
    this._channel.onopen = () => {
      this._onChannelOpen()
    };
    this._channel.onclose = () => {
      this._onChannelClose()
    };
    this._channel.onerror = (err) => {
      //this.destroy(errCode(err, 'ERR_DATA_CHANNEL'))
    };

    // HACK: Chrome will sometimes get stuck in readyState "closing", let's check for this condition
    // https://bugs.chromium.org/p/chromium/issues/detail?id=882743
    bool isClosing = false;
    this._closingInterval = setInterval(() => { // No "onclosing" event
      if (this._channel && this._channel.readyState == 'closing') {
        if (isClosing) this._onChannelClose() ;// closing timed out: equivalent to onclose firing
        isClosing = true;
      } else {
        isClosing = false;
      }
    }, channelClosingTimeout);
  }

  _read () {}

  _write (chunk, encoding, cb) {
    if (this.destroyed) return cb(errCode(new Error('cannot write after peer is destroyed'), 'ERR_DATA_CHANNEL'));

    if (this._connected) {
      try {
        this.send(chunk);
      } catch (err) {
        return this.destroy(errCode(err, 'ERR_DATA_CHANNEL'));
      }
      if (this._channel.bufferedAmount > maxBufferSize) {
        this._debug('start backpressure: bufferedAmount $this._channel.bufferedAmount');
        this._cb = cb;
      } else {
        cb(null);
      }
    } else {
      this._debug('write before connect')
      this._chunk = chunk;
      this._cb = cb;
    }
  }

  // When stream finishes writing, close socket. Half open connections are not
  // supported.
  _onFinish () {
    if (this.destroyed) return;

    // Wait a bit before destroying so the socket flushes.
    // TODO: is there a more reliable way to accomplish this?
    const destroySoon = () => {
      setTimeout(() => this.destroy(), 1000);
    }

    if (this._connected) {
      destroySoon();
    } else {
      this.once('connect', destroySoon);
    }
  }

  _startIceCompleteTimeout () {
    if (this.destroyed) return;
    if (this._iceCompleteTimer) return;
    this._debug('started iceComplete timeout');
    this._iceCompleteTimer = setTimeout(() => {
      if (!this._iceComplete) {
        this._iceComplete = true;
        this._debug('iceComplete timeout completed');
        this.emit('iceTimeout');
        this.emit('_iceComplete');
      }
    }, this.iceCompleteTimeout);
  }

  _createOffer () {
    if (this.destroyed) return;

    this._pc.createOffer(this.offerOptions)
      .then((offer) => {
        if (this.destroyed) return;
        if (!this.trickle && !this.allowHalfTrickle) offer.sdp = filterTrickle(offer.sdp);
        offer.sdp = this.sdpTransform(offer.sdp);

        const sendOffer = () => {
          if (this.destroyed) return;
          const signal = this._pc.localDescription || offer;
          this._debug('signal');
          this.emit('signal', {
            'type': signal.type,
            'sdp': signal.sdp,
            'extension' : this.extension;
          })
        }

        const onSuccess = () => {
          this._debug('createOffer success');
          if (this.destroyed) return;
          if (this.trickle || this._iceComplete) sendOffer()
          else this.once('_iceComplete', sendOffer) // wait for candidates
        }

        const onError = (err) => {
          this.destroy(errCode(err, 'ERR_SET_LOCAL_DESCRIPTION'));
        }

        this._pc.setLocalDescription(offer)
          .then(onSuccess)
          .catch(onError)
      })
      .catch((err) => {
        this.destroy(errCode(err, 'ERR_CREATE_OFFER'));
      })
  }

  _requestMissingTransceivers () {
    if (this._pc.getTransceivers) {
      this._pc.getTransceivers().forEach((transceiver) => {
        if (!transceiver.mid && transceiver.sender && transceiver.sender.track && !transceiver.requested) {
          transceiver.requested = true // HACK: Safari returns negotiated transceivers with a null mid
          this.addTransceiver(transceiver.sender.track.kind);
        }
      });
    }
  }

  _createAnswer () {
    if (this.destroyed) return;

    this._pc.createAnswer(this.answerOptions)
      .then((answer) => {
        if (this.destroyed) return;
        if (!this.trickle && !this.allowHalfTrickle) answer.sdp = filterTrickle(answer.sdp);
        answer.sdp = this.sdpTransform(answer.sdp);

        const sendAnswer = () => {
          if (this.destroyed) return
          const signal = this._pc.localDescription || answer
          this._debug('signal')
          this.emit('signal', {
            type: signal.type,
            sdp: signal.sdp,
            extension: this.extension
          })
          //if (!this.initiator) this._requestMissingTransceivers() //ios unSupport
        }

        const onSuccess = () => {
          if (this.destroyed) return;
          if (this.trickle || this._iceComplete) sendAnswer()
          else this.once('_iceComplete', sendAnswer);
        }

        const onError = (err) => {
          this.destroy(errCode(err, 'ERR_SET_LOCAL_DESCRIPTION'));
        }

        this._pc.setLocalDescription(answer)
          .then(onSuccess)
          .catch(onError)
      })
      .catch((err) => {
        this.destroy(errCode(err, 'ERR_CREATE_ANSWER'));
      });
  }

  _onConnectionStateChange () {
    if (this.destroyed) return;
    if (this._pc.connectionState == 'failed') {
      this.destroy('Connection failed.ERR_CONNECTION_FAILURE');
    }
  }

  _onIceStateChange () {
    if (this.destroyed) return;
    const iceConnectionState = this._pc.iceConnectionState;
    const iceGatheringState = this._pc.iceGatheringState;

    this._debug(
      'iceStateChange (connection: $iceConnectionState) (gathering: $iceGatheringState)');
    this.emit('iceStateChange', iceConnectionState, iceGatheringState);

    if (iceConnectionState == 'connected' || iceConnectionState == 'completed') {
      this._pcReady = true;
      this._maybeReady();
    }
    if (iceConnectionState == 'failed') {
      this.destroy('Ice connection failed.,ERR_ICE_CONNECTION_FAILURE');
    }
    if (iceConnectionState == 'closed') {
      this.destroy('Ice connection closed.,ERR_ICE_CONNECTION_CLOSED');
    }
  }

  getStats (cb) {
    // statreports can come with a value array instead of properties
    var flattenValues = (report) => {
      if (report.values is List) {
        report.values.forEach((value) => {
          Object.assign(report, value)
        })
      }
      return report;
    };

    // Promise-based getStats() (standard)
    if (this._pc.getStats.length == 0) {
      this._pc.getStats()
        .then((res) => {
          List<dynamic> reports = [];
          res.forEach(report => {
            reports.push(flattenValues(report))
          });
          cb(null, reports);
        }, (err) => cb(err));

      // Single-parameter callback-based getStats() (non-standard)
    } else if (this._pc.getStats.length > 0) {
      this._pc.getStats((res) => {
        // If we destroy connection in `connect` callback this code might happen to run when actual connection is already closed
        if (this.destroyed) return;

        const reports = []
        res.result().forEach((result) => {
          var report = {};
          result.names().forEach(name => {
            report[name] = result.stat(name);
          })
          report.id = result.id;
          report.type = result.type;
          report.timestamp = result.timestamp;
          reports.push(flattenValues(report));
        })
        cb(null, reports);
      }, (err) => cb(err));

      // Unknown browser, skip getStats() since it's anyone's guess which style of
      // getStats() they implement.
    } else {
      cb(null, []);
    }
  }

  _maybeReady () {
    this._debug('maybeReady pc $this._pcReady channel $this._channelReady');
    if (this._connected || this._connecting || !this._pcReady || !this._channelReady) return;

    this._connecting = true;

    // HACK: We can't rely on order here, for details see https://github.com/js-platform/node-webrtc/issues/339
    var findCandidatePair = () => {
      if (this.destroyed) return;

      this.getStats((err, items) => {
        if (this.destroyed) return;

        // Treat getStats error as non-fatal. It's not essential.
        if (err!=null) items = [];

        const remoteCandidates = {};
        const localCandidates = {};
        const candidatePairs = {};
        var foundSelectedCandidatePair = false;

        items.forEach(item => {
          // TODO: Once all browsers support the hyphenated stats report types, remove
          // the non-hypenated ones
          if (item.type == 'remotecandidate' || item.type == 'remote-candidate') {
            remoteCandidates[item.id] = item
          }
          if (item.type == 'localcandidate' || item.type == 'local-candidate') {
            localCandidates[item.id] = item
          }
          if (item.type == 'candidatepair' || item.type == 'candidate-pair') {
            candidatePairs[item.id] = item
          }
        });

        var setSelectedCandidatePair = selectedCandidatePair => {
          foundSelectedCandidatePair = true;

          var local = localCandidates[selectedCandidatePair.localCandidateId];

          if (local && (local.ip || local.address)) {
            // Spec
            this.localAddress = local.ip || local.address;
            this.localPort = Number(local.port);
          } else if (local && local.ipAddress) {
            // Firefox
            this.localAddress = local.ipAddress;
            this.localPort = Number(local.portNumber);
          } else if (selectedCandidatePair.googLocalAddress is String) {
            // TODO: remove this once Chrome 58 is released
            local = selectedCandidatePair.googLocalAddress.split(':');
            this.localAddress = local[0];
            this.localPort = Number(local[1]);
          }
          if (this.localAddress==null) {
            this.localFamily = this.localAddress.includes(':') ? 'IPv6' : 'IPv4';
          }

          var remote = remoteCandidates[selectedCandidatePair.remoteCandidateId];

          if (remote && (remote.ip || remote.address)) {
            // Spec
            this.remoteAddress = remote.ip || remote.address;
            this.remotePort = Number(remote.port);
          } else if (remote && remote.ipAddress) {
            // Firefox
            this.remoteAddress = remote.ipAddress;
            this.remotePort = Number(remote.portNumber);
          } else if (selectedCandidatePair.googRemoteAddress is String) {
            // TODO: remove this once Chrome 58 is released
            remote = selectedCandidatePair.googRemoteAddress.split(':');
            this.remoteAddress = remote[0];
            this.remotePort = Number(remote[1]);
          }
          if (this.remoteAddress!=null) {
            this.remoteFamily = this.remoteAddress.includes(':') ? 'IPv6' : 'IPv4';
          }

          this._debug(
            'connect local: %s:%s remote: %s:%s',
            this.localAddress,
            this.localPort,
            this.remoteAddress,
            this.remotePort
          );
        }

        items.forEach(item => {
          // Spec-compliant
          if (item.type == 'transport' && item.selectedCandidatePairId) {
            setSelectedCandidatePair(candidatePairs[item.selectedCandidatePairId])
          }

          // Old implementations
          if (
            (item.type == 'googCandidatePair') ||
            ((item.type == 'candidatepair' || item.type == 'candidate-pair') && item.selected)
          ) {
            setSelectedCandidatePair(item);
          }
        })

        // Ignore candidate pair selection in browsers like Safari 11 that do not have any local or remote candidates
        // But wait until at least 1 candidate pair is available
        if (!foundSelectedCandidatePair && (!Object.keys(candidatePairs).length || Object.keys(localCandidates).length)) {
          setTimeout(findCandidatePair, 100)
          return;
        } else {
          this._connecting = false;
          this._connected = true;
        }

        if (this._chunk) {
          try {
            this.send(this._chunk);
          } catch (err) {
            return this.destroy(errCode(err, 'ERR_DATA_CHANNEL'));
          }
          this._chunk = null;
          this._debug('sent chunk from "write before connect"');

          const cb = this._cb;
          this._cb = null;
          cb(null)
        }

        // If `bufferedAmountLowThreshold` and 'onbufferedamountlow' are unsupported,
        // fallback to using setInterval to implement backpressure.
        if (typeof this._channel.bufferedAmountLowThreshold != 'number') {
          this._interval = setInterval(() => this._onInterval(), 150);
          if (this._interval.unref) this._interval.unref();
        }

        this._debug('connect');
        this.emit('connect');
      })
    }
    findCandidatePair();
  }

  _onInterval () {
    if (!this._cb || !this._channel || this._channel.bufferedAmount > maxBufferSize) {
      return;
    }
    this._onChannelBufferedAmountLow();
  }

  _onSignalingStateChange () {
    if (this.destroyed) return;

    if (this._pc.signalingState == 'stable') {
      this._isNegotiating = false;

      // HACK: Firefox doesn't yet support removing tracks when signalingState !== 'stable'
      this._debug('flushing sender queue', this._sendersAwaitingStable);
      this._sendersAwaitingStable.forEach((sender) => {
        this._pc.removeTrack(sender);
        this._queuedNegotiation = true;
      });
      this._sendersAwaitingStable = [];

      if (this._queuedNegotiation) {
        this._debug('flushing negotiation queue');
        this._queuedNegotiation = false;
        this._needsNegotiation(); // negotiate again
      } else {
        this._debug('negotiated');
        this.emit('negotiated');
      }
    }

    this._debug('signalingStateChange %s', this._pc.signalingState);
    this.emit('signalingStateChange', this._pc.signalingState);
  }

  _onIceCandidate (event) {
    if (this.destroyed) return;
    if (event.candidate && this.trickle) {
      this.emit('signal', {
        'type': 'candidate',
        'candidate': {
          'candidate': event.candidate.candidate,
          'sdpMLineIndex': event.candidate.sdpMLineIndex,
          'sdpMid': event.candidate.sdpMid
        }
      });
    } else if (!event.candidate && !this._iceComplete) {
      this._iceComplete = true;
      this.emit('_iceComplete');
    }
    // as soon as we've received one valid candidate start timeout
    if (event.candidate) {
      this._startIceCompleteTimeout();
    }
  }

  _onChannelMessage (event) {
    if (this.destroyed) return;
    var data = event.data;
    if (data instanceof ArrayBuffer) data = Buffer.from(data)
    this.push(data);
  }

  _onChannelBufferedAmountLow () {
    if (this.destroyed || !this._cb) return;
    this._debug('ending backpressure: bufferedAmount %d', this._channel.bufferedAmount);
    const cb = this._cb;
    this._cb = null;
    cb(null);
  }

  _onChannelOpen () {
    if (this._connected || this.destroyed) return;
    this._debug('on channel open');
    this._channelReady = true;
    this._maybeReady();
  }

  _onChannelClose () {
    if (this.destroyed) return;
    this._debug('on channel close');
    this.destroy();
  }

  _onTrack (event) {
    if (this.destroyed) return;

    event.streams.forEach(eventStream => {
      this._debug('on track');
      this.emit('track', event.track, eventStream);

      this._remoteTracks.add({
        'track': event.track,
        'stream': eventStream
      })

      if (this._remoteStreams.some(remoteStream => {
        return remoteStream.id == eventStream.id
      })) return; // Only fire one 'stream' event, even though there may be multiple tracks per stream

      this._remoteStreams.push(eventStream);
      queueMicrotask(() => {
        this._debug('on stream');
        this.emit('stream', eventStream); // ensure all tracks have been added
      })
    });
  }

  _debug (String msg) {
    logger.i(msg);
  }
}
