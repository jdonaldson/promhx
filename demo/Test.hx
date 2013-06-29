import promhx.Promise;

class Test {
    static function main() {
        // Declare a promised value
        var p1 = new Promise<Int>();

        // Simple: deliver promise when value is available.
        p1.then(function(x) trace("delivered " + x));

        // Deliver multiple promises when they are all available.
        // the "then" function must match the arity of the contained values
        // from the arguments to "when".
        var p2 = new Promise<Int>();
        Promise.when(p1,p2).then(function(x,y)trace(x+y));


        var k:Array<Promise<Dynamic>> = new Array();
        k.push(p1); k.push(p2);

        // Special handling for Iterables, Array Literals:

        // Iterable<Promise<T>> is passed as a single Iterable<T> callback:
        Promise.when(k).then(function(x) trace("passed as Iterable instance: " + x));
        Promise.when([p1,p2]).then(function(x) trace("passed as array: " +  x));

        // The return value is another promise, so you can chain.
        Promise.when(p1,p2).then(function(x,y) return x+y)
            .then(function(x) trace(x+1));

        var p3 = new Promise<String>();
        // The pipe method lets you manually specify a new Promise to chain
        // to.  It can be pre-existing, or created by the method itself.
        Promise.when(p1,p2).then(function(x,y) return x+y)
            .pipe(function(x) return p3)
            .then(function(x) trace(x));


        // You can easily catch errors by specifying a callback.
        Promise.when(p1,p2).then(function(x,y) throw('an error'))
            .error(function(x) trace(x));

        // Errors are propagated through the promise chain.
        // You can rethrow errors to use Haxe's try/catch feature.
        Promise.when(p1,p2).then(function(x,y) {throw('an error'); return 'hi';})
            .then(function(x) return 'a value')
            .error(function(x) {
                try {
                    throw(x); // rethrow the error value to do standard error handling
                } catch(e:String){
                    trace('caught a string: ' + e);
                } catch(e:Dynamic){
                    trace('caught something unknown:' + e);
                }
            });

        // If no error callback is specified, the error is thrown.
        // Uncomment this next line to cause an error!
        // Promise.when(p1,p2).then(function(x,y) throw('an error'));

        // finally, resolve the promise values, which will start the
        // evaluation of all promises.
        p1.resolve(1);
        p2.resolve(2);
        p3.resolve('hi');

        // arguments that are all resolved will only trigger once
        Promise.when(p1,p2).then(function(x,y) trace(x + ", " + y));
    }

}
