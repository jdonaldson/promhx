// import js.Browser;
// import js.JQuery;
import promhx.Stream;
using js.promhx.JQueryTools;
import js.JQuery;
import promhx.mdo.StreamM;
import promhx.mdo.PromiseM;
using promhx.haxe.EventTools;
import promhx.haxe.http.Cancel;

class Demo {
    static function main() {
        var j = new JQuery("#status").eventStream('focus');
        var h = new promhx.haxe.Http("test.txt");
        h.then(function(x){
            js.Browser.alert(x);
        });
        h.request();
        h.cancel();
        h.status.then(function(x){
            trace(x);
        });
        h.catchError(function(x){
            trace(h);
            try throw(x)
            catch(e:Cancel) {
                trace("cancelled for a good reason: ");
                trace(e.reason);
            }
                
        });
        j.then(function(x){
            trace(x);
        });
    }
}

class Message {
    public var content(default, null) : String; 
    public function new(content : String){
        this.content = content;
    }
}
