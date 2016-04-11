package promhx.deferred;
class DeferredPromise<T> extends Deferred<T> {
    public var boundPromise : Promise<T>;
    public function new(#if debug ?pos:haxe.PosInfos #end) {
        super();
        boundPromise = new Promise<T>(this #if debug ,pos #end);
    }
}
