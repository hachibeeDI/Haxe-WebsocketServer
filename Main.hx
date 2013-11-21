package ;

import neko.net.websocket.WebSocketServer;


class Main {
    public static function main() {
        trace("start server");
        var webs = new WebSocketServer();
        webs.run("localhost", 1234);
        trace("server halt");
    }
}
