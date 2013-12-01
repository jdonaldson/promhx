package js.promhx;
import promhx.Stream;
import promhx.Promise;
import js.JQuery;
import js.JQuery.JqEvent;
import js.html.MouseEvent;
import js.html.WheelEvent;

typedef LoadResponse = {
    responseText : String,
    textStatus : String,
}

/**
  A collection of utility methods intended to be used via the "using" import
  directive.
 **/
class JQueryTools {
    /**
      Wraps functions that accept callbacks, and enables them to
      return Stream<JqEvent> instead.
     **/
    public static function bindStream
        (f:(JqEvent->Void)->JQuery) : Stream<JqEvent>
        {
            var str = new Stream<JqEvent>();
            f(str.update);
            return str;
        }

    /**
      An equivalent for the JQuery "on" method.  Provide one or more events
      to listen for, and a Stream will be created for them.
     **/
    public static function eventStream
        ( jq : JQuery, events : String) : Stream<JqEvent>
        {
            var str = new Stream<JqEvent>();
            jq.on(events, str.update);
            return str;
        }


    /**
      An equivalent for the JQuery "load" method.  Provide the url and relevant
      data arguments, and the results will be delivered as a Promise.
     **/
    public static function loadPromise
        ( jq : JQuery, url : String, ?data : {} ) : Promise<LoadResponse>
        {
            var pro = new Promise<LoadResponse>();
            jq.load(url, data, function(responseText, textStatus){
                pro.resolve({
                    responseText  : responseText,
                    textStatus    : textStatus
                });
            });
            return pro;
        }

}
