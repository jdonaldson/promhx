
package promhx;
import haxe.unit.TestCase;
import promhx.PromiseM;

class TestPromiseM extends TestCase {
    public function testSimpleDo(){
        var p1 = new Promise<Int>();
        var p2 = new Promise<String>();

        var p3 = PromiseM.dO({
            val1 <= p1;
            val2 <= p2;
            val3 <= p2;
            ret({val1:val1, val2:val2});
        });
        p3.then(function(y) {
            assertEquals(y.val1, 10);
            assertEquals(y.val2, 'foo');
        });

        p1.resolve(10);
        p2.resolve('foo');

    }



}
