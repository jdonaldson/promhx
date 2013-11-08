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
import com.mindrocks.monads.Monad;
import promhx.EventQueue;

@:expose
class Stream<T> extends Async<T>{
    public function new(?errorf : Dynamic->Dynamic) super(errorf);
    /**
      Macro method that binds the promise arguments to a single function
      callback that is triggered when all promises are resolved.
      Note: You may call this function on as many promise arguments as you
      like.
     **/
    macro public static function whenever<T>( args : Array<ExprOf<Async<Dynamic>>>) : Expr {

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
                return Stream.wheneverAll($eargs).pipe(function(x){
                            var p = new Stream();
                            // we get the type/arity of "f" from the resolved promise values.
                            // haxe infers the call/complex type for us, so we don't need to declare it:
                            p.resolve(f($a{epargs}));
                            return p;
                        });
            };

            // return an anonymous object with the function definition for "then"
            { then : varargf };
        }
    }

    /**
      Transforms an iterable of promises into a single promise which resolves
      to an array of values.
     **/
    public static function wheneverAll<T>(itb : Iterable<Stream<T>>) : Stream<Array<T>> {
        return Async._whenAll(itb, create);
    }

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    override public function resolve(val : T): Void {
        if (_resolved) throw("Stream has already been resolved");
        _resolve(val);
    }


    /**
      add a wait function directly to the Async instance.
     **/
    override public function then<A>(f : T->A): Stream<A> {
        return cast Async._then(this, f, create);
    }

    /**
      Converts any value to a resolved Stream
     **/
    public static function promise<T>(_val : T, ?errorf : Dynamic->Dynamic): Stream<T> {
        var ret = new Stream<T>(errorf);
        ret.resolve(_val);
        return ret;
    }

    /**
      Create a non-resolved promise (equivalent to calling constructor);
     **/
    static function create<A>() return new Stream<A>();
}
