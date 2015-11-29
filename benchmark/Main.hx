import promhx.PublicStream;

class Main {
    static function main() {
        var start = haxe.Timer.stamp();
        trace(start + " is the value for start");
        for (t in 1...10000){
            var p = new PublicStream<Int>();
            p.then(function(x){
                // trace('resolved $x');
            });
            p.resolve(t);
            if (t == 9999){
                p.then(function(x){
                    trace('time taken: ${haxe.Timer.stamp() - start}');
                });
            }
        }
    }
}
