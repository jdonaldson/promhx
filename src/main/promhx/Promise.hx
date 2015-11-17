package promhx;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end
import promhx.base.EventLoop;
import promhx.base.AsyncBase;
import promhx.error.PromiseError;

@:expose
class Promise<T> extends AsyncBase<Promise<Dynamic>, T>{
    var _rejected   : Bool;
    public function new(?d:Deferred<T>){
        super(d);
        _rejected = false;
    }

    /**
      Macro method that binds the promise arguments to a single function
      callback that is triggered when all promises are resolved.
      Note: You may call this function on as many promise arguments as you
      like.
     **/
    macro public static function when<T>( args : Array<ExprOf<Promise<Dynamic>>>) : Expr {

        // a default position
        var pos = Context.currentPos();

        //the macro arguments translated to an array expression.
        var eargs = {expr:EArrayDecl(args), pos:pos};

        // An array of the resolved promise values
        var epargs = [for (i in 0...args.length) macro arr[$v{i}]._val];

        // the returned function that actually does the runtime work.
        return macro @:privateAccess {
            // a function that accepts a variable argument function
            var varargf = function(f){
                // we wait on all of the promises with the iterable-based "whenAll"
                // this will resolve an array, so we use pipe to ignore it, and set
                // up a new promise for return.
                // this new promise resolves via a macro-defined function expression
                // on "f" that provides arity and types for the resolved promise values.
                var ret = new promhx.Promise();
                var arr : Array<promhx.Promise<Dynamic>> = $eargs;
                var p = new Promise<Array<Dynamic>>(); 
                promhx.base.AsyncBase.linkAll(arr, p);
                p._update.push({
                    async : ret,
                    linkf : function(x) ret.handleResolve(f($a{epargs}))
                });
                return ret;
            };

            // return an anonymous object with the function definition for "then"
            { then : varargf };
        }
    }

    /**
      Utility function to determine if a Promise value has been rejected.
     **/
    public inline function isRejected(): Bool {
        return _rejected;
    }

    /**
      Rejects the promise, throwing an error.
     **/
    public function reject(e : Dynamic): Void {
        _rejected = true;
        handleError(e);
    }

    /**
      Transforms an iterable of promises into a single promise which resolves
      to an array of values.
     **/
    public static function whenAll<T>(itb : Iterable<Promise<T>>) : Promise<Array<T>> {
        var ret : Promise<Array<T>> = new Promise();
        AsyncBase.linkAll(itb, ret);
        return ret;
    }

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    override function handleResolve(val : T): Void {
        if (_resolved) {
            var msg = "Promise has already been resolved";
            throw(AlreadyResolved(msg));
        }
        _resolve(val);
    }

    /**
      add a wait function directly to the Promise instance.
     **/
    override public function then<A>(f : T->A): Promise<A> {
        var ret  = new Promise<A>();
        link(ret,f);
        return ret;
    }

    override public function unlink( to : AsyncBase<Dynamic,Dynamic>) {
        EventLoop.enqueue(function(){
            if (!isFulfilled()) {
                var msg = "Downstream Promise is not fullfilled";
                handleError(DownstreamNotFullfilled(msg));
            }
            else{
                _update =  _update.filter(function(x) return x.async != to);
            }
        });
    }

    override function handleError(error : Dynamic) : Void {
       _rejected = true; 
       _handleError(error);
    }

    public function pipe<A>(f : T->Promise<A>) : Promise<A> {
        var ret = new Promise<A>();
        AsyncBase.pipeLink(this, ret, f);
        return ret;
    }

    /**
      Pipes an error back into a normal type.
      **/
    public function errorPipe( f: Dynamic-> Promise<T>){
        var ret = new Promise<T>();
        catchError(function(e){
            var piped = f(e);
            piped.then(ret._resolve);
        });
        then(ret._resolve);
        return ret;
    }

    /**
      Converts any value to a resolved Promise
     **/
    public static function promise<T>(_val : T): Promise<T> {
        var ret = new Promise<T>();
        ret.handleResolve(_val);
        return ret;
    }
}

