package promhx;

class Deferred<T> {
    var _update : Array<{func: T->Dynamic, error: Dynamic->Void}>;
    public function new(){
        this._update = [];
    }
    public function resolve(val:T){
        for (u in _update) {
            if (u.error != null){
                try u.func(val)
                catch(e:Dynamic) {
                }
            } else {
                u.func(val);
            }
        }
    }

    public function then<X>(func : T->X, ?error : Dynamic->Void){
        _update.push({func : func, error: error});
    }

    /**
      Returns a promise based on the current deferred instance
     **/
    public function promise(){
        return new Promise(this);
    }
    /**
      Returns a stream based on the current deferred instance
     **/
    public function stream(){
        return new Stream(this);
    }
}
