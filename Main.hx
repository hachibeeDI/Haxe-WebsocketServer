package ;

import neko.net.websocket.WebSocketServer;


class Main {
    public static function main() {
        trace("start server");
        var webs = new WebSocketServer();
        webs.onmessage.push(
            function(client_self, msg) {
                for (c in WebSocketServer.connected_clients_) {
                    c.soc.output.write(msg);
                }
            }
        );
        webs.run("localhost", 1234);
        trace("server halt");
    }
}
