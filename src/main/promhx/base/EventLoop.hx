package promhx.base;

private typedef Queue = #if java java.vm.AtomicList #else List #end <Void->Void>;

class EventLoop {
    static var queue : Queue = new Queue();

    // public static var nextLoop(default, set) : (Void->Void)-> Void;
    public static var nextLoop : (Void->Void)-> Void;

    static function __init__() untyped {
#if js
#if (!nodejs && !noEmbedJs && embedSetImmediate)
        if (__js__("typeof window != 'undefined'")){
            haxe.macro.Compiler.includeFile("lib/setImmediate/setImmediate.js");
        }
#end
        nextLoop = __js__("typeof(setImmediate) === 'function' ? function(x){setImmediate(x)}: function(x){setTimeout(x,0)}");
#elseif flash
        nextLoop = function(x)  haxe.Timer.delay(x,0);
#else
        nextLoop = function(x) x();
#end
    }

    public static inline function enqueue(eqf:Void->Void)  {
        queue.add(eqf);
        nextLoop(f);
    }

    static function set_nextLoop(f : (Void->Void)->Void) : Void{
        nextLoop = f;
    }

    /**
      Retrieve the current length of the queue.
     **/
    public static inline function queueEmpty() {
        return #if java queue.peekLast() == null #else queue.isEmpty() #end;
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
        if (!queueEmpty()) nextLoop(f);
    }

}
