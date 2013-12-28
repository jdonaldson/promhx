package promhx.mdo;
import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;

class PromiseM {

    macro public static function dO(body : Expr)  // the function to trigger the Monad macro.
    {
        // wrap the monad chain in a promise, to catch initialization errors.
        return macro Promise.promise(null).pipe(function(_){
            return ${Monad._dO("promhx.mdo.PromiseM", body, Context)};
        });
    }

    inline public static function ret<A>(x : A) // creates an element
        return Promise.promise(x);

    inline public static function map <A, B> (x : Promise<A>, f : A -> B)
        return x.then(f);

    inline public static function flatMap<A, B>(x : Promise<A>, f : A -> Promise<B>)
        return x.pipe(f);
}
