import haxe.Http;
import haxe.remoting.HttpAsyncConnection;
import promhx.Promise;
using DemoUtils.HttpExtensions;
class DemoUtils {

    static function main() {
        var h1 = new Http("foo.txt").promise();
        var h2 = new Http("bar.txt").promise();
        Promise.when(h1,h2).then(function(x,y) trace (x + y ));
    }

}

class HttpExtensions{
    public static function promise(h:Http,request = false){
        var p = new Promise<String>();
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
