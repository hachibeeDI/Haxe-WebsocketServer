package sys.net.websocket.api;

import sys.net.Socket;


typedef Client = {
    var id: Int;
    var soc: Socket;
    var host: String;
    var key: String;
    var is_hand_shaked: Bool;
}
