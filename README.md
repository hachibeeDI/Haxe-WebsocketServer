
[![Build Status](https://travis-ci.org/hachibeeDI/Haxe-WebsocketServer.png?branch=master)](https://travis-ci.org/hachibeeDI/Haxe-WebsocketServer)

# Haxe-WebsocketServer 0.0.0.1

Haxe製WebsocketServer。
This is websocketserver implemented by Haxe.


### Targets

neko only


## Install

`$ haxelib git nyansocket https://github.com/hachibeeDI/Haxe-WebsocketServer.git`


### Example

```
-lib nyansocket
-main Main
-neko main.n

# if you don't need server stateus trace, append the following option
#--no-traces
```

```javascript
package ;

import neko.net.websocket.WebSocketServer;


class Main {
    public static function main() {
        trace("start server");
        var webs = new WebSocketServer();
        // add event listener
        webs.onmessage.push(
            function(client_self, msg) {
                webs.broad_cast(msg, client_self);
            }
        );
        webs.run("localhost", 1234);
        trace("server halt");
    }
}
```

```html
<script>
  var ws = new WebSocket("ws://localhost:1234");
  ws.onopen = function (e) {
      console.log(e);
  };
  ws.onclose = function (e) {
      console.log(e);
  };
  ws.onmessage = function (e) {
      console.log(e);
      console.log(e.data);
  };

  ws.send('Hello Server!');
</script>
```

