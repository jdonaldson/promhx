package promhx.base;

private typedef Queue = #if java java.vm.AtomicList #else List #end <Void->Void>;

class EventLoop {
    static var queue : Queue = new Queue();

    // public static var nextLoop(default, set) : (Void->Void)-> Void;
    public static var nextLoop : (Void->Void)-> Void;

    static function __init__() untyped {
#if (js && !noEmbedJs && !noEmbedAsap)
        __js__("var module = {}");
#if nodejs
        // gives a ~ 20% speedup
        haxe.macro.Compiler.includeFile("lib/asap/raw.js");
        nextLoop = rawAsap; 
#else 
        if (js.Browser.supported){
            // gives a ~ 60% speedup
            var global = window;
            haxe.macro.Compiler.includeFile("lib/asap/browser-raw.js");
            nextLoop = rawAsap; 
        } else {
            nextLoop = function(x) haxe.Timer.delay(x,0);
        }
#end
#elseif (flash || java || python || js)
        nextLoop = function(x)  haxe.Timer.delay(x,0);
#else
        nextLoop = function(x) x();
#end
    }

    public static inline function enqueue(eqf:Void->Void) : Void {
        if (queueEmpty()){
            queue.add(eqf);
            nextLoop(f);
        } else {
            queue.add(eqf);
            nextLoop(f);
        }
    }

    /**
      Returns true if the queue is empty
     **/
    public static inline function queueEmpty() : Bool {
        return #if java queue.peekLast() == null #else queue.isEmpty() #end;
    }

    /**
      Attempt to finish the remaining loops in the queue.  Returns true
      if all loops are finished.  If [max_iterations] pass, then exit and
      return false.
     **/
    public static function finish(max_iterations = 1000) : Bool {
        var fn = null;
        while (max_iterations-- > 0 && (fn = queue.pop()) != null){
            fn();
        }
        return queueEmpty();
    }

    /**
      Clear the existing event loop queue.
     **/
    public static function clear() : Void {
        queue = new Queue();
    }

    static function f() : Void {
        var fn = queue.pop();
        if (fn != null) fn();
        // if (!queueEmpty()) nextLoop(f);
    }

}
