/****  Copyright (c) 2013 Justin Donaldson
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
****/

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
