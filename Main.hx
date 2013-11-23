package ;

import neko.net.websocket.WebSocketServer;


class Main {
    public static function main() {
        trace("start server");
        var webs = new WebSocketServer();
        webs.onmessage.push(
            function(client_self, msg) {
                webs.broad_cast(msg, client_self);
            }
        );
        webs.run("localhost", 1234);
        trace("server halt");
    }
}
