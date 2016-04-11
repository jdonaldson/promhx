package promhx.deferred;
class DeferredStream<T> extends Deferred<T> {
    public var boundStream : Stream<T>;
    public function new(#if debug ?pos:haxe.PosInfos #end) {
        super();
        boundStream = new Stream<T>(this #if debug ,pos #end);
    }
}
