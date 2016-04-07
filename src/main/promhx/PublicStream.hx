
package promhx;

@:expose
class PublicStream<T> extends Stream<T> {
    public function new(?def : Deferred<T>#if debug ,?pos:haxe.PosInfos #end){
        super(def #if debug ,pos #end);
    }
    inline public function resolve(val:T) this.handleResolve(val);
    inline public function throwError(e:Dynamic) handleError(e);
    inline public function update(val:T) this.handleResolve(val);
    inline public static function publicstream<T>(val:T #if debug ,?pos:haxe.PosInfos #end){
        var ps = new PublicStream(null#if debug ,pos #end);
        ps.resolve(val);
        return ps;
    }
}
