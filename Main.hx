package ;

import haxe.crypto.Sha1;
import haxe.crypto.BaseCode;
import sys.net.Socket;
import neko.Lib;
import neko.net.ThreadServer;
import neko.net.ServerLoop;
import haxe.ds.Option;
import haxe.io.Bytes;
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


class WebSocketProcol extends haxe.remoting.SocketProtocol {

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
            if (!c.is_hand_shaked && c.key != null) {
                var decoded_key = WebSocket.decode(c.key);
                // WebSocket.send_hand_shake(c.soc, decoded_key);
                this.sendData(c.soc, WebSocket.get_hand_shake(decoded_key));
                c.is_hand_shaked = true;
                trace('!! shake handed !!');
            }
        }
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
}


