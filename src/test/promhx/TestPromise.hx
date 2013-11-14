
package promhx;
import promhx.Promise;
import utest.Assert;

class TestPromise {
    public function new(){}

    public function testSimpleThen(){
        var p1 = new Promise<Int>();
        var expected = 1;
        var actual:Int = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        p1.then(function(x) {
            actual = x;
            async();
        });
        p1.resolve(expected);
    }


    public function testResolved(){
        var p1 = new Promise<Int>();
        p1.resolve(0);
        Assert.isTrue(p1.isResolved());
    }

#if (js || flash)
    public function testAsynchronousResolving(){
        var p1 = new Promise<Int>();
        p1.resolve(0);
        Assert.isTrue(p1.isFulfilling(), "p1 was not resolving, should be asynchronous");
    }

#else
    public function testSynchronousResolving(){
        var p1 = new Promise<Int>();
        p1.resolve(0);
        Assert.isTrue(!p1.isFulfilling(),  "p1 was resolving, should be synchronous");
    }
#end


    public function testSimpleWhen(){
        var expected1 = 4;
        var expected2 = 5;
        var p1        = new Promise<Int>();
        var p2        = new Promise<Int>();
        var expected = expected1 + expected2;
        var actual = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        var p3 = Promise.when(p1,p2).then(function(x,y){
            actual = x + y;
            async();
        });
        p1.resolve(expected1);
        p2.resolve(expected2);
    }

    public function testSimpleWhenError(){
        var p1        = new Promise<Int>();
        var p2        = new Promise<Int>();
        var error = false;
        var async = Assert.createAsync(function(){
            Assert.isTrue(error);
        });
        Promise.when(p1, p2).then(function(x, y){
            throw "an error";
        }).error(function(e){
            error = true;
            async();
        });
        p1.resolve(0);
        p2.resolve(0);
    }

    public function testSimpleWhenReject(){
        var p1        = new Promise<Int>();
        var p2        = new Promise<Int>();
        var error = false;
        var async = Assert.createAsync(function(){
            Assert.isTrue(error);
        });
        Promise.when(p1,p2).then(function(x,y){
            Assert.isTrue(false, "The 'then' method should not trigger"); //or whatever make the test fail
        }).error(function(e){
            error = true;
            async();
        });
        p1.reject("error");
        p2.resolve(0);
    }

    public function testChainedThen(){
        var resolved1 = 1;
        var resolved2 = 2;
        var p1        = new Promise<Int>();
        var p2        = p1.then(function(x){
            return resolved2;
        });
        var expected = resolved2;
        var actual = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        p2.then(function(x){
            actual = x;
            async();
        });
        p1.resolve(resolved1);
    }


}
