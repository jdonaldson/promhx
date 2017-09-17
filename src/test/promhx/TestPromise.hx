
package promhx;
import promhx.Promise;
import utest.Assert;
import promhx.deferred.DeferredStream;
import promhx.deferred.DeferredPromise;

using Lambda;

class TestPromise {

    public function new(){}

    public function testThenOnErroredPromise(){
        var p = new promhx.Promise<Int>();
        var expected = 7;
        var actual = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });

        p.then(function(a){
            return 1;
        }).catchError(function(e){
            actual += 3;
        });


        p.reject(2);

        p.then(function(a){
            return 1;
        }).catchError(function(e){
            actual += 4;
            async();
        });

    }

    public function testSimplePipe(){
        var expected = 1;
        var actual = 0;
        var d1 = new Deferred<Int>();
        var d2 = new Deferred<Int>();
        var p1 = d1.promise(); 
        var p2 = d2.promise(); 
        var async = Assert.createAsync(function(){
            Assert.equals(expected,actual);
        });
        p1.pipe(function(x) {
            d2.resolve(expected);
            return p2;
        });
        p2.then(function(x){
            actual = x;
            async();
        });
        d1.resolve(0);
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
            return null;
        });
    }

    public function testSimpleThen(){
        var d1 = new Deferred<Int>();
        var p1 = d1.promise();
        var expected = 1;
        var actual:Int = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        p1.then(function(x) {
            actual = x;
            async();
        });
        d1.resolve(expected);
    }


    public function testResolved(){
        var expected = 1;
        var actual = 0;
        var d1 = new Deferred<Int>();
        var p1 = d1.promise();
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        d1.then(function(x) {
            actual = x;
            async();
        });
        d1.resolve(expected);
    }

    public function testAsynchronousResolving(){
        var d1 = new Deferred<Int>();
        var p1 = d1.promise();
        d1.resolve(0);
        Assert.isTrue(d1.isPending(), "d1 was not resolving, should be asynchronous");
    }


    public function testSimpleWhen(){
        var expected1 = 4;
        var expected2 = 5;
        var d1        = new Deferred<Int>();
        var d2        = new Deferred<Int>();
        var p1        = d1.promise();
        var p2        = d2.promise();
        var expected  = expected1 + expected2;
        var actual    = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        var p3 = Promise.when(p1,p2).then(function(x,y){
            actual = x + y;
            async();
            return null;
        });
        d1.resolve(expected1);
        d2.resolve(expected2);
    }

    public function testSimpleWhenError(){
        var d1        = new Deferred<Int>();
        var d2        = new Deferred<Int>();
        var p1        = d1.promise(); 
        var p2        = d2.promise(); 
        var error = false;
        var async = Assert.createAsync(function(){
            Assert.isTrue(error);
        });
        Promise.when(p1, p2).then(function(x, y){
            throw "an error";
            return null;
        }).catchError(function(e){
            error = true;
            async();
        });
        d1.resolve(0);
        d2.resolve(0);
    }

    public function errorThen(){
        var d1        = new Deferred<Int>();
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
        d1.resolve(1);
    }

    public function testSimpleWhenReject(){
        var d1        = new Deferred<Int>();
        var d2        = new Deferred<Int>();
        var p1        = d1.promise();
        var p2        = d2.promise();
        var error = false;
        var async = Assert.createAsync(function(){
            Assert.isTrue(error);
        });
        Promise.when(p1,p2).then(function(x,y){
            Assert.isTrue(false, "The 'then' method should not trigger"); //or whatever make the test fail
            return null;
        }).catchError(function(e){
            error = true;
            async();
        });
        p1.reject("error");
        d2.resolve(0);
    }

    public function testChainedThen(){
        var resolved1 = 1;
        var resolved2 = 2;
        var d1        = new Deferred<Int>();
        var p1        = d1.promise(); 
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
        d1.resolve(resolved1);
    }

#if debug
    public function testPromiseConstuctorStack(){

        var p = Promise.promise('foo');
        var endPromise = p.then(function(_) {
            return true;
        }).then(function(_) {
            return true;
        }).then(function(_) {
            return 'end';
        });

        var async = Assert.createAsync(function(){
            Assert.isTrue(endPromise.parentConstructorPos.exists(function(e) {
                return e.fileName == 'TestPromise.hx' && e.lineNumber == 235;
            }));
            Assert.isTrue(endPromise.parentConstructorPos.exists(function(e) {
                return e.fileName == 'TestPromise.hx' && e.lineNumber == 236;
            }));
        });
        endPromise.then(function(x){
            var actual = x;
            async();
        });
    }
#end

}
