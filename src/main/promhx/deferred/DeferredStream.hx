package promhx.deferred;
class DeferredStream<T> extends Deferred<T> {
    public var boundStream : Stream<T>;
    public function new() {
        super();
        boundStream = new Stream<T>(this);
    }
}
