package sys.net.websocket;

import haxe.crypto.Sha1;
import haxe.crypto.BaseCode;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.BytesInput;
#if neko
    import neko.net.ThreadServer;
#else
    typedef ThreadServer = {
        function sendData(Socket, String): Void;
    }
#end

import sys.net.websocket.api.Client;
import sys.net.websocket.api.Message;
import sys.net.websocket.OPCODE;
using sys.net.websocket.OpcodeUtils;

using StringTools;
using Lambda;


abstract Response(String) to String {
    static inline var GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

    inline function new(key: String)
        this = key;

    @:from static public inline function from_request(r: Request) {
        var key = decode_key_data(r.key);
        return
            new Response(
                'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ${key}\r\n\r\n'
            );
    }

    static function decode_key_data(sec_websocket_key: String): String {
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
}


class Request {
    public var key(default, null): String;
    public var host(default, null): String;

    public function new(msg: String) {
        var v = parse_header(msg);
        this.key = v.key;
        this.host = v.host;
    }

    static function parse_header(msg: String): {host: String, key: String} {
        var maybe_headers = msg.split("\r\n");
        var hostname: String = '';
        var key: String = '';
        if (maybe_headers.length > 7) {
            // TODO: more stable implementation
            for (l in maybe_headers) {
                switch (l.split(" ")) {
                    case ["Origin:", _hostname]: hostname = _hostname;
                    case ["Sec-WebSocket-Key:", _key]: key = _key;
                    case v: 'null';
                }
            }
            return {host: hostname, key: key}
        } else { throw "unsuported request header!"; }
    }
}


class Protocol {

    public static function parse_request(msg: String): Request {
        return new Request(msg);
    }

    public static function send_hand_shake(
            server: ThreadServer<Client, Message>,
            soc: Socket,
            req: Request): Void {
        var res: Response = req;
        server.sendData(soc, res);
    }

    /**
      * via: http://d.hatena.ne.jp/gtk2k/20120203/1328275041
     */
    public static function decode_message(buf: Bytes, pos: Int, len: Int): OPCODE {
        var datas = new BytesInput(buf, pos, len);
        var fin_rsv_opcode = datas.readByte();
        // 10000000 & 10000000 == 10000000  一番左端のビットが立っているかどうかの計算
        var fin: Bool = (fin_rsv_opcode & 0x80) == 0x80;
        var opcode = fin_rsv_opcode & 0x0f;
        if (opcode == OpcodeUtils.Text) {
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
            return OPCODE.Text(result.toString());
        } else {
            throw "NotImplemented 工事中";
        }
    }

    /**
      * this method is for servers, so FrameMasking will not define.
      * @param data: TODO: define abstract data type from String to Byte or Int
     */
    public static function encode_message(opcode: OPCODE): BytesOutput {
        return switch (opcode) {
            case Text(s): return encode_text(s);
            case _: throw "NotImplemented 工事中";
        }
    }

    static function encode_text(data: String): BytesOutput {
        var buf = new BytesOutput();
        // 1|0|0|0 | opcode
        buf.writeByte(0x80 | OpcodeUtils.Text);

        var data_length = data.length;
        var payload_len = switch (data_length) {
                case i if (i <= 125): i;
                case i if (i <= 65535): 126;
                case i: 127;
            }
        buf.writeByte(0x00 | payload_len);  // ignore Mask

        if (payload_len == 126) {
            // data len interpret 2 bytes
            buf.writeByte((data_length >> 8) & 0xFF);
            buf.writeByte(data_length & 0xFF);
        }
        else if (payload_len == 127) {
            // data len interpret 4 bytes
            buf.writeByte((data_length >> 24) & 0xFF);
            buf.writeByte((data_length >> 16) & 0xFF);
            buf.writeByte((data_length >> 8) & 0xFF);
            buf.writeByte(data_length & 0xFF);
        }
        buf.writeString(data);
        return buf;
    }
}
