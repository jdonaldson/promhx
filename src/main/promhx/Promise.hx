/****
* Copyright (c) 2013 Justin Donaldson
*
* MIT License
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
****/

package promhx;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
#end

using Lambda;

class Promise<T> {
    private var _val    : T;
    private var _set    : Bool;
    private var _update : Array<T->Dynamic>;
    private var _error  : Array<Dynamic->Dynamic>;
    private var _errorf : Dynamic->Void;

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
        trace(a);
        return macro null;
    }

    /**
      Macro method that binds the promise arguments to a single function
      callback that is triggered when all promises are resolved.
      Note: You may call this function on as many promise arguments as you
      like.
     **/
    macro public static function when<T>( args : Array<ExprOf<Promise<Dynamic>>>) : Expr {


        // just using a simple pos for all expressions
        var pos = args[0].pos;
        //The unknown type for the then function, also used for the promise return
        var eargs : Expr; // the array of promises
        var ecall : Expr; // the function call on the promises

        // multiple argument, with iterable first argument... treat as error for now
        for (a in args){
            //the types of all the arguments (should be all Promises)
            var types = args.map(Context.typeof);
            //the parameters of the Promise types
            var ptypes = types.map(function(x) switch(x){
                case TInst(_,params): return params[0];
                default : {
                    Context.error("Somehow, an illegal promise value was passed",pos);
                    return null;
                }
            });
            //the macro arguments expressed as an array expression.
            eargs = {expr:EArrayDecl(args),pos:pos};

            // An array of promise values
            var epargs = args.map(function(x) {
                return {expr:EField(x,"_val"),pos:pos}
            }).array();
            ecall = {expr: ECall(macro f, epargs), pos:pos}
        }

        // the returned function that actually does the runtime work.
        return macro {
            var parr:Array<Promise<Dynamic>> = $eargs;
            var p = new Promise();
            {
                then : function(f){
                     //"then" function callback for each promise
                    var cthen = function(v:Dynamic){
                        if ( Promise.allSet(parr)){
                            try{ untyped p.resolve($ecall); }
                            catch(e:Dynamic){
                                untyped p.handleError(e);
                            }
                        }
                    }
                    if (Promise.allSet(parr)) cthen(null);
                    else for (p in parr) p.then(cthen);
                    return p;
                }
            }
        }
    }

    /**
      "Flattens" an Iterable of promises into a single promise which resolves
      to an array of values.
     **/
    public static function flatMap<T>(itb : Iterable<Promise<T>>) : Promise<Array<T>> {
        var p = new Promise<Array<T>>();
        var cthen = function(v:Dynamic){
            if (Promise.allSet(itb)){
                var vals = [for (v in itb) v._val];
                try p.resolve(vals)
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
        _set = true;
        _val = val;
        for (f in _update){
            try f(_val)
            catch (e:Dynamic) handleError(e);
        }
        _update = new Array<T->Dynamic>();
    }

    /**
      Handle errors
     **/
    private function handleError(d:Dynamic){
        if (_errorf != null) _errorf(d)
        else if (_error.length == 0) throw d
        else for (ef in _error) ef(d);
        return null;
    }

    /**
      add a wait function directly to the Promise instance.
     **/
    public function then<A>(f:T->A):Promise<A>{
        var ret = new Promise<A>();
        if(_set){
            try f(_val)
            catch (e:Dynamic) handleError(e);
        }else{
            _update.push(f);
            _error.push(ret.handleError);
        }
        return ret;
    }

    public function pipe<A>(f:T->Promise<A>):Promise<A>{
        if(_set){
            return f(_val);
        }else{
            var ret = new Promise<A>();
            var this_update = function(x:T){
                var fret = f(x);
                fret._update.push(cast ret.resolve);
                fret._error.push(ret.handleError);
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

