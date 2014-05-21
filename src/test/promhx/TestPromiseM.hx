
package promhx;
import promhx.mdo.PromiseM;
import utest.Assert;

class TestPromiseM {
    public function new(){}
    public function testSimpleDo(){
        var expected1 = 10;
        var expected2 = 'foo';
        var actual1 = 0;
        var actual2 = 'bar';
        var d1 = new Deferred<Int>();
        var d2 = new Deferred<String>();
        var p1 = d1.promise(); 
        var p2 = d2.promise(); 
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
        d1.resolve(10);
        d2.resolve('foo');
    }

    public function testError() {
        var expected = "Test Error";
        var actual = "";
        var async = Assert.createAsync(function(){
            Assert.equals(actual, expected);
        });
        PromiseM.dO({
            throw expected;
        }).catchError(function(err){
            actual = err;
            async();
        });
    }

}
