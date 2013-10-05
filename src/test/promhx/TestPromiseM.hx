
package promhx;
import haxe.unit.TestCase;
import promhx.PromiseM;

class TestPromiseM extends TestCase {
    public function testSimpleDo(){
        var p2 = new Promise<String>();
        var p1 = new Promise<Int>();

        var p3 = PromiseM.dO({
            val1 <= p1;
            val2 <= p2;
            ret({val1:val1, val2:val2});
        }).then(function(y) trace(y.val2));


        p1.resolve(10);
        p2.resolve('foo');

        assertEquals(1,1);
    }



}
