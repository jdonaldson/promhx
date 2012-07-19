import haxe.Http;
import js.Lib;
import haxe.remoting.HttpAsyncConnection;
import promhx.Promise;
using DemoUtils.HttpExtensions;
using Lambda;
class DemoUtils {
    static var jsonps:Dynamic<String->Dynamic> = {}
    static var jsonpsctr = 1;
    static function main() {
        var err = function(x) trace(x);
        var k = jsonp('http://api.twitter.com/1/users/show.json?screen_name=meltingice');
        var l = jsonp('http://api.twitter.com/1/users/show.json?screen_name=sudojudo');
        Promise.when(k,l).then(function(x,y){
            trace(x);
            trace(y);
        });
    }

    static function jsonp<T>(url:String, ?data:Dynamic<Dynamic>):Promise<T>{
        var err = function(x) trace(x);
        var p = new Promise<T>();

        var cb = url + "&callback="+StringTools.urlEncode("DemoUtils.jsonps.a"+jsonpsctr);
        Reflect.setField(jsonps,'a'+jsonpsctr, p.resolve);
        jsonpsctr++;
        var head = Lib.document.getElementsByTagName('head')[0];
        var script = Lib.document.createElement('script');
        untyped script.type = 'text/javascript';
        untyped script.src = cb;
        head.appendChild(script);
        return p;
    }
}

class HttpExtensions{
    public static function promise(h:Http,request = false, ?err:Dynamic->Dynamic){
        var p = new Promise<String>(err);
        h.onError = p.reject;
        var set = false;
        h.onData = function(x){
            if (!set) p.resolve(x);
            else set = true;
        }
        h.request(request);
        return p;
    }
}
