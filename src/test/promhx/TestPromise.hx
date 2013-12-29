
package promhx;
import promhx.Promise;
import utest.Assert;

class TestPromise {

    public function new(){}

    public function testSimplePipe(){
        var expected = 1;
        var actual = 0;
        var p1 = new Promise<Int>();
        var p2 = new Promise<Int>();
        var async = Assert.createAsync(function(){
            Assert.equals(expected,actual);
        });
        p1.pipe(function(x) {
            p2.resolve(expected);
            return p2;
        });
        p2.then(function(x){
            actual = x;
            async();
        });
        p1.resolve(0);
    }

    public function testPromiseUnlinkError(){
        var p = new Promise<Int>();
        var p2 = p.then(function(x){
            return x + 1;
        });
        var expected = true;
        var actual = false;
        var async = Assert.createAsync(function(){
            Assert.equals(expected,actual);
        });
        p.unlink(p2);
        p.catchError(function(x){
            actual = true;
            async();
        });
    }

    public function testEmptyWhenAll(){
        var expected = 0;
        var actual = 1;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        Promise.whenAll([]).then(function(x){
            actual = x.length;
            async();
        });
    }

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

    public function testAsynchronousResolving(){
        var p1 = new Promise<Int>();
        p1.resolve(0);
        Assert.isTrue(p1.isPending(), "p1 was not resolving, should be asynchronous");
    }


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
        }).catchError(function(e){
            error = true;
            async();
        });
        p1.resolve(0);
        p2.resolve(0);
    }

    public function errorThen(){
        var p1 = new Promise<Int>();
        var expected = 1;
        var actual = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        p1.then(function(x){
            throw true;
            return 2;
        }).errorThen(function(x){
            return 1;
        }).then(function(x){
            actual = x;
            async();
            return 2;
        });
        p1.resolve(1);
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
        }).catchError(function(e){
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
