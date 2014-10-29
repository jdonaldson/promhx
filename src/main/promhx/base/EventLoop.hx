package promhx.base;

private typedef Queue = #if java java.vm.AtomicList #else List #end <Void->Void>;

class EventLoop {
    static var queue : Queue = new Queue();

    // public static var nextLoop(default, set) : (Void->Void)-> Void;
    public static var nextLoop : (Void->Void)-> Void;

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
        queue.add(eqf);
        continueOnNextLoop();
    }
    static function set_nextLoop(f : (Void->Void)->Void) : (Void->Void)->Void{
        if (nextLoop != null) throw "nextLoop has already been set";
        else nextLoop = f;
        return nextLoop;
    }

    /**
      Retrieve the current length of the queue.
     **/
    public static inline function queueEmpty() {
        return #if java queue.peek() == null #else queue.isEmpty() #end;
    }

    /**
      Attempt to finish the remaining loops in the queue.  Returns true
      if all loops are finished.  If [max_iterations] pass, then exit and
      return false.
     **/
    public static function finish(max_iterations = 1000){
        var fn = null;
        while (max_iterations-- > 0 && (fn = queue.pop()) != null){
            fn();
        }
        return queueEmpty();
    }

    /**
      Clear the existing event loop queue.
     **/
    public static function clear(){
        queue = new Queue();
    }

    static function f(){
        var fn = queue.pop();
        if (fn != null) fn();
        if (!queueEmpty()) continueOnNextLoop();
    }

    static function continueOnNextLoop(){
        if (nextLoop != null) nextLoop(f);
        else {

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
}
