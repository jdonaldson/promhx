package promhx;
import haxe.macro.Expr;
import haxe.macro.Context;
using Lambda;
class Promise<T> {
    private var _val:T;
    private var _set:Bool;
    private var _update:Array<T->Dynamic>;
    private var _error:Array<Dynamic->Dynamic>;
    private var _errorf:Dynamic->Dynamic;
    public function new(){
        _set = false;
        _update = new Array<T->Dynamic>();
        _error = new Array<Dynamic->Dynamic>();
    }

    /**
      Specify an error handling function
     **/
    public function error(f:Dynamic->Dynamic) {
        _errorf = f;
        return this;
    }

    private static function _when(arr:Array<Dynamic>):Dynamic{
        var ret = {then:function(x) trace("hi")};
        return ret;
        // could be an array of arrays
        var arg_arr = false;
        if (arr.length > 0 && Std.is(arr[0],Array)) {
            arg_arr = true;
            arr = arr[0];
        }
        var p = new Promise<Dynamic>();
        var parr:Array<Promise<Dynamic>> = cast arr; 
        // "then" function for the promise closure
        var pthen =  function(f:Dynamic){
            // "then" function callback for each promise
            var cthen = function(v:Dynamic){
                if (Promise.allSet(parr)){
                    var vals = [];
                    for (pv in parr) vals.push(pv._val);
                    if (arg_arr) vals = cast [vals];
                    trace(f);
                    try p.resolve(Reflect.callMethod({},f,vals))
                    catch (e:Dynamic) p.handleError(e);
                }
            }
            cthen(null);
            for (p in parr) p.then(cthen);
            return p;
        }
        var ret = {then:pthen};
        return ret;
    }

    /**
      static initialization to set the magic "when" function
     **/
    private static function __init__(){
        //arr = Array of promises
        Promise.when =  Reflect.makeVarArgs(cast _when);
    }
    /**
      Utility function to determine if all Promise values are set.
     **/
    private static function allSet(as:Array<Promise<Dynamic>>): Bool{
        for (a in as) if (!a._set) return false;
        return true;
    }

    @:overload(function<A,B,C>(arg1:Promise<A>, arg2:Promise<B>):{then:(A->B->C)->Promise<C>}{})
    @:overload(function<A,B,C,D>(arg1:Promise<A>, arg2:Promise<B>, arg3:Promise<C>):{then:(A->B->C->D)->Promise<D>}{})
    @:overload(function<A,B,C,D,E>(arg1:Promise<A>, arg2:Promise<B>, arg3:Promise<C>, arg4:Promise<D>):{then:(A->B->C->D->E)->Promise<E>}{})
    @:overload(function<A,B,C,D,E,F>(arg1:Promise<A>, arg2:Promise<B>, arg3:Promise<C>, arg4:Promise<D>, arg5:Promise<E>):{then:(A->B->C->D->E->F)->Promise<F>}{})
    @:overload(function<A,B,C,D,E,F,G>(arg1:Promise<A>, arg2:Promise<B>, arg3:Promise<C>, arg4:Promise<D>, arg5:Promise<E>, arg6:Promise<F>):{then:(A->B->C->D->E->F->G)->Promise<G>}{})
    public dynamic static function when<A>(f:Array<Promise<Dynamic>>):{then:(Array<Dynamic>->A)->Promise<A>} {return null;}

    //@:overload(function<A,B,C>(arg1:Promise<A>, arg2:Promise<B>):Promise<C>{})
    //@:overload(function<A,B,C,D>(arg1:Promise<A>, arg2:Promise<B>, arg3:Promise<C>):Promise<D>{})
    //@:overload(function<A,B,C,D,E>(arg1:Promise<A>, arg2:Promise<B>, arg3:Promise<C>, arg4:Promise<D>):Promise<E>{})
    //@:macro public static function when2(args:Array<Expr>):Expr{
    //@:macro public static function when2(args:Expr):Expr{
    @:macro public static function when2(args:Array<ExprRequire<Promise<Dynamic>>>):Expr{
    // could be an array of arrays
        trace(args);
        //return args[0];
        return args[0];

        var pos = args[0].pos;
        var vals_ref = { pos:pos,
            expr:EConst(CIdent("vals"))
        }
         
        for (a in 0...args.length){
            EArray(vals_ref, Context.makeExpr(a,pos));
        }
        //var eargs = {pos:args[0].pos,
            //expr:EArrayDecl(args)
        //}
        //var f_ref = {pos:args[0].pos,
            //expr:EConst(CIdent("f"))
        //}

        //var call ={pos:args[0].pos,
            //expr:ECall(f_ref, )
        //}
        return macro {
            var p = new Promise<Dynamic>();
            //var parr:Array<Promise<Dynamic>> = $eargs; 
            // "then" function for the promise closure
            var pthen =  function(f:Dynamic){
                // "then" function callback for each promise
                var cthen = function(v:Dynamic){
                    if (untyped Promise.allSet(parr)){
                        var vals = [];
                        for (pv in parr) vals.push(untyped pv._val);
                        //try p.resolve($call)
                        //catch (e:Dynamic) p.handleError(e);
                    }
                }
                cthen(null);
                for (p in parr) p.then(cthen);
                return p;
            }
            var ret = {then:pthen};
            return ret;
        }
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
        return this;
    }

    /**
      Handle errors 
     **/
    private function handleError(d:Dynamic){
        if (_errorf != null) _errorf(d)
        else if (_error.length == 0) throw d
        else for (ef in _error) ef(d);
    }

    /**
      add a wait function directly to the Promise instance.
     **/
    public function then<A>(f:T->A):Promise<A>{
        var ret = new Promise<A>();
        _update.push(f);
        _error.push(ret.handleError);
        return ret;
    }


    /**
      Rejects the promise, throwing an error.
     **/
    public function reject(e:Dynamic){
        _update = new Array<T->Dynamic>();
        handleError(e);
    }
    /**
      Converts any value to a Promise
     **/
    public static function promise<T>(_val:T) : Promise<T>{
        var ret = new Promise<T>();
        ret.resolve(_val);
        return ret;
    }
}



