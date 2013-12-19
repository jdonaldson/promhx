package promhx;
import promhx.Stream;
import promhx.base.EventLoop;
import utest.Assert;

class TestStream {
    public function new(){}

    public function testSimpleFilter(){
        var s1 = new Stream<Int>();
        var expected = 1;
        var actual:Int = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        Stream.whenever(s1)
            .then(function(x) return x + 1)
            .filter(function(x) return x == 1)
            .then(function(x){
                actual = x;
                async();
            });
        s1.resolve(0);
    }

    public function testStreamEnd(){
        var s = new Stream<Int>();
        var expected = 1;
        var actual = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        s.then(function(x){
            actual = x;
            async();

        });
        s.update(1);
        s.end();
    }
    public function testConcat(){
        var s1 = new Stream<Int>();
        var s2 = new Stream<Int>();
        var expected = [1,2] + '';
        var arr = [];
        var async = Assert.createAsync(function(){
            Assert.equals(expected, arr + '');
        });
        var s3 = s1.concat(s2);
        s3.then(function(x){
            arr.push(x);
        });
        s3.finish(function(){
            async();
        });
        s2.update(2);
        s1.update(1);
        s2.end();
        s1.end();
    }

    public function testFrancoAlwaysFindsABug() {
        var si = new Stream<Int>(),
            ss = new Stream<String>(),
            initial = "Ice-Stream",
            expected = "Ice",
            actual = "";
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        Stream.whenever(si, ss)
            .then(function(i : Int, s : String){
                actual = s.substring(0,i);
                async();
            });
        si.resolve(3);
        ss.resolve(initial);
    }

    public function testPipeLinkError(){
        var expected = 'a pipe link error';
        var actual = '';
        var s1 = new Stream<Int>();
        var s2 = new Stream<Int>();

        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });

        var s3 = s1.pipe(function(x){
            return s2;
        });

        var s4 = s2.then(function(x){
            throw 'a pipe link error';
        });

        s4.error(function(e){
            actual = e;
            async();
        });

        s1.resolve(1);
        s2.resolve(1);
    }

    public function testDelayedErrorHandler(){
        var s = new Stream<Int>();
        var expected = 'foo';
        var actual = '';
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        var s2 = s.then(function(x){
            throw expected;
            return 1;
        });
        s2.error(function(x){
           actual = expected;
           async();
        });
        s.resolve(1);
    }

    public function testSimpleThen(){
        var s1 = new Stream<Int>();
        var expected = 1;
        var actual:Int = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        s1.then(function(x) {
            actual = x;
            async();
        });
        s1.resolve(expected);
    }


    public function testResolved(){
        var s1 = new Stream<Int>();
        s1.resolve(0);
        Assert.isTrue(s1.isResolved());
    }

    public function testAsynchronousResolving(){
        var s1 = new Stream<Int>();
        s1.resolve(0);
        Assert.isTrue(s1.isFulfilling(), "s1 was not fulfilling;, should be asynchronous");
    }



    public function testMultipleStream(){
        var actual = 2;
        var cnt = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(2, actual);
        });
        var s = new Stream<Int>();
        Stream.whenever(s).then(function(x){
           actual = x;
           cnt = x;
           if (cnt == 2) async();
        });
        s.update(1);
        s.update(2);
    }

    public function testSimpleWhenever(){
        var expected1 = 4;
        var expected2 = 5;
        var s1        = new Stream<Int>();
        var s2        = new Stream<Int>();
        var expected = expected1 + expected2;
        var actual = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        var s3 = Stream.whenever(s1,s2).then(function(x,y){
            actual = x + y;
            async();
        });
        s1.resolve(expected1);
        s2.resolve(expected2);
    }

    public function testSimpleWhenError(){
        var s1    = new Stream<Int>();
        var s2    = new Stream<Int>();
        var error = false;
        var async = Assert.createAsync(function(){
            Assert.isTrue(error);
        });
        Stream.whenever(s1,s2).then(function(x,y){
            throw "an error";
        }).error(function(e){
            error = true;
            async();
        });
        s1.resolve(0);
        s2.resolve(0);
    }

    public function testChainedThen(){
        var expected1 = 1;
        var expected2 = 2;
        var s1        = new Stream<Int>();
        var s2        = s1.then(function(x){
            return expected2;
        });
        var expected = expected2;
        var actual = 0;
        var async = Assert.createAsync(function(){
            Assert.equals(expected, actual);
        });
        s2.then(function(x){
            actual = x;
            async();
        });
        s1.resolve(expected1);
    }

}
