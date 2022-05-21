"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.p2pChatAction = exports.P2pChatAction = void 0;
var message_1 = require("../message");
var baseaction_1 = require("../baseaction");
var datablock_1 = require("../datablock");
/**
在chain目录下的采用自定义protocol "/chain"的方式自己实现的功能
*/
var P2pChatAction = /** @class */ (function (_super) {
    __extends(P2pChatAction, _super);
    function P2pChatAction(msgType) {
        return _super.call(this, msgType) || this;
    }
    P2pChatAction.prototype.chat = function (connectPeerId, data, targetPeerId) {
        return __awaiter(this, void 0, void 0, function () {
            var chainMessage, response;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        chainMessage = this.prepareSend(connectPeerId, data, targetPeerId);
                        return [4 /*yield*/, this.send(chainMessage)];
                    case 1:
                        response = _a.sent();
                        if (response) {
                            return [2 /*return*/, response.Payload];
                        }
                        return [2 /*return*/, null];
                }
            });
        });
    };
    P2pChatAction.prototype.receive = function (chainMessage) {
        return __awaiter(this, void 0, message_1.ChainMessage, function () {
            var srcPeerId, payload, _dataBlock;
            var _this = this;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        chainMessage = _super.prototype.receive.call(this, chainMessage);
                        srcPeerId = chainMessage.SrcPeerId;
                        if (!(chainMessage.PayloadType === baseaction_1.PayloadType.DataBlock)) return [3 /*break*/, 2];
                        _dataBlock = chainMessage.Payload;
                        return [4 /*yield*/, datablock_1.dataBlockService.decrypt(_dataBlock)];
                    case 1:
                        _a.sent();
                        payload = _dataBlock.payload;
                        return [3 /*break*/, 3];
                    case 2:
                        payload = chainMessage.Payload;
                        _a.label = 3;
                    case 3:
                        if (chainMessage && exports.p2pChatAction.receivers) {
                            exports.p2pChatAction.receivers.forEach(function (receiver, key) { return __awaiter(_this, void 0, void 0, function () {
                                return __generator(this, function (_a) {
                                    switch (_a.label) {
                                        case 0: return [4 /*yield*/, receiver(srcPeerId, payload)];
                                        case 1:
                                            _a.sent();
                                            return [2 /*return*/];
                                    }
                                });
                            }); });
                            return [2 /*return*/, null];
                        }
                        return [2 /*return*/];
                }
            });
        });
    };
    return P2pChatAction;
}(baseaction_1.BaseAction));
exports.P2pChatAction = P2pChatAction;
exports.p2pChatAction = new P2pChatAction(message_1.MsgType.P2PCHAT);
