
package promhx;
import haxe.unit.TestCase;
import promhx.Promise;

class TestPromhx extends TestCase {
    public function testThen(){
        var p1 = new Promise<Int>();
        p1.then(function(x) trace("delivered " + x));
        p1.resolve(1);
    }
}
