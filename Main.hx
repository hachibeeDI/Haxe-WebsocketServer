package ;

import haxe.crypto.Sha1;
import haxe.crypto.BaseCode;
import sys.net.Socket;
import neko.Lib;
import neko.net.ThreadServer;
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
        trace('------------encoded sha ${data}');

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
    public static function send_hand_shake(socket: Socket, sec_websocket_key: String)
    {
        var s = 'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ${sec_websocket_key}\r\n\r\n';
        socket
            .output
            .writeString(s);
        trace(s);
        trace("send hand shake!!!!!!!!!!!");
    }
}



typedef Client = {
  var id: Int;
  var soc: Socket;
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
        return {id: Std.random(100), soc: soc};
    }

    override function readClientMessage(c: Client, buf: Bytes, pos: Int, len: Int): { msg: Message, bytes: Int } {
        // find out if there's a full message, and if so, how long it is.
        var complete = false;
        var cpos = pos;
        while (cpos < (pos+len) && !complete)
        {
          complete = (buf.get(cpos) == 46);
          cpos++;
        }

        // no full message
        if( !complete ) return null;

        // got a full message, return it
        var msg: String = buf.readString(pos, cpos-pos);
        var content = msg.split("\r\n");
        if (content.length > 10) {
            var key = content.filter(function(s) {return s.startsWith("Sec-WebSocket-Key"); });
            if (key.length >= 1) {
                var decoded_key = WebSocket.decode(key[0].split(" ")[1]);
                trace('!!!!!!!!!!!!decoded_key is ${decoded_key}');
                WebSocket.send_hand_shake(c.soc, decoded_key);
                return {msg: {str: ""}, bytes: cpos - pos};
            }
        }
        trace('get ============================== ${msg}');
        return {msg: {str: msg}, bytes: cpos - pos};
    }

    override function clientMessage(c: Client, msg: Message): Void {
        trace("received ==========");
        trace(c.id + " sent: " + msg.str);
        trace("==========received ");
    }
}


