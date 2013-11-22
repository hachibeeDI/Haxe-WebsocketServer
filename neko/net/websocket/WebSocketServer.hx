package neko.net.websocket;

import sys.net.Socket;
import neko.net.ThreadServer;
import haxe.io.Bytes;
using Lambda;

import sys.net.websocket.Protocol;
import sys.net.websocket.api.Client;
import sys.net.websocket.api.Message;
import sys.net.websocket.OPCODE;
using sys.net.websocket.OpcodeUtils;


class WebSocketServer extends ThreadServer<Client, Message> {
    public static var connected_clients_(default, null): Array<Client> = [];

    public var onmessage(default, default): Array<Client -> Bytes -> Void>;

    public function new() {
        super();
        this.onmessage = [];
    }

    /**
      *
      * TODO: can it make shake_hand on this event?
     */
    override function clientConnected(soc: Socket): Client {
        // trace("client connected...");
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
        // シェイクハンド確立部分
        if (!c.is_hand_shaked) {
            this.hand_shake(c, msg);
            return {msg: {content: HandShake(msg)}, bytes: len};
        }

        var content = Protocol.decode_message(buf, pos, len);
        trace(content);
        var msg = switch (content) {
            case Text(st): st;
            case Close(reason):
                this.stopClient(c.soc);
                reason;
            case _: throw 'unsupported opcode';
        }
        trace('============================== get end\n');
        return {msg: {content: Content(msg)}, bytes: len};
    }

    override function clientMessage(c: Client, msg: Message): Void {
        switch (msg.content) {
            case Content(s):
                var _msg = Protocol.encode_message(OPCODE.Text(s))
                               .getBytes();
                if (this.onmessage.length == 1) {
                    this.onmessage[0](c, _msg);
                } else if (this.onmessage.length != 0) {
                    this.onmessage.iter(function(f) { f(c, _msg); });
                }
            case _: 'null';
        }
    }

    override function clientDisconnected(c: Client): Void {
        trace(c.id + " is disconnected.");
    }

    function hand_shake(c: Client, msg: String) {
        var req = Protocol.parse_request(msg);
        // WebSocket.send_hand_shake(c.soc, decoded_key);
        Protocol.send_hand_shake(this, c.soc, req);
        c.is_hand_shaked = true;
        c.host = req.host;

        connected_clients_.push(c);
    }
}
