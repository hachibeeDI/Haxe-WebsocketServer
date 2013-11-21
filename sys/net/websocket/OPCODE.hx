package sys.net.websocket;

/**
  * 
  * - opcodeについて
  * %x0 は継続フレームを表す
  * %x1 はテキストフレームを表す
  * %x2 はバイナリフレームを表す
  * %x3-7 は追加の非制御フレーム用に予約済み
  * %x8 は接続の切断を表す
  * %x9 は ping を表す
  * %xA は pong を表す
  * %xB-F は追加の制御フレーム用に予約済み
 */
enum OPCODE {
    Continuation;
    Text;
    Binary;
    Close;
    Ping;
    Pong;
}
