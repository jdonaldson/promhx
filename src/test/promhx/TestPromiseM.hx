
package promhx;
import promhx.PromiseM;
import utest.Assert;

class TestPromiseM {
    public function new(){}
    public function testSimpleDo(){
        var expected1 = 10;
        var expected2 = 'foo';
        var actual1 = 0;
        var actual2 = 'bar';
        var p1 = new Promise<Int>();
        var p2 = new Promise<String>();
        var val2 = null;
        var p3 = PromiseM.dO({
            val1 <= p1;
            val2 <= p2;
            ret({val1:val1, val2:val2});
        });

        var async = Assert.createAsync(function(){
            Assert.equals(expected1, actual1);
            Assert.equals(expected2, actual2);
        });
        p3.then(function(y) {
            actual1 = y.val1;
            actual2 = y.val2;
            async();
        });

        p1.resolve(10);
        p2.resolve('foo');

    }



}
