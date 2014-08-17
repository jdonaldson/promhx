package promhx.deferred;
class DeferredPromise<T> extends Deferred<T> {
    public var boundPromise : Promise<T>;
    public function new() {
        super();
        boundPromise = new Promise<T>(this);
    }
}
