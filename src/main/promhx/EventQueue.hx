package promhx;
class EventQueue {

#if (js && !nodejs && !noEmbedJs && !noEmbedSetImmediate)
    static function __init__() untyped {
#if !nodejs
        // we need to use global as an alternate since setImmediate expects this == window
        var global = window;
#end
        haxe.macro.Compiler.includeFile("lib/setImmediate/setImmediate.js");
    }
#end

    public static inline function setImmediate(f:Void->Void)  {
#if flash
        haxe.Timer.delay(f,0);
#elseif (js && (noEmbedJs || noEmbedSetImmediate) && !nodejs)
        // fallback to setTimeout
        untyped __js__("(typeof setImmediate === 'function' ? setImmediate : setTimeout)")(f);
#elseif js
        // use polyfill or native node
        untyped __js__("setImmediate")(f);
#else
        f();
#end
    }
}
