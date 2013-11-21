package js.promhx;
import js.JQuery;
import js.JQuery.JqEvent;
import promhx.Stream;
class JQueryTools {
    public static function eventStream(jq : JQuery, events : String) : Stream<JqEvent> {
        var s = new Stream<JqEvent>();
        jq.on(events, s.update);
        return s;
    }
    public static function clickStream(jq : JQuery) : Stream<JqEvent> {
        var s = new Stream<JqEvent>();
        jq.on('click', s.update);
        return s;
    }
}
