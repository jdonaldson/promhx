/****  Copyright (c) 2013 Justin Donaldson
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
****/

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
class Stream<T> extends AsyncBase<T>{
    var _pause : Bool;
    var _end : Bool;
    var _end_promise : Promise<Option<T>>;

    public function new(?errorf : Dynamic->Dynamic){
        super(errorf);
        _end = false;
        _pause = false;
        _end_promise = new Promise();
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
        var epargs = [for (a in args) { expr: EField(a, "_val"), pos: pos}];

        // the returned function that actually does the runtime work.
        return macro {
            // a function that accepts a variable argument function
            var varargf = function(f){
                // we wait on all of the streams with the iterable-based "whenAll"
                // this will resolve an array, so we use pipe to ignore it, and set
                // up a new stream for return.
                // this new stream resolves via a macro-defined function expression
                // on "f" that provides arity and types for the resolved stream values.
                var ret = new Stream();
                var arr : Array<Stream<Dynamic>> = $eargs;
                var p = Stream.wheneverAll(arr);
                p._update.push({
                    async: ret,
                    linkf: function(x) ret.resolve(f($a{epargs}))
                });
                return ret;
            };

            // return an anonymous object with the function definition for "then"
            { then : varargf };
        }
    }
    public static function foreach<T>(itb : Iterable<T>) : Stream<T>{
        var s = new Stream<T>();
        for (i in itb) s.update(i);
        s.end();
        return s;
    }

    /**
      add a wait function directly to the Stream instance.
     **/
    override public function then<A>(f : T->A): Stream<A> {
        var ret  = new Stream<A>();
        AsyncBase.link(this, ret, f);
        _end_promise.then(function(x) ret.end());
        return ret;
    }

    /**
      Transforms an iterable of streams into a single stream which resolves
      to an array of values.
     **/
    public static function wheneverAll<T>(itb : Iterable<Stream<T>>) : Stream<Array<T>> {
        var ret = new Stream<Array<T>>();
        AsyncBase.linkAll(itb, ret);
        return ret;
    }

    /**
      Concatenates all the streams in the iterable argument to a single stream.  See
      the [concat] instance method.
     **/
    public static function concatAll<T>(itb : Iterable<Stream<T>>) : Stream<T> {
        var ret = new Stream<T>();
        for (i in itb) ret.concat(i);
        return ret;
    }

    /**
      Merges all the streams in the iterable argument to a single stream.  See
      the [merge] instance method.
     **/
    public static function mergeAll<T>(itb : Iterable<Stream<T>>) : Stream<T> {
        var ret = new Stream<T>();
        for (i in itb) ret.merge(i);
        return ret;
    }

    /**
      Returns a Promise that will resolve only for the first stream update.
     **/
    public inline function first() : Promise<T> {
        var s = new Promise<T>();
        this.then(function(x) if (!s.isResolved()) s.resolve(x));
        return s;
    }

    public inline function update(val : T) resolve(val);

    override public function resolve(val : T) : Void {
        if (!_end && !_pause) _resolve(val);
    }

    /**
      Momentarily disable updates for the stream.  Set the pause state with
      the argument.  Call it without the argument to toggle the current state.
     **/
    public function pause(?set : Bool){
        if (set == null) set == !_pause;
        _pause = set;
    }

    public function pipe<A>(f : T->Stream<A>) : Stream<A> {
        var ret = new Stream<A>();
        AsyncBase.pipeLink(this, ret, f);
        _end_promise.then(function(x) ret.end());
        return ret;
    }

    /**
      I need this as a private function to call recursively.
     **/
    function handleEnd(){
        // If the async is still pending, check on the next loop.
        if (this.isPending()) EventLoop.enqueue(handleEnd);
        else if (_end_promise.isResolved()) return;
        else {
            _end = true;
            var o = isResolved() ? Some(_val) : None;
            _end_promise.resolve(o);
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
    public function filter(f : T->Bool) : Stream<T>{
        var ret = new Stream<T>();
        _update.push({
            async : ret,
            linkf : function(x) if (f(x)) ret.update(x)
        });
        AsyncBase.immediateLinkUpdate(this, ret, function(x) return x);
        return ret;
    }

    /**
      Creates a new stream that updates with the values from the current
      stream until the stream ends, and then takes values from the next stream
      [s] until that stream ends.
     **/
    public function concat(s : Stream<T>) : Stream<T> {
        var ret = new Stream<T>();
        _update.push({
            async : ret,
            linkf : ret.update
        });
        AsyncBase.immediateLinkUpdate(this, ret, function(x) return x);
        endThen(function(_){
            s.pipe(function(x){
                ret.resolve(x);
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
    public function merge(s : Stream<T>) : Stream<T> {
        var ret = new Stream<T>();
        _update.push({
            async : ret,
            linkf : ret.update
        });
        s._update.push({
            async : ret,
            linkf : ret.update
        });
        AsyncBase.immediateLinkUpdate(this, ret, function(x) return x);
        AsyncBase.immediateLinkUpdate(s, ret, function(x) return x);
        return ret;
    }

    /**
      Converts any value to a resolved Stream
     **/
    public static function stream<A>(_val : A, ?errorf : Dynamic->Dynamic): Stream<A> {
        var ret = new Stream<A>(errorf);
        ret.resolve(_val);
        return ret;
    }

}

