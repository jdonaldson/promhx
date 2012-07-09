Promhx
========

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
* Errors are propogated through the promise chain.

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

// Finally, resolve the two promise values, which will start the
// evaluation of all promises.
p1.resolve(1);
p2.resolve(2);

```
