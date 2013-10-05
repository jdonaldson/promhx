
package promhx;
import haxe.unit.TestCase;
import promhx.PromiseM;

class TestMPromhx extends TestCase {

    public function testSimpleThen(){
        var p1 = new Promise<Int>();
        var p2 = new Promise<String>();

        // 1) promise monad
        PromiseM.dO({
            val1 <= p1;
            val2 <= p2;
            ret({val1:val1, val2:val2});
        }).then(function(x) trace(x));

        // 2) old promise interface
        Promise.when(p1,p2)
            .then(function(val1,val2) trace({val1:val1, val2:val2}));

        p1.resolve(10);
        p2.resolve('foo');

        assertEquals(1,1);
    }


}
