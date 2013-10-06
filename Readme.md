Promhx
========

[![Build Status](https://travis-ci.org/jdonaldson/promhx.png)](https://travis-ci.org/jdonaldson/promhx)

Promhx is a [promise](http://en.wikipedia.org/wiki/Futures_and_promises)
library for [Haxe](http://www.haxe.org).  Promises contain values that are not
immediately available. However, you can specify callback functions that will
trigger when the values do become available.

A typical case is to specify a callback for a given promise once the value
becomes available:

```js
promise.then(function(p1) trace("do something with promise's value"));
```

Alternatively, you can specify a callback on multiple promise instances using
the static method "when":

```js
Promise.when(promise1, promise2).then(function(p1,p2) trace("do something with the promise values"));
```
Promhx has a number of powerful features:

* You can specify a "then" callback on one or more promise values.
* Callback functions are typed according to the values that the promises
  contain.
* Errors are propagated through the promise chain.

Promhx has the following behavior:

* Promises can only be resolved once.
* Promises will remember their resolved value, and any functions specified
  afterwards by "then()" will get ther result synchronously.
* It is only possible to cancel a promise by rejecting it, which triggers an
  error.

```js
// Declare a promised value
var p1 = new Promise<Int>();

// Simple: deliver promise when value is available.
p1.then(function(x) trace("delivered " + x));

// Deliver multiple promises when they are all available.
// the "then" function must match the types and arity of the contained values
// from the arguments to "when".
var p2 = new Promise<Int>();
Promise.when(p1,p2).then(function(x,y)trace(x+y));

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
//Promise.when(p1,p2).then(function(x,y) throw('an error'));

// finally, resolve the promise values, which will start the
// evaluation of all promises.
p1.resolve(1);
p2.resolve(2);
p3.resolve('hi');

// arguments that are all resolved will only trigger once
Promise.when(p1,p2).then(function(x,y) trace(x + ", " + y));

```
