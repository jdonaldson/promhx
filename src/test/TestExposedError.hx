
import utest.Runner;
import utest.ui.Report;
import promhx.PublicStream;


import utest.Assert;

class TestExposedError {
    static function main() {
        var r = new Runner();
        r.addCase(new TestError());
        Report.create(r);
        r.run();
    }
}

class TestError{
    public function new(){}
    public function testError(){
        var s = new PublicStream();
        s.resolve(4);
        try{
            s.then(function(x){
                throw('fail');
                Assert.fail("failed to error: shouldn't reach this code");
            });
        } catch (e:Dynamic){
            Assert.equals(e,'fail',"Failed to catch exposed error");
        }

    }
}
