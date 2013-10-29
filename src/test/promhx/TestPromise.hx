
package promhx;
import promhx.Promise;
import utest.Assert;

class TestPromise {
    public function new(){}

    public function testSimpleThen(){
        var p1 = new Promise<Int>();
        var expected = 1;
        var actual = null;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        p1.then(function(x) {
            actual = x;
            async();
        });
        p1.resolve(expected);
    }

    public function testSimpleWhen(){
        var expected1 = 4;
        var expected2 = 5;
        var p1        = new Promise<Int>();
        var p2        = new Promise<Int>();
        var expected = expected1 + expected2;
        var actual = null;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        Promise.when(p1,p2).then(function(x,y){
            actual = x + y;
            async();
        });
        p1.resolve(expected1);
        p2.resolve(expected2);
    }

    public function testChainedThen(){
        var expected1 = 1;
        var expected2 = 2;
        var p1        = new Promise<Int>();
        var p2        = p1.then(function(x){
            return expected2;
        });
        var expected = expected2;
        var actual = null;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        p2.then(function(x){
            actual = x;
            async();
        });
        p1.resolve(expected1);
    }


}
