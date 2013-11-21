package sys.net.websocket;


class OpcodeUtils {

    public static function  equals (code: OPCODE, arg: Int) {
        return to_byte(code) == arg;
    }

    public static function to_byte(code: OPCODE): Int {
        return switch (code) {
            case Continuation: 0x00;
            case Text: 0x01;
            case Binary: 0x02;
            case Close: 0x08;
            case Ping: 0x09;
            case Pong: 0x0A;
        }
    }

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
