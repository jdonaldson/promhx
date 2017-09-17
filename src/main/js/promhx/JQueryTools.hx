package js.promhx;

import promhx.Stream;
import promhx.Promise;
import promhx.Deferred;
import js.jquery.JQuery;
import js.jquery.Event;
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
      return Stream<Event> instead.
     **/
    public static function bindStream
        (f:(Event->Void)->JQuery) : Stream<Event>
        {
            var def = new Deferred<Event>();
            var str = new Stream(def);
            f(def.resolve);
            return str;
        }

    /**
      An equivalent for the JQuery "on" method.  Provide one or more events
      to listen for, and a Stream will be created for them.
     **/
    public static function eventStream
        ( jq : JQuery, events : String) : Stream<Event>
        {
            var def = new Deferred<Event>();
            var str = new Stream(def);
            jq.on(events, def.resolve);
            return str;
        }


    /**
      An equivalent for the JQuery "load" method.  Provide the url and relevant
      data arguments, and the results will be delivered as a Promise.
     **/
    public static function loadPromise
        ( jq : JQuery, url : String, ?data : {} ) : Promise<LoadResponse>
        {
            var def = new Deferred<LoadResponse>();
            var pro = new Promise(def);
            jq.load(url, data, function(responseText, textStatus, jqxhr){
                def.resolve({
                    responseText  : responseText,
                    textStatus    : textStatus
                });
            });
            return pro;
        }

}
