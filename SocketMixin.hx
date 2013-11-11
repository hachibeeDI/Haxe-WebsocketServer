package ;

import haxe.ds.Option;
import sys.net.Socket;

class SocketMixin {
    public static function read_line_maybe(soc: Socket): Option<String> {
        var c = soc.input.readLine();
        return if(c == null) Option.None else Option.Some(c);
    }
}
