package promhx;
import promhx.base.AsyncBase;

@:expose
class Deferred<T> extends AsyncBase<T> {

    public function new() super();

    /**
      The public write interface
     **/
    public function resolve(val:T) handleResolve(val);

    inline public function throwError(e:Dynamic) handleError(e);

    /**
      Returns a new promise based on the current deferred instance
     **/
    public function promise(){
        return new Promise(this);
    }

    /**
      Returns a new stream based on the current deferred instance
     **/
    public function stream(){
        return new Stream(this);
    }

    /**
      Returns a stream based on the current deferred instance
     **/
    public function publicStream(){
        return new PublicStream(this);
    }
}
