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

typedef AsyncLink<T> = {
    async : AsyncBase<Dynamic>,
    linkf : T->Void
}


class AsyncBase<T>{
#if debug
    // add ids to the async instances so they are easier to track
    static var id_ctr  = 0;
    var id          : Int;
#end
    var _val        : T;
    var _resolved   : Bool;
    var _fulfilled  : Bool;
    var _pending    : Bool;
    var _update     : Array<AsyncLink<T>>;
    var _error      : Array<Dynamic->Void>;
    var _errorMap   : Dynamic->T;

    /**
      Constructor argument can take optional function argument, which adds
      a callback to the error handler chain.
     **/
    public function new(?errorf : Dynamic->Void) {
#if debug id = id_ctr +=1; #end

        _resolved   = false;
        _pending = false;
        _fulfilled  = false;
        _update     = [];
        _error      = [];

        if (errorf != null) _error.push(errorf);
    }

    /**
      Catch error, effectively halting the current update chain.
      This will prevent downstream async objects from receiving 
      the error message.
     **/
    public function catchError(f : Dynamic->Void) : AsyncBase<T> {
        _error.push(f);
        return this;
    }

    /**
      Map errors back to the expected type, and continue as normal.
     **/
    public function errorThen( f : Dynamic -> T){
        _errorMap = f;
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
      Utility function to determine if a Promise value is pending operations
      on the next loop.
     **/
    public inline function isPending() : Bool
        return _pending;

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    public function resolve(val : T) : Void  _resolve(val);

    /**
      Resolves the given value for processing on any waiting functions.
     **/
    function _resolve(val : T, ?cleanup : Void->Void) : Void {

        // this async is pending an update on the next loop, move the
        // resolve to the loop after that.
        if (_pending)
            return EventLoop.enqueue(_resolve.bind(val, cleanup));

        // point of no return, this async has now been resolved at least once.
        _resolved = true;

        // we are now in the act of fulfilling the async... which
        // involves waiting for the next enqueued loop
        _pending = true;

        // the loop handler, which may not even be used
        EventLoop.enqueue(function(){
            _val = val; // save the value
            for (up in _update){
                try up.linkf(val)
                catch (e:Dynamic) up.async.handleError(e);
            }
            _fulfilled = true; // we're in a fulfilled state
            _pending = false; // we're done fulfilling for this resolve
            if (cleanup != null) cleanup(); // we can cleanup if necessary
        });
    }

    /**
      Handle errors
     **/
    function handleError(error : Dynamic) : Void {
        var update_errors = function(e:Dynamic){
            if (_error.length > 0) for (ef in _error) ef(e);
            else if (_update.length > 0) for (up in _update) up.async.handleError(e);
            else throw e;
        }
        EventLoop.enqueue(function(){
            if (_errorMap != null){
                try this.resolve(_errorMap(error))
                catch (e : Dynamic) update_errors(e);
            } else {
                update_errors(error);
            }
        });
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
        current._update.push({
            async : next,
            linkf : function(x){
                next.resolve(f(x));
            }
        });
        immediateLinkUpdate(current, next, f);
    }

    static function immediateLinkUpdate<A,B>
        (current : AsyncBase<A>, next : AsyncBase<B>, f : A->B) : Void
    {
        if (current.isResolved() && !current.isPending()){
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
            return null;
        };
        for (a in all){
            a._update.push({
                async : next,
                linkf: cthen.bind([for (a2 in all) if (a2 != a) a2], a, _)
            });
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
    {
        var linked = false;
        var linkf = function(x){ // updates go to pipe function.
                if (!linked){ // but only once
                    linked = true; // the piped async doesn't actually respond to updates from current
                    var pipe_ret = f(x); // it just needs to be created
                    pipe_ret._update.push({  // and to be linked to ret
                        async : ret, // errors go to ret
                        linkf : ret.resolve // updates go directly to ret
                    });
                    immediateLinkUpdate(pipe_ret, ret, function(x) return x );
                }
            }

        current._update.push({
            async : ret, // errors go to ret
            linkf : linkf
        });

        if (current.isResolved() && !current.isPending()){
            try linkf(current._val)
            catch (e:Dynamic) ret.handleError(e);
        }
    }

    /**
      Utility function to determine if all Promise values are set.
     **/
    public static function allResolved
        (as : Iterable<AsyncBase<Dynamic>>) : Bool
    {
        for (a in as) {
            if (!a.isResolved()) return false;
        }
        return true;
    }

    /**
      Utility function to determine if all Promise values are resolved and
      are currently fulfilled (not in the process of fulfilling).
     **/
    static function allFulfilled
        (as : Iterable<AsyncBase<Dynamic>>) : Bool
    {
        for (a in as) {
            if (!a.isFulfilled()) return false;
        }
        return true;
    }

}
