/****
* Copyright (c) 2013 Justin Donaldson
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
class Promise<T> {
    var _val    : T;
    var _set    : Bool;
    var _update : Array<T->Dynamic>;
    var _error  : Array<Dynamic->Dynamic>;
    var _errorf : Dynamic->Void;

    /**
      Constructor argument can take optional function argument, which adds
      a callback to the error handler chain.
     **/
    public function new(?errorf:Dynamic->Dynamic){

        _set    = false;
        _update = new Array<T->Dynamic>();
        _error  = new Array<Dynamic->Dynamic>();
        if (errorf != null) _error.push(errorf);
    }


    /**
      Specify an error handling function
     **/
    public function error(f:Dynamic->Void) {
        _errorf = f;
        return this;
    }

    /**
      Utility function to determine if all Promise values are set.
     **/
    public static function allSet(as:Iterable<Promise<Dynamic>>): Bool{
        for (a in as) if (!a._set) return false;
        return true;
    }

    macro public static function foo(a:Expr) : Expr {
        return macro null;
    }

    /**
      Macro method that binds the promise arguments to a single function
      callback that is triggered when all promises are resolved.
      Note: You may call this function on as many promise arguments as you
      like.
     **/
    macro public static function when<T>( args : Array<ExprOf<Promise<Dynamic>>>) : Expr {

        var pos = args[0].pos; // default pos
        var eargs : Expr; // the array of promises
        var ecall : Expr; // the function call on the promises


        //the types of all the arguments (should be all Promises)
        var types = [for (a in args) Context.typeof(a)];

        //the macro arguments expressed as an array expression.
        eargs = {expr:EArrayDecl(args),pos:pos};

        // An array of promise values
        var epargs = [for (a in args) { expr: EField(a, "_val"), pos: pos}];
        ecall = {expr: ECall(macro f, epargs), pos:pos}

        // the returned function that actually does the runtime work.
        return macro {
            var parr:Array<Promise<Dynamic>> = $eargs;
            var p = new Promise();
            {
                then : function(f) return Promise.whenAll(parr)
                        .then(function(x){
                            try untyped p.resolve($ecall)
                            catch(e:Dynamic) untyped p.handleError(e);
                        })
            }
        }
    }

    /**
      Transforms an iterable of promises into a single promise which resolves
      to an array of values.
     **/
    public static function whenAll<T>(itb : Iterable<Promise<T>>) : Promise<Array<T>> {
        var p = new Promise<Array<T>>();
        var itr = itb.iterator();
        var cur = itr.hasNext() ? itr.next() : null;
        var cthen = function(v:Dynamic){
            while(cur != null){
                if (!cur._set) return;
                else cur = itr.next();
            }
            if (!p._set){
                try p.resolve([for (v in itb) v._val])
                catch(e:Dynamic) untyped p.handleError(e);
            }
        };
        if (Promise.allSet(itb)) cthen(null);
        else for (p in itb) p.then(cthen);
        return p;
    }

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    public function resolve(val:T){
        if (_set) throw("Promise has already been resolved");
#if (js || flash) EventQueue.next(function(){ #end
        _set = true;
        _val = val;
        for (f in _update){
            try f(_val)
                catch (e:Dynamic) handleError(e);
        }
        _update = new Array<T->Dynamic>();
#if (js || flash) }); #end
    }

    /**
      Handle errors
     **/
    private function handleError(d:Dynamic){
        if (_errorf != null) _errorf(d)
        else if (_error.length == 0) throw d
        else for (ef in _error) ef(d);
        var p1 = new Promise<Int>();
        return null;
    }

    /**
      add a wait function directly to the Promise instance.
     **/
    public function then<A>(f:T->A):Promise<A>{
        var ret = new Promise<A>();

        // the function wrapper for the callback, which will
        // resolve the return promise
        var fret = function(v:T) {
            var res = f(v);
            ret.resolve(res);
            return res;
        }

        if(_set){
            try fret(_val)
            catch (e:Dynamic) handleError(e);
        }else{
            _update.push(fret);
            _error.push(ret.handleError);
        }
        return ret;
    }

    public function pipe<A>(f:T->Promise<A>):Promise<A>{
        if(_set){
            // if already set, then directly invoke the promise creation callback
            var fret = f(_val);
            return fret;
        }else{
            // if not, we need to create a proxy promise
            var ret = new Promise<A>();

            // and an update, which will propagate the created promise value
            // to the proxy
            var this_update = function(x:T){
                var fret = f(x);
                if (fret._set) ret.resolve(fret._val);
                else {
                    fret._update.push(cast ret.resolve);
                    fret._error.push(ret.handleError);
                }
            }
            _update.push(cast this_update);
            _error.push(ret.handleError);
            return ret;
        }
    }



    /**
      Rejects the promise, throwing an error.
     **/
    public function reject(e:Dynamic){
        _update = new Array<T->Dynamic>();
        handleError(e);
    }
    /**
      Converts any value to a resolved Promise
     **/
    public static function promise<T>(_val:T, ?errorf:Dynamic->Dynamic) : Promise<T>{
        var ret = new Promise<T>(errorf);
        ret.resolve(_val);
        return ret;
    }

}

