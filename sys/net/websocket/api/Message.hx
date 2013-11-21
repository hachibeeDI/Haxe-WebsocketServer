package sys.net.websocket.api;


enum MessageType {
    HandShake(v: String);
    Content(v: String);
}

typedef Message = {
  var content : MessageType;
}
