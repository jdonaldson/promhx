// import js.Browser;
// import js.JQuery;
import promhx.Stream;
using js.promhx.JQueryTools;
import js.JQuery;
import promhx.mdo.StreamM;
import promhx.mdo.PromiseM;
using promhx.haxe.EventTools;

class Demo {
    static function main() {
        var j = new JQuery("#status").eventStream('focus');
        var h = new promhx.haxe.Http("test.txt");
        h.then(function(x){
            trace(x);
        });
        h.request();
        j.then(function(x){
            trace(x);
        });
    }
}
