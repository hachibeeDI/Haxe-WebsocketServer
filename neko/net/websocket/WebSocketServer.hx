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
            case Text(st): "null";
            case Close(reason):
                var _sock = c.soc;
                // response Close frame
                _sock.output.write(Protocol.encode_message(content).getBytes());
                // shutdown only write channel before close socket
                _sock.shutdown(false, true);
                this.stopClient(_sock);
                reason;
            case Ping(s):
                this.send_pong(c.soc, s);  // TODO: may have to define default event?
            case Pong(s):
                trace("receive pong frame");  // TODO: kick event

            case _: throw 'unsupported opcode';
        }
        trace('============================== get end\n');
        return {msg: {content: Content(content)}, bytes: len};
    }

    override function clientMessage(c: Client, msg: Message): Void {
        switch (msg.content) {
            case Content(op):
                switch (op) {
                    case Close(reason): "null";
                    case Text(v):
                        var _msg = Protocol.encode_message(op)
                                       .getBytes();
                        if (this.onmessage.length == 1) {
                            this.onmessage[0](c, _msg);
                        } else if (this.onmessage.length != 0) {
                            this.onmessage.iter(function(f) { f(c, _msg); });
                        }
                    case _: throw "unsuported opcode";
                }
            case _: 'null';
        }
    }

    override function clientDisconnected(c: Client): Void {
        WebSocketServer.connected_clients_.remove(c);

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

    public function broad_cast(msg: Bytes, ?self: Client): Void {
        var targets = if (self == null) WebSocketServer.connected_clients_
                      else WebSocketServer.connected_clients_.filter(function(c) { return c.id != self.id; });
        targets.iter(
            function(c) {
                c.soc.output.write(msg);
            }
        );
    }

    /**
      * Pong frame should have same application frame as received Ping's application frame
     */
    public function send_pong(s: Socket, ping_content: String) {
        s.output.write(
                Protocol.encode_message(
                    OPCODE.Pong(ping_content))
                .getBytes());

    }

    /**
     */
    public function send_ping(s: Socket, content: String) {
        s.output.write(
                Protocol.encode_message(
                    OPCODE.Ping(content))
                .getBytes());

    }
}
