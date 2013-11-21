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
import promhx.util.EventLoop;
import promhx.util.AsyncBase;

@:expose
class Stream<T> extends AsyncBase<T>{
    var _end : Bool;
    var _onend : Array<Void->Void>;
    public function new(?errorf : Dynamic->Dynamic){
        super(errorf);
        _end = false;
        _onend = [];
    }
    /**
      Macro method that binds the stream arguments to a single function
      callback that is triggered when all streams are resolved.
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
                var p = Stream.wheneverAll($eargs);
                p._update.push(function(x) ret.resolve(f($a{epargs})));
                p._error.push(ret.handleError);
                return ret;
            };

            // return an anonymous object with the function definition for "then"
            { then : varargf };
        }
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

    public inline function update(val : T) resolve(val);

    override public function resolve(val : T) : Void {
        if (!_end) _resolve(val);
    }

    public function pipe<A>(f : T->Stream<A>) : Stream<A> {
        var ret = new Stream<A>();
        AsyncBase.pipeLink(this, ret, f);
        return ret;
    }

    public function end(){
        _end = true;
        for (f in _onend) try f() catch(e:Dynamic) handleError(e);
        _update = [];
        _error = [];
    }

    public function filter(f : T->Bool) : Stream<T>{
        var ret = new Stream<T>();
        _update.push(function(x) if (f(x)) ret.update(x));
        _error.push(ret.handleError);
        return ret;
    }

    public function concat(s : Stream<T>) : Stream<T> {
        var ret = new Stream<T>();
        _onend.push(function(){
            ret._update.push(s.update);
            ret._error.push(s.handleError);
        });
        _update.push(ret.update);
        _error.push(ret.handleError);
        return ret;
    }

    /**
      Merges another stream into the current one.
     **/
    public function merge(s : Stream<T>) : Stream<T> {
        var ret = new Stream<T>();
        _update.push(ret.update);
        _error.push(ret.handleError);
        s._update.push(ret.update);
        s._error.push(ret.handleError);
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
