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
class Promise<T> {
    var _val       : T;
    var _resolved       : Bool;
    var _fulfilled : Bool;
    var _fulfilling : Bool;
    var _rejected  : Bool;
    var _update    : Array<T->Dynamic>;
    var _error     : Array<Dynamic->Dynamic>;
    var _errorf    : Dynamic->Void;

    /**
      Constructor argument can take optional function argument, which adds
      a callback to the error handler chain.
     **/
    public function new(?errorf : Dynamic->Dynamic) {

        _resolved   = false;
        _fulfilling = false;
        _fulfilled  = false;
        _rejected   = false;
        _update     = new Array<T->Dynamic>();
        _error      = new Array<Dynamic->Dynamic>();

        if (errorf != null) _error.push(errorf);
    }


    /**
      Specify an error handling function
     **/
    public function error(f : Dynamic->Void): Promise<T> {
        _errorf = f;
        return this;
    }

    /**
      Utility function to determine if all Promise values are set.
     **/
    public static function allSet(as : Iterable<Promise<Dynamic>>): Bool {
        for (a in as) if (!a._resolved) return false;
        return true;
    }



    /**
      Utility function to determine if a Promise value has been resolved.
     **/
    public inline function isResolved(): Bool {
        return _resolved;
    }

    /**
      Utility function to determine if a Promise value has been rejected.
     **/
    public inline function isRejected(): Bool {
        return _rejected;
    }

    /**
      Utility function to determine if a Promise value has been rejected.
     **/
    public inline function isFulfilled(): Bool {
        return _fulfilled;
    }

    /**
      Utility function to determine if a Promise value has been rejected.
     **/
    public inline function isFulfilling(): Bool {
        return _fulfilling;
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
    public static function whenAll<T>(arr : Array<Promise<T>>) : Promise<Array<T>> {
        var ret = new Promise<Array<T>>();
        var idx = 0;
        var cthen = function(v:Dynamic){
            while(idx < arr.length){
                if (!arr[idx].isResolved()) return;
                idx+=1;
            }
            if (!ret.isResolved()){
                try ret.resolve([for (v in arr) v._val])
                catch(e:Dynamic) untyped ret.handleError(e);
            }
        };
        if (Promise.allSet(arr)) cthen(null);
        else for (p in arr) {
            p.then(cthen);
            p.error(ret.handleError);
        }
        return ret;
    }

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    public function resolve(val : T): Void {
        if (_resolved) throw("Promise has already been resolved");
        _val = val;
        _resolved = true;
        _fulfilling = true;
#if (js || flash) EventQueue.setImmediate(function(){ #end
        for (f in _update){
            try f(_val)
                catch (e:Dynamic) handleError(e);
        }
        _update = new Array<T->Dynamic>();
        _fulfilling = false;
        _fulfilled = true;
#if (js || flash) }); #end
    }

    /**
      Handle errors
     **/
    private function handleError(d : Dynamic) {
        _rejected = true;
        if (_errorf != null) _errorf(d)
        else if (_error.length == 0) throw d
        else for (ef in _error) ef(d);
        var p1 = new Promise<Int>();
        return null;
    }

    /**
      add a wait function directly to the Promise instance.
     **/
    public function then<A>(f : T->A): Promise<A> {
        var ret = new Promise<A>();

        // the function wrapper for the callback, which will
        // resolve the return promise
        var fret = function(v:T) {
            var res = f(v);
            ret.resolve(res);
            return res;
        }

        if(_resolved){
            try fret(_val)
            catch (e:Dynamic) handleError(e);
        }else{
            _update.push(fret);
            _error.push(ret.handleError);
        }
        return ret;
    }

    public function pipe<A>(f : T->Promise<A>): Promise<A> {
        if(isResolved()){
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
                if (fret._resolved) ret.resolve(fret._val);
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
    public function reject(e : Dynamic): Void {
        _update = new Array<T->Dynamic>();
        handleError(e);
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

