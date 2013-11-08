
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


/**
  This is a primitive asynchronous class, used as a base class for Promise and
  Signal.
 **/


package promhx;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end
import com.mindrocks.monads.Monad;
import promhx.EventQueue;

class Async<T>{
    var _val        : T;
    var _resolved   : Bool;
    var _fulfilled  : Bool;
    var _fulfilling : Bool;
    var _rejected   : Bool;
    var _update     : Array<T->Dynamic>;
    var _error      : Array<Dynamic->Dynamic>;
    var _errorf     : Dynamic->Void;

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
    public function error(f : Dynamic->Void){
        _errorf = f;
        return this;
    }

    /**
      Utility function to determine if all Promise values are set.
     **/
    public static function allSet(as : Iterable<Async<Dynamic>>): Bool {
        var atLeastOneAsync = false;
        for (a in as) {
            if (!a._resolved) return false;
            else atLeastOneAsync = true;
        }

        return atLeastOneAsync;
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
      Resolves the given value for processing on any waiting functions.
     **/
    public function resolve(val : T): Void  _resolve(val); 

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    private function _resolve(val : T): Void {
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
      Rejects the promise, throwing an error.
     **/
    public function reject(e : Dynamic): Void {
        _update = new Array<T->Dynamic>();
        handleError(e);
    }

    public function create<A>() return new Async<A>(); 

    /**
      Converts any value to a resolved Async 
     **/
    public static function Async<T>(_val : T, ?errorf : Dynamic->Dynamic): Async<T> {
        var ret = new Async<T>(errorf);
        ret.resolve(_val);
        return ret;
    }

    /**
      add a wait function directly to the Async instance.
     **/
    public function then<A>(f : T->A): Async<A> {
        return _then(f);
    }

    function _then<A>(f : T->A) {
        var ret = create();
        // the function wrapper for the callback, which will
        // resolve the return promise
        var fret = function(v) {
            var res = f(v);
            ret.resolve(res);
            return res;
        }
        if(_resolved){
            try ret.resolve(f(_val))
            catch (e:Dynamic) handleError(e);
        }else{
            _update.push(fret);
            _error.push(ret.handleError);
        }
        return ret;
    }


    public function pipe<A,B:Async<A>>(f : T->Async<A>){
        if(isResolved()){
            // if already set, then directly invoke the promise creation callback
            var fret = f(_val);
            return fret;
        }else{
            var ret = create();
            // if not, we need an update, which will propagate the created 
            // promise value to the proxy
            _update.push(function(x){
                var fret = f(x);
                if (fret._resolved) ret.resolve(fret._val);
                else {
                    fret._update.push(cast ret.resolve);
                    fret._error.push(ret.handleError);
                }
                return null;
            });
            _error.push(ret.handleError);
            return ret;
        }
    }


    /**
      Transforms an iterable of Asyncs into a single async which resolves
      to an array of values.
     **/
    public static function whenAll<A>(itb : Iterable<Async<A>>) : Async<Array<A>> {
        return _whenAll(itb, new Async<Array<A>>());
    }

    inline static function _whenAll<A, B:Async<A>, C:Async<Array<A>>> (itb : Iterable<B>, ret : C) : C {
        var idx = 0;
        var arr = [for (i in itb) i];
        var cthen = function(v){
            while(idx < arr.length){
                if (!arr[idx].isResolved()) return;
                idx+=1;
            }
            if (!ret.isResolved()){
                try ret.resolve([for (v in arr) v._val])
                catch(e:Dynamic) untyped ret.handleError(e);
            }
        };
        if (promhx.Async.allSet(arr)) cthen(null);
        else for (p in arr) {
            p.then(cthen);
            p.error(ret.handleError);
        }
        return ret;
    }

}
