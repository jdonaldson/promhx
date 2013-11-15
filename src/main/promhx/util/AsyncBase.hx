
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


package promhx.util;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end
import com.mindrocks.monads.Monad;
import promhx.util.EventQueue;
import promhx.Thenable;

class AsyncBase<T>{
    public var id         : Int;
    static var _idctr = 0;
    var _val        : T;
    var _resolved   : Bool;
    var _fulfilled  : Bool;
    var _fulfilling : Bool;
    var _update     : Array<T->Void>;
    var _error      : Array<Dynamic->Void>;

    /**
      Constructor argument can take optional function argument, which adds
      a callback to the error handler chain.
     **/
    public function new(?errorf : Dynamic->Void) {

        id = _idctr; _idctr+=1;
        _resolved   = false;
        _fulfilling = false;
        _fulfilled  = false;
        _update     = new Array<T->Void>();
        _error      = new Array<Dynamic->Void>();

        if (errorf != null) _error.push(errorf);
    }

    /**
      Specify an error handling function
     **/
    public function error(f : Dynamic->Void){
        _error.push(f);
        return this;
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
    private function _resolve(val : T, ?cb : Void->Void) : Void {
        _val = val;
        _resolved = true;
        _fulfilling = true;
#if (js || flash) EventQueue.setImmediate(function(){ #end
        for (f in _update){
            try f(_val)
            catch (e:Dynamic) handleError(e);
        }
        _fulfilling = false;
        _fulfilled = true;
        if (cb != null) cb();
#if (js || flash) }); #end
    }

    /**
      Handle errors
     **/
    private function handleError(d : Dynamic) {
        if (_error.length == 0) throw d
        else for (ef in _error) ef(d);
        return null;
    }


    public function then<A>(f : T->A) : AsyncBase<A> {
        var ret = new AsyncBase<A>();
        thenBuilder(this, f, ret);
        return ret;
    }

    inline static public function pipeBuilder<T,A>
        ( current : AsyncBase<T>, f : T->AsyncBase<A>, ret : AsyncBase<A>){
        current.error(ret.handleError).then(function(x) {
            f(x).error(ret.handleError).then(ret.resolve);
            return ret;
        });
    }

    /**
      Utility function to determine if all Promise values are set.
     **/
    public static function allResolved(as : Iterable<AsyncBase<Dynamic>>): Bool {
        var atLeastOneAsyncBase = false;
        for (a in as) {
            if (!a.isResolved()) return false;
            else atLeastOneAsyncBase = true;
        }

        return atLeastOneAsyncBase;
    }

    public static function bind<A,B>(from:AsyncBase<A>, to:AsyncBase<B>, f:  A->B ) {
        from.error(to.handleError).then(function(x) to.resolve(f(x)) );
    }

    inline public static function thenBuilder<T,A>(current : AsyncBase<T>, f : T->A, ret: AsyncBase<A>) : Void{
        // the function wrapper for the callback, which will resolve the return
        if(current.isResolved()) {
            try ret.resolve(f(current._val))
                catch(e:Dynamic) ret.handleError(e);
        }else {
            current._error.push(ret.handleError);
            current._update.push(function(x) ret.resolve(f(x)));
        }
    }
}
