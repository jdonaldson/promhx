package promhx.haxe;
import promhx.Stream;
#if (js || flash)
typedef EventListener = {
    function addEventListener(
            type        : String,
            listener    : Dynamic->Void,
            ?useCapture : Bool
#if flash
            ,
            ?priority         : Int,
            ?useWeakReference : Bool
#end
            ) : Void;
}

/**
  A simple utility class for creating Stream instances from standard callback
  handling instances in js and flash.
 **/
class EventTools {
    /**
      Create a Stream<Dynamic> instance from an instance that manages event 
      listeners.  Intended to be utilized via using :
      var stream = element.eventStream('click');
      var stream = movie_clip.eventStream(Events.CLICK);
     **/
    public static function eventStream(
            el : EventListener, 
            event : String, 
            ?useCapture : Bool 
#if flash
            ,
            ?priority : Int,
            ?useWeakReference : Bool
#end
            ){
            var def = new Deferred<Dynamic>();
            el.addEventListener(event, def.resolve, useCapture);
            return def.promise();
        }
}

#end

