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
        Promise.when(p1,p2).then(function(x,y) trace(x+y));
        
        // You can also call it on an array of values, but you lose typing.
        Promise.when([p1,p2]).then(function(arr) trace(arr));

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
        p1.resolve(1);
        p2.resolve(2);

    }

}
