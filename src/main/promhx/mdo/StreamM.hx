package promhx.mdo;
import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;

class StreamM {

    macro public static function dO(body : Expr)  // the function to trigger the Monad macro.
    {
        // wrap the monad chain in a promise, to catch initialization errors.
        return macro promhx.Stream.stream(null).pipe(function(_){
            return ${Monad._dO("promhx.mdo.StreamM", body, Context)};
        });
    }

    inline public static function ret<A>(x : A) // creates an element
        return Stream.stream(x);

    inline public static function map < A, B > (x : Stream<A>, f : A -> B) 
        return x.then(f);

    inline public static function flatMap<A, B>(x : Stream<A>, f : A -> Stream<B>)
        return x.pipe(f);
}
