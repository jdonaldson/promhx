package promhx.haxe.http;
class Cancel {
    public var reason(default, null) : Dynamic;
    public function new(reason:Dynamic){
        this.reason = reason;
    }
}
