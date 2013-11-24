Promhx
========

[![Build Status](https://travis-ci.org/jdonaldson/promhx.png)]
(https://travis-ci.org/jdonaldson/promhx)

Promhx is a [promise](http://en.wikipedia.org/wiki/Futures_and_promises) and
[functional reactive programming](TODO) library for [Haxe](http://www.haxe.org).
The "promise" and "stream" variables contain values that are not immediately
available. However, you can specify callback functions that will trigger when
the values do become available.

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

Streams work more or less the same:

```js
stream.then(function(s1) trace("do something with stream's value"));
```

```js
Stream.whenever(stream1, stream2).then(function(s1,s2) trace("do something with the stream values"));
```

The major difference between Promises and Streams is that Promises may only
resolve once, while Streams may resolve multiple times.  Promises are suitable
for initialization and asset loading, while Streams are a useful alternative to
managing events.

Promhx has a number of powerful features:

* Fully cross-platform for php, c#, c++, java, js (nodejs and browser js), neko,
   and flash.
* Very efficient code that ranks among the fastest promise libraries for js.
* Type safety without requiring excessive boilerplate.
* Staggered promise/stream updates occur once per event loop, preventing
excessive blocking of io in single threaded contexts (e.g. js).
* Run time errors are propagated to subsequent promise/streams, and can be
managed where appropriate.

Promises have the following behavior:

* Promises can only be resolved once.
* It is only possible to cancel a promise by rejecting it, which triggers an
  error.

Streams have the following behavior:
* If a stream is updated more than once in a single loop, the updates will be
staggered in subsequent loops.
* Promises will remember their resolved value, and any functions specified
  afterwards by "then()" will get their result synchronously.

```js
// Declare a promised value
var p1 = new Promise<Int>();

// Simple: deliver promise when value is available. Stream works the same.
p1.then(function(x) trace("delivered " + x));

// Deliver multiple promises when they are all available.
// the "then" function must match the types and arity of the contained values
// from the arguments to "when".
var p2 = new Promise<Int>();
Promise.when(p1,p2).then(function(x,y)trace(x+y));


// Stream has its own "when" based method, called "whenever".  Note that
// the returned stream value will resolve whenver *any one* of the stream
// arguments changes.
var s1 = new Stream<Int>();
var s2 = new Stream<Int>();
Stream.whenever(s1,s2).then(function(x,y)trace(x+y));


// Stream.whenever can mix and match stream and promise arguments:
Stream.whenever(s1,p1).then(function(x,y)trace(x+y));

// The return value is another promise, so you can chain.
Promise.when(p1,p2).then(function(x,y) return x+y)
    .then(function(x) trace(x+1));

var p3 = new Promise<String>();

// The pipe method lets you manually specify a new Promise to chain
// to.  It can be pre-existing, or created by the method itself.  Stream
// works in a similar fashion.
Promise.when(p1,p2).then(function(x,y) return x+y)
    .pipe(function(x) return p3)
    .then(function(x) trace(x));


// You can easily catch errors by specifying a callback.
Promise.when(p1,p2).then(function(x,y) throw('an error'))
    .error(function(x) trace(x));

// Errors are propagated through the promise chain.
// You can rethrow errors to use Haxe's try/catch feature.
// Stream works the same here too.
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

// Promises can go through various stages before finally resolving.  The
// following methods check the status.


// Check to see if a promise has been resolved.  This will return true as soon
// as resolve() returns.
trace(p1.isResolved());

// Check to see if a promise is in the process of fulfilling.
// In some cases promises are not completely resolved.  This can happen if
// the promise is delaying execution (on flash, js), or is updating other
// promises.
trace(p1.isFulfilling());

// Check to see if the promise has completed fulfilling its updates.
trace(p1.isFulfilled());

// Check to see if a promise has been rejected.  This can happen if
// the promise throws an error, or if the current promise is waiting
// on a promise that has thrown an error.
trace(p1.isRejected());

// finally, resolve the promise values, which will start the
// evaluation of all promises.
p1.resolve(1);
p2.resolve(2);
p3.resolve('hi');

// You can "resolve" a stream as well since they share a base class, but the
// method "update" is provided as a clearer alias as well:
s1.resolve(1);
s1.update(1);
s2.update(2);

// arguments that are all resolved will only trigger once
Promise.when(p1,p2).then(function(x,y) trace(x + ", " + y));

```
