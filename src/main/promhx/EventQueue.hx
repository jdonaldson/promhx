package promhx;
class EventQueue {
    static var _next:(Void->Void)->Void;
    static var setImmediate:(Void->Void)-> Void;
    static var setTimeout:(Void->Void)-> Void;

#if (js || flash)
    static function __init__() untyped {
        
#if (js && !noEmbedJS)
        var global:Dynamic = {};
        haxe.macro.Compiler.includeFile("lib/setImmediate/setImmediate.js");
        setImmediate = global.setImmediate;
#end

#if js
        _next = __js__("typeof setImmediate == 'function' ? setImmediate : setTimeout");
#elseif flash
        _next = haxe.Timer.delay.bind(_,0);
#end
    }
#end


    static function typeof(x: Dynamic) : String untyped {
#if js
        return  __js__("typeof x");
#elseif flash
        return  __typeof__(x);
#else
        throw "typeof not supported on this platform";
        return null;
#end
    }

    public static inline function next(f) _next(f);

}
