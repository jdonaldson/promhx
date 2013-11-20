package promhx.util;
import de.polygonal.ds.ArrayedQueue;

class EventQueue {
    static var queue = new ArrayedQueue<Void->Void>(10);

#if (js && !nodejs && !noEmbedJs && !noEmbedSetImmediate)
    static function __init__() untyped {
#if !nodejs
        // we need to use global as an alternate since setImmediate expects this == window
        var global = window;
#end
        haxe.macro.Compiler.includeFile("lib/setImmediate/setImmediate.js");
    }
#end

    public static inline function enqueue(eqf:Void->Void)  {
        queue.enqueue(eqf);
        continueOnNextLoop();
    }
    static function continueOnNextLoop(){
        var f = function(){
            if (queue.size() > 0) {
                queue.dequeue()();
                continueOnNextLoop();
            }
        }
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
