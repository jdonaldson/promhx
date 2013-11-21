import js.Browser;
import js.JQuery;
using js.promhx.JQueryTools;
import promhx.Stream;

class Demo {
    static function main() {
        var target1 = new JQuery("#target1"),
            target2 = new JQuery("#target2"),
            s1 = target1.clickStream(),
            s2 = target2.clickStream(),
            markclicked = function(id:Int, x:JqEvent){
                x.currentTarget.innerHTML = 'target $id clicked';
            };

        s1.then(markclicked.bind(1,_));
        s2.then(markclicked.bind(2,_));
        
        var status = new JQuery("#status");
        var s3 = Stream.whenever(s1,s2).then(function(x,y){
            status.html('clicked target 1 on ${x.timeStamp} 
                    and  clicked target 2 on ${y.timeStamp}');
        });
    }
}
