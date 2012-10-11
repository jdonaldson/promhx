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

        // Iterable<Promise<T>> are passed a single Iterable<T> callback:
        Promise.when(k).then(function(x) trace("passed as Iterable instance: " + x));

        // Array literals are treated as if the arguments were passed 
        // one at a time:
        Promise.when([p1,p2]).then(function(x,y) trace("passed as array literal: " +  x + ',' + y));

        // The return value is another promise, so you can chain.
        Promise.when(p1,p2).then(function(x,y) return x+y)
            .then(function(x) trace(x+1));
        
        // You can easily catch errors by specifying a callback.
        Promise.when(p1,p2).then(function(x,y) throw('an error'))
            .error(function(x) trace(x));
        
        // Errors are propagated through the promise chain.
        Promise.when(p1,p2).then(function(x,y) throw('an error'))
            .then(function(x) return 'a value')
            .error(function(x) trace(x));
       
        // If no error callback is specified, the error is thrown.
        //Promise.when(p1,p2).then(function(x,y) throw('an error'));
        
        // finally, resolve the two promise values, which will start the 
        // evaluation of all promises.
        p2.resolve(2);
        p1.resolve(1);
    }

}
