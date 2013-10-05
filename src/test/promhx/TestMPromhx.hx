
package promhx;
import haxe.unit.TestCase;
import promhx.PromiseM;

class TestMPromhx extends TestCase {

    public function testSimpleThen(){
#if js
        js.Lib.debug();
#end
        var p10 = new Promise<Int>();
        var p20 = new Promise<String>();
        var k = PromiseM.dO({
            p1 <= p10;
            p2 <= p20;
            p3 <= ret(p1 + p2 + '!');
        });
        p10.resolve(0);
        p20.resolve('hi');
        k.then(function(x) trace(x));
        assertEquals(1,1);
    }


}
