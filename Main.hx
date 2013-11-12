package ;

import haxe.crypto.Sha1;
import haxe.crypto.BaseCode;
import sys.net.Socket;
import neko.Lib;
import neko.net.ThreadServer;
import neko.net.ServerLoop;
import haxe.ds.Option;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import neko.vm.Deque;


using StringTools;
using Lambda;

using SocketMixin;
using OptionMixin;


class Main {

    public static function main() {
        trace("start server");
        var webs = new WebSocketServer();
        webs.run("localhost", 1234);
        trace("server halt");
    }
}


class WebSocket {

    static inline var GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";


    public static function decode(sec_websocket_key: String): String {
        var holder = Sha1.encode(sec_websocket_key.trim() + GUID);
        var data = "";
        for (i in 0...Std.int(holder.length / 2)) {
            data += String.fromCharCode(Std.parseInt("0x" + holder.substr(i * 2, 2)));
        }

        var suffix = switch (data.length % 3) {
            case 2: "=";
            case 1: "==";
            default: "";
        };
        return BaseCode.encode(data,  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/") + suffix;
    }

    /**
      * @param sec_websocket_key
      *
     */
    public static function get_hand_shake(sec_websocket_key: String): String
    {
        var s = 'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ${sec_websocket_key}\r\n\r\n';
        return s;
        // socket
        //     .output
        //     .writeString(s);
        // trace("send hand shake!!!!!!!!!!!");
    }
}



typedef Client = {
    var id: Int;
    var soc: Socket;
    var host: String;
    var key: String;
    var is_hand_shaked: Bool;
}

typedef Message = {
  var str : String;
}


class WebSocketServer extends ThreadServer<Client, Message> {

    /**
      *
        1 GET /chat HTTP/1.1
        2 Host: server.example.com
        3 Upgrade: websocket
        4 Connection: Upgrade
        5 Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
        6 Origin: http://example.com
        7 Sec-WebSocket-Protocol: chat, superchat
        8 Sec-WebSocket-Version: 13
     */
    override function clientConnected(soc: Socket): Client {
        trace("client connected...");
        var m_trace = function(m) { switch (m) {case Some(m): trace(m); case _: trace("failed!");}; }
        return {
            id: Std.random(100),
            soc: soc,
            host: "",
            key: null,
            is_hand_shaked: false
        };
    }

    override function readClientMessage(c: Client, buf: Bytes, pos: Int, len: Int): { msg: Message, bytes: Int } {
        var msg: String = buf.readString(pos, len);
        trace('get ============================== ');
        trace("len = " + Std.string(len) + " id = " + c.id);
        trace(msg);
        // シェイクハンド確立部分
        if (!c.is_hand_shaked) {
            this.hand_shake(c, msg);
            return {msg: {str: msg}, bytes: len};
        }
        var content = decode_message(buf, pos, len);
        trace(content);
        trace('============================== get end\n');
        return {msg: {str: msg}, bytes: len};
    }

    override function clientMessage(c: Client, msg: Message): Void {
        // trace('${c.id} connected');
        // trace("received ========== \n");
        // trace(c.id + " sent: " + msg.str);
        // trace("========== received  \n");
    }

    override function clientDisconnected(c: Client): Void {
        trace(c.id + " is disconnected.");
    }

    function hand_shake(c: Client, msg: String) {
        var maybe_headers = msg.split("\r\n");
        if (maybe_headers.length > 5) {
            for (l in maybe_headers) {
                switch (l.split(" ")) {
                    case ["Origin:", hostname]: c.host = hostname;
                    case ["Sec-WebSocket-Key:", key]:
                                             trace("keyget!");
                                             c.key = key;
                    case v: trace(v);
                }
            }
            if (c.key != null) {
                var decoded_key = WebSocket.decode(c.key);
                // WebSocket.send_hand_shake(c.soc, decoded_key);
                this.sendData(c.soc, WebSocket.get_hand_shake(decoded_key));
                c.is_hand_shaked = true;
                trace('!! shake handed !!');
            } else {
                throw "Invalid header";
            }
        }

    }

    /**
      * 
      * via: http://d.hatena.ne.jp/gtk2k/20120203/1328275041
     */
    function decode_message(buf: Bytes, pos: Int, len: Int): String {
        var datas = new BytesInput(buf, pos, len);
        var fin_rsv_opcode = datas.readByte();
        // 10000000 & 10000000 == 10000000  一番左端のビットが立っているかどうかの計算
        var fin: Bool = (fin_rsv_opcode & 0x80) == 0x80;
        var opcode = fin_rsv_opcode & 0x0f;
        if (opcode == OPCODE.Text) {
            var data_header = datas.readByte();
            var is_masked: Bool = (data_header & 0x80) == 0x80;
            if (!is_masked) { throw "Client should mask datas."; }
            var decode_payload_length =
                function(len_of_byte: Int) {
                    var _payload = datas.read(len_of_byte).toHex();
                    trace('payload data = ${_payload}');
                    return Std.parseInt(_payload);
                }
            var payload_length = switch (data_header & 0x7f) {
                                  case 126: decode_payload_length(2);
                                  case 127: decode_payload_length(2);
                                  case i: i;
                              }
            var masking_key: Vector<Int> = new Vector(4);
                [for (i in 0...4) masking_key.set(i, datas.readByte())];
            // var payload_datas = datas.read(payload_length);
            var decoded_payload_data = [
                for (i in 0...payload_length)
                    // payload_datas.get(i) ^ masking_key[i % 4]
                    datas.readByte() ^ masking_key[i % 4]
                ];
            var result = new StringBuf();
            decoded_payload_data.iter(function(c) { result.addChar(c); });
            return result.toString();
            // return decoded_payload_data
            //     .map(
            //         function(_byte) {
            //             trace('decoded payload = ${_byte}');
            //             return String.fromCharCode(_byte);
            //         })
            //     .fold(
            //         function(_ch1, ch2) { return _ch1 + ch2; },
            //         "")
            //     ;
        } else {
            throw "NotImplemented 工事中";
        }
    }
}


/**
  * 
  * - opcodeについて
  * %x0 は継続フレームを表す
  * %x1 はテキストフレームを表す
  * %x2 はバイナリフレームを表す
  * %x3-7 は追加の非制御フレーム用に予約済み
  * %x8 は接続の切断を表す
  * %x9 は ping を表す
  * %xA は pong を表す
  * %xB-F は追加の制御フレーム用に予約済み
 */
class OPCODE {
    public static inline var Continuation = 0x00;
    public static inline var Text = 0x01;
    public static inline var Binary = 0x02;
    public static inline var Close = 0x08;
    public static inline var Ping = 0x09;
    public static inline var Pong = 0x0A;

    // public static inline var RECEIVED1 = 0x03;
    // public static inline var RECEIVED2 = 0x04;
    // public static inline var RECEIVED3 = 0x05;
    // public static inline var RECEIVED4 = 0x06;
    // public static inline var RECEIVED5 = 0x07;
    // B-Fも予約済み
}

