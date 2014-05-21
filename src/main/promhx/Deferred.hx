package promhx;

@:expose
class Deferred<T> {
    var _update : Array<{func: T->Dynamic, error: Dynamic->Void}>;

    public function new(){
        this._update = [];
    }

    /**
      The public write interface
     **/
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

    /**
      Register callbacks directly to a Deferred instance. 
     **/
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
