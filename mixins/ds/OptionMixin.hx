package ;

import haxe.ds.Option;

class OptionMixin {

    public static function map<T, U>(m: Option<T>, func: T -> U): Option<U> {
        return switch (m) {
            case None: None;
            case Some(v): Some(func(v));
        }
    }
}
