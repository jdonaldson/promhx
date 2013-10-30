package promhx;
class EventQueue {

    // We can get better performace on js targets with a small shim.  Respect noEmbedJs
    // in case dev doesn't want to use any polyfills.
#if (js && !noEmbedJS)
    static function __init__() untyped {
#if (!nodejs)
        // if we're not on nodejs, "this" won't be  "window" since we are in
        //an enclosing function.  So, set the global to window and use that
        var global = window;
#end
        haxe.macro.Compiler.includeFile("lib/setImmediate/setImmediate.js");
    }
#end

    // if not js this can be inlined
#if !js inline #end
    public static function setImmediate(f:Void->Void):Void {
#if flash
        haxe.Timer.delay(f,0);
#elseif js
        untyped __js__("typeof setImmediate == 'function' ? setImmediate(f) : setTimeout(f)");
#else
        f();
#end
    }

}
