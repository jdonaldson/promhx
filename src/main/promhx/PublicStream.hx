
package promhx;

@:expose
class PublicStream<T> extends Stream<T> {
    public function new(?def : Deferred<T>){
        super(def);
    }
    inline public function resolve(val:T){
        this.handleResolve(val);
    }
    inline public function update(val:T){
        this.handleResolve(val);
    }
    inline public static function publicstream<T>(val:T){
        var ps = new PublicStream();
        ps.resolve(val);
        return ps;
    }
}
