
package promhx;
#if macro
import haxe.macro.Expr;
using tink.macro.tools.TypeTools;
#end

using Lambda;

class Promise<T> {
    macro public static function when<T>(args:Array<Expr>):Expr{
        return macro 'hi';
    }

}



