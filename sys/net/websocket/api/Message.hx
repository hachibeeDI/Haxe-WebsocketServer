package sys.net.websocket.api;


enum MessageType {
    HandShake(v: String);
    Content(v: OPCODE);
}

typedef Message = {
  var content : MessageType;
}
