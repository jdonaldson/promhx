
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


package promhx.base;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end
import promhx.base.EventLoop;
import promhx.Thenable;

class AsyncBase<T>{
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
    public function error(f : Dynamic->Void) : AsyncBase<T> {
        _error.push(f);
        return this;
    }


    /**
      Utility function to determine if a Promise value has been resolved.
     **/
    public inline function isResolved() : Bool
        return _resolved;


    /**
      Utility function to determine if a Promise value has been rejected.
     **/
    public inline function isFulfilled(): Bool
        return _fulfilled;

    /**
      Utility function to determine if a Promise value is in the process of
      fulfilling.
     **/
    public inline function isFulfilling() : Bool
        return _fulfilling;

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    public function resolve(val : T) : Void  _resolve(val);

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    private function _resolve(val : T, ?cleanup : Void->Void) : Void {

        // this async is in the process of fulfilling another value, move the
        // resolve to the next loop
        if (_fulfilling)
            return EventLoop.enqueue(_resolve.bind(val, cleanup));

        // point of no return, this async has now been resolved at least once.
        _resolved = true;

        // we are now in the act of fulfilling the async... which typically
        // involves waiting for the next enqueued loop
        _fulfilling = true;

        // the loop handler, which may not even be used
#if (js || flash) EventLoop.enqueue(function(){ #end
        _val = val; // save the value
        for (f in _update){
            try f(val)
            catch (e:Dynamic) handleError(e);
        }
        _fulfilled = true; // we're in a fulfilled state
        _fulfilling = false; // we're done fulfilling for this resolve
        if (cleanup != null) cleanup(); // we can cleanup if necessary
#if (js || flash) }); #end
    }

    /**
      Handle errors
     **/
    private function handleError(d : Dynamic) : Void {
        if (_error.length == 0) throw d
        else for (ef in _error) ef(d);
    }

    /**
      This function returns a new AsyncBase.  When this instance resolves,
      it will resolve the new AsyncBase with the function callback argument.
     **/
    public function then<A>(f : T->A) : AsyncBase<A> {
        var ret = new AsyncBase<A>();
        link(this, ret, f);
        return ret;
    }



    /**
      This is the base "link" method for wiring up the "current" async to
      the "next" one via the transform defined by the f argument.
     **/
    inline public static function link<T,A>
        (current : AsyncBase<T>, next: AsyncBase<A>, f : T->A) : Void
    {
        // the function wrapper for the callback, which will resolve the return
        // if current is not resolved, or will resolve next loop, push to
        // update queues.
        current._error.push(next.handleError);
        current._update.push(function(x){
            next.resolve(f(x));
        });
        if (current.isResolved() && !current.isFulfilling()){
            // we can go ahead and resolve this.
            try next.resolve(f(current._val))
                catch (e:Dynamic) next.handleError(e);
        }
    }

    inline public static function linkAll<T,A>
        (all : Iterable<AsyncBase<T>>, next: AsyncBase<Array<T>>) : Void
    {
        // a helper callback function.  This will be called for each Stream in
        // the iterable argument.  The "arr" argument will be all of the Streams
        // *except* the one currently resolving.  If there's only one Stream
        // in the iterable, it will always resolve.
        var cthen = function(arr:Array<AsyncBase<T>>, current:AsyncBase<T>,  v){
            if (arr.length == 0 || AsyncBase.allFulfilled(arr)){
                var vals = [for (a in all) a == current ? v : a._val];
                next.resolve(vals);
            }
        };
        for (a in all){
            a._update.push(cthen.bind([for (a2 in all) if (a2 != a) a2], a, _));
            a._error.push(next.handleError);
        }
        if (AsyncBase.allFulfilled(all)) {
            next.resolve([for (a in all) a._val]);
        }
    }

    /**
      Similar to the link function, except the [f] function must return an
      AsyncBase instance.
     **/
    inline static public function pipeLink<T,A>
        ( current : AsyncBase<T>, ret : AsyncBase<A>, f : T->AsyncBase<A> ) : Void
        current.then(function(x) f(x).then(ret.resolve));

    /**
      Utility function to determine if all Promise values are set.
     **/
    public static function allResolved
        (as : Iterable<AsyncBase<Dynamic>>) : Bool
    {
        var atLeastOneAsyncBase = false;
        for (a in as) {
            if (!a.isResolved()) return false;
            else atLeastOneAsyncBase = true;
        }
        return atLeastOneAsyncBase;
    }

    /**
      Utility function to determine if all Promise values are resolved and
      are currently fulfilled (not in the process of fulfilling).
     **/
    static function allFulfilled
        (as : Iterable<AsyncBase<Dynamic>>) : Bool
    {
        var atLeastOneAsyncBase = false;
        for (a in as) {
            if (!a.isFulfilled()) return false;
            else atLeastOneAsyncBase = true;
        }
        return atLeastOneAsyncBase;
    }

}
