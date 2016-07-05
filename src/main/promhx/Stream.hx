package promhx;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end
import promhx.base.EventLoop;
import promhx.base.AsyncBase;
import haxe.ds.Option;

@:expose
class Stream<T> extends AsyncBase<T> {
    var deferred      : Deferred<T>;
    var _pause        : Bool;
    var _end          : Bool;
    var _end_promise  : Promise<Option<T>>;

    public function new(?d : Deferred<T> #if debug ,?pos:haxe.PosInfos #end){
        super(d #if debug, pos #end);
        _end_promise = new Promise<Option<T>>();
    }

    /**
      Macro method that binds the stream arguments to a single function
      callback that is triggered when all streams are updated.
      Note: You may call this function on as many stream arguments as you
      like.
     **/
    macro public static function whenever<T>( args : Array<ExprOf<AsyncBase<Dynamic>>>) : Expr {

        // a default position
        var pos = Context.currentPos();

        //the macro arguments translated to an array expression.
        var eargs = {expr:EArrayDecl(args), pos:pos};

        // An array of the resolved stream values
        var epargs = [for (i in 0...args.length) macro arr[$v{i}]._val];

        // the returned function that actually does the runtime work.
        return macro @:privateAccess {
            // a function that accepts a variable argument function
            var varargf = function(f){
                // we wait on all of the streams with the iterable-based "whenAll"
                // this will resolve an array, so we use pipe to ignore it, and set
                // up a new stream for return.
                // this new stream resolves via a macro-defined function expression
                // on "f" that provides arity and types for the resolved stream values.
                var ret = new promhx.Stream(null #if debug ,null #end);
                var arr : Array<promhx.base.AsyncBase<Dynamic>> = $eargs;
                var s = new Stream<Array<Dynamic>>();
                promhx.base.AsyncBase.linkAll(arr, s);
                s._update.push({
                    async: ret,
                    linkf: function(x) ret.handleResolve(f($a{epargs}))
                });
                return ret;
            };

            // return an anonymous object with the function definition for "then"
            { then : varargf };
        }
    }

    /**
      Creates a stream from the iterable [itb] that will immediately update
      for each value, and then end.
     **/
    public static function foreach<T>(itb : Iterable<T> #if debug ,?pos:haxe.PosInfos #end) : Stream<T> {
        var s = new Stream<T>(null #if debug ,pos #end);
        for (i in itb) s.handleResolve(i);
        s.end();
        return s;
    }


    /**
      add a wait function directly to the Stream instance.
     **/
    override public function then<A>(f : T->A #if debug ,?pos:haxe.PosInfos #end) : Stream<A> {
        var ret  = new Stream<A>(null #if debug ,pos #end);
        AsyncBase.link(this, ret, f);
        _end_promise._update.push({
            async : ret._end_promise,
            linkf : function(x) ret.end()
        });
        return ret;
    }

    public function detachStream(str : Stream<Dynamic>) : Bool {
        var filtered = [];
        var removed = false;
        for (u in _update){
            if (u.async == str) {
                // also remove the "end" promise update from downstream
                _end_promise._update = _end_promise._update.filter(function(x){
                    return x.async != str._end_promise;
                });
                removed = true;
            }
            else filtered.push(u);
        }
        _update = filtered;
        return removed;
    }

    /**
      Transforms an iterable of streams into a single stream which resolves
      to an array of values.
     **/
    public static function wheneverAll<T>(itb : Iterable<AsyncBase<T>> #if debug ,?pos:haxe.PosInfos #end) : Stream<Array<T>> {
        var ret = new Stream<Array<T>>(null #if debug ,pos #end);
        AsyncBase.linkAll(itb, ret);
        return ret;
    }

    /**
      Concatenates all the streams in the iterable argument to a single stream.  See
      the [concat] instance method.
     **/
    public static function concatAll<T>(itb : Iterable<Stream<T>> #if debug ,?pos:haxe.PosInfos #end) : Stream<T> {
        var ret = new Stream<T>(null #if debug ,pos #end);
        for (i in itb) ret.concat(i);
        return ret;
    }

    /**
      Merges all the streams in the iterable argument to a single stream.  See
      the [merge] instance method.
     **/
    public static function mergeAll<T>(itb : Iterable<Stream<T>> #if debug ,?pos:haxe.PosInfos #end) : Stream<T> {
        var ret = new Stream<T>(null #if debug ,pos #end);
        for (i in itb) ret.merge(i);
        return ret;
    }

    /**
      Returns a Promise that will resolve only for the first stream update.
     **/
    public inline function first(#if debug ?pos:haxe.PosInfos #end) : Promise<T> {
        var s = new Promise<T>(null #if debug ,pos #end);
        then(function(x) if (!s.isResolved()) s.handleResolve(x));
        return s;
    }

    override function handleResolve(val : T) : Void {
        if (!_end && !_pause) _resolve(val);
    }

    /**
      Momentarily disable updates for the stream.  Set the pause state with
      the argument.  Call it without the argument to toggle the current state.
     **/
    public function pause(?set : Bool){
        if (set == null) set = !_pause;
        _pause = set;
    }

    public function pipe<A>(f : T->Stream<A> #if debug ,?pos:haxe.PosInfos #end) : Stream<A> {
        var ret = new Stream<A>(null #if debug ,pos #end);
        AsyncBase.pipeLink(this, ret, f);
        _end_promise.then(function(x) ret.end());
        return ret;
    }

    /**
      Pipes an error back into a normal type.
      **/
    public function errorPipe( f: Dynamic-> Stream<T> #if debug ,?pos:haxe.PosInfos #end) : Stream<T>{
        var ret = new Stream<T>(null #if debug ,pos #end);
        catchError(function(e){
            var piped = f(e);
            piped.then(ret._resolve);
            piped._end_promise.then(ret._end_promise._resolve);
        });
        then(ret._resolve);
        _end_promise.then(function(x) ret.end());
        return ret;
    }

    /**
      I need this as a private function to call recursively.
     **/
    function handleEnd(){
        // If the async is still pending, check on the next loop.
        if (isPending()) EventLoop.enqueue(handleEnd);
        else if (_end_promise.isResolved()) return;
        else {
            _end = true;
            var o = isResolved() ? Some(_val) : None;
            _end_promise.handleResolve(o);
            _update = [];
            _error = [];
        }
    }

    public function end(){
        EventLoop.enqueue(handleEnd);
        return this;
    }

    inline public function endThen<A>(f : Option<T>->A) : Promise<A>{
       return _end_promise.then(f);
    }

    /**
      Creates a new stream linked to the current instance that only updates
      if the [f] argument is true.
     **/
    public function filter(f : T->Bool #if debug ,?pos:haxe.PosInfos #end) : Stream<T>{
        var ret = new Stream<T>(null #if debug ,pos #end);
        _update.push({
            async : ret,
            linkf : function(x) if (f(x)) ret.handleResolve(x)
        });
        AsyncBase.immediateLinkUpdate(this, ret, function(x) return x);
        return ret;
    }

    /**
      Creates a new stream that updates with the values from the current
      stream until the stream ends, and then takes values from the next stream
      [s] until that stream ends.
     **/
    public function concat(s : Stream<T> #if debug ,?pos:haxe.PosInfos #end) : Stream<T> {
        var ret = new Stream<T>(null #if debug ,pos #end);
        _update.push({
            async : ret,
            linkf : ret.handleResolve
        });
        AsyncBase.immediateLinkUpdate(this, ret, function(x) return x);
        endThen(function(_){
            s.pipe(function(x){
                ret.handleResolve(x);
                return ret;
            });
            s.endThen(function(_){
                ret.end();
            });
        });
        return ret;
    }

    /**
      Merges another stream into the current one.
     **/
    public function merge(s : Stream<T> #if debug ,?pos:haxe.PosInfos #end) : Stream<T> {
        var ret = new Stream<T>(null #if debug ,pos #end);
        _update.push({
            async : ret,
            linkf : ret.handleResolve
        });
        s._update.push({
            async : ret,
            linkf : ret.handleResolve
        });
        AsyncBase.immediateLinkUpdate(this, ret, function(x) return x);
        AsyncBase.immediateLinkUpdate(s, ret, function(x) return x);
        return ret;
    }

    /**
      Converts any value to a resolved Stream
     **/
    public static function stream<A>(_val : A #if debug ,?pos:haxe.PosInfos #end): Stream<A> {
        var ret = new Stream<A>(null #if debug ,pos #end);
        ret.handleResolve(_val);
        return ret;
    }

}

