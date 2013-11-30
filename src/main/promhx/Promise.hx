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

@:expose
class Promise<T> extends AsyncBase<T>{
    var _rejected   : Bool;
    public function new(?errorf : Dynamic->Dynamic){
        super(errorf);
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
        var epargs = [for (a in args) { expr: EField(a, "_val"), pos: pos}];

        // the returned function that actually does the runtime work.
        return macro {
            // a function that accepts a variable argument function
            var varargf = function(f){
                // we wait on all of the promises with the iterable-based "whenAll"
                // this will resolve an array, so we use pipe to ignore it, and set
                // up a new promise for return.
                // this new promise resolves via a macro-defined function expression
                // on "f" that provides arity and types for the resolved promise values.
                var ret = new Promise();
                var p = Promise.whenAll($eargs);
                p._update.push(function(x) ret.resolve(f($a{epargs})));
                p._error.push(ret.handleError);
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
        _update = new Array<T->Void>();
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
    override public function resolve(val : T): Void {
        if (_resolved) throw("Promise has already been resolved");
        _resolve(val, function(){
            _update = new Array<T->Void>();
        });
    }

    /**
      add a wait function directly to the AsyncBase instance.
     **/
    override public function then<A>(f : T->A): Promise<A> {
        var ret  = new Promise<A>();
        AsyncBase.link(this, ret, f);
        return ret;
    }

    public function pipe<A>(f : T->Promise<A>) : Promise<A> {
        var ret = new Promise<A>();
        AsyncBase.pipeLink(this, ret, f);
        return ret;
    }


    /**
      Converts any value to a resolved Promise
     **/
    public static function promise<T>(_val : T, ?errorf : Dynamic->Dynamic): Promise<T> {
        var ret = new Promise<T>(errorf);
        ret.resolve(_val);
        return ret;
    }
}

