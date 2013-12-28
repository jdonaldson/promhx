package js.promhx;

import js.html.Element;
import promhx.Stream;
import js.html.MouseEvent;
import js.html.WheelEvent;
import js.html.TouchEvent;

class DomTools {
    inline static function buildEventStream<T>
        (e : Element, event : String, stream : Stream<T>) : Stream<T>
        {
            e.addEventListener('event', stream.resolve);
            return stream;
        }

// mouse events
    public static function mouseupStream(e : Element)   
        return buildEventStream(e, 'mouseover', new Stream<MouseEvent>());
    public static function mouseoutStream(e : Element)      
        return buildEventStream(e, 'mouseout', new Stream<MouseEvent>());
    public static function mousedownStream(e : Element)     
        return buildEventStream(e, 'mousedown', new Stream<MouseEvent>());
    public static function mousemoveStream(e : Element)     
        return buildEventStream(e, 'mousemove', new Stream<MouseEvent>());
    public static function mouseoverStream(e : Element)     
        return buildEventStream(e, 'mouseover', new Stream<MouseEvent>());

// wheel events
    public static function mousewheelStream(e : Element)   
        return buildEventStream(e, 'mousewheel', new Stream<WheelEvent>());


}
