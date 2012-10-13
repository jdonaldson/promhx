package promhx;
#if macro
import haxe.macro.Expr;
import tink.macro.tools.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
using tink.macro.tools.TypeTools;
#end
using Lambda;
class Promise<T> {
    private var _val:T;
    private var _set:Bool;
    private var _update:Array<T->Dynamic>;
    private var _error:Array<Dynamic->Dynamic>;
    private var _errorf:Dynamic->Dynamic;

    /**
      Constructor argument can take optional function argument, which adds
      a callback to the error handler chain.
     **/
    public function new(?errorf:Dynamic->Dynamic){
        _set = false;
        _update = new Array<T->Dynamic>();
        _error = new Array<Dynamic->Dynamic>();
        if (errorf != null) _error.push(errorf);
    }

    /**
      Specify an error handling function
     **/
    public function error(f:Dynamic->Dynamic) {
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

    /**
      Macro method that binds the promise arguments to a single function
      callback that is triggered when all promises are resolved.
      Note: You may call this function on as many promise arguments as you
      like. The overloads give just two examples of usage.
     **/
    @:overload(function<A,B,C>(arg1:Promise<A>, arg2:Promise<B>):{then:(A->B->C)->Promise<C>}{})
    @:overload(function<A,B,C,D>(arg1:Promise<A>, arg2:Promise<B>, arg3:Promise<C>):{then:(A->B->C->D)->Promise<D>}{})
    @:macro public static function when<T>(args:Array<ExprOf<Promise<Dynamic>>>):Expr{
        // just using a simple pos for all expressions
        var pos = args[0].pos;
        // Dynamic Complex Type expression
        var d = TPType("Dynamic".asComplexType());
        // Generic Dynamic Complex Type expression
        var p = "promhx.Promise".asComplexType([d]);
        var ip = "Iterable".asComplexType([TPType(p)]);
        //The unknown type for the then function, also used for the promise return
        var ctmono = Context.typeof(macro null).toComplex(true);
        var eargs:Expr; // the array of promises
        var ecall:Expr; // the function call on the promises
        var cfexpr:ComplexType; // the type signature for the function callback
        for (a in args){
            if (ExprTools.is(a,ip)){
                if (args.length > 1) {
                    Context.error("Only a single Iterable of Promises can be passed", a.pos);
                }
                var cptypes = [Context.typeof(a).toComplex(true)];
                eargs = a;
                ecall = macro {
                    var arr = [];
                    for (a in $a) arr.push(a._val);
                    f(arr);
                }
            }
            else if (ExprTools.is(a,p)){
                //the types of all the arguments (should be all Promises)
                var types = args.map(Context.typeof);
                //the parameters of the Promise types
                var ptypes = types.map(function(x) switch(x){
                    case TInst(t,params): return params[0];
                    default : {
                        Context.error("Somehow, an illegal promise value was passed",pos);
                        return null;
                    }
                });
                 var cptypes = ptypes.map(function(x) return x.toComplex(true)).array();
                //the macro arguments expressed as an array expression.
                eargs = {expr:EArrayDecl(args),pos:pos};
                var cfexpr = TFunction(cptypes,ctmono);

                // An array of promise values
                var epargs = args.map(function(x) {
                    return {expr:EField(x,"_val"),pos:pos}
                }).array();
                ecall = {expr:ECall(macro f, epargs), pos:pos}

            } else{
                Context.error("Arguments must all be Promise types, or a single Iterable of Promise types",a.pos);
            }
        }



        // the returned function that actually does the runtime work.
        return macro {
            var parr:Array<Promise<Dynamic>> = $eargs;
            var p = new Promise<$ctmono>();
            {
                then:function(f:$cfexpr){
                     //"then" function callback for each promise
                    var cthen = function(v:Dynamic){
                        if ( Promise.allSet(parr)){
                            try{ untyped $ecall; }
                            catch(e:Dynamic){
                                untyped p.handleError(e);
                            }
                        }
                    }
                    cthen(null);
                    for (p in parr) p.then(cthen);
                    return p;
                }
            }
        }
    }

    //TODO: try to figure out how to do this cleanly with the existing when function
    //public static function whenCol<T>(arg:Iterable<Promise<Dynamic>>):{then:(Iterable<Dynamic>->T)->Promise<T>}{
    //    var p = new Promise<T>();
    //    return {
    //        then:function(f:Iterable<Dynamic>->T) {
    //            //"then" function callback for each promise
    //            var cthen = function(v:Dynamic){
    //                if (Promise.allSet(arg)){
    //                    var vals = [];
    //                    for (a in arg) vals.push(a._val);
    //                    try{
    //                        f(vals);
    //                    }catch(e:Dynamic){
    //                        p.handleError(e);
    //                    }
    //                }
    //            }
    //            cthen(null);
    //            for (p in arg) p.then(cthen);
    //            return p;
    //        }
    //    }
    //}

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
    public static function promise<T>(_val:T, ?errorf:Dynamic->Dynamic) : Promise<T>{
        var ret = new Promise<T>(errorf);
        ret.resolve(_val);
        return ret;
    }
}



