package promhx;
import haxe.macro.Expr;
import tink.macro.tools.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
using tink.macro.tools.TypeTools;
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

    /**
      Utility function to determine if all Promise values are set.
     **/
    public static function allSet(as:Array<Promise<Dynamic>>): Bool{
        for (a in as) if (!a._set) return false;
        return true;
    }

    @:macro public static function when<T>(args:Array<ExprRequire<Promise<Dynamic>>>):Expr{
        // just using a simple pos for all expressions
        var pos = args[0].pos;

        //the types of all the arguments (should be all Promises)
        var types = args.map(Context.typeof);

        //the parameters of the Promise types
        var ptypes = types.map(function(x) switch(x){
            case TInst(t,params): return params[0];
            default : throw("Somehow, an illegal promise value was passed");
        });

        //The complex types of the promise parameters
        var cptypes = ptypes.map(function(x) return x.toComplex(true)).array();
        //The unknown type for the then function, also used for the promise return
        var ctmono = Context.typeof(macro null).toComplex(true);
        //The complex "then" function signature
        var cfexpr = TFunction(cptypes,ctmono);
        //the macro arguments expressed as an array expression.
        var eargs = {expr:EArrayDecl(args),pos:pos};
        // An array of promise values
        var epargs = args.map(function(x) {
            return {expr:EField(x,"_val"),pos:pos}
        }).array();
        // A call expression on f using the array of promise values
        var ecall = {expr:ECall(macro f, epargs),pos:pos}

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



