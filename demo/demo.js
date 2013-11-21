(function () { "use strict";
function $extend(from, fields) {
	function inherit() {}; inherit.prototype = from; var proto = new inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var Demo = function() { }
Demo.main = function() {
	var target1 = new js.JQuery("#target1"), target2 = new js.JQuery("#target2"), s1 = js.promhx.JQueryTools.clickStream(target1), s2 = js.promhx.JQueryTools.clickStream(target2), markclicked = function(id,x) {
		x.currentTarget.innerHTML = "target " + id + " clicked";
	};
	s1.then((function(f,id1) {
		return function(x) {
			return f(id1,x);
		};
	})(markclicked,1));
	s2.then((function(f1,id2) {
		return function(x) {
			return f1(id2,x);
		};
	})(markclicked,2));
	var status = new js.JQuery("#status");
	var s3 = ((function($this) {
		var $r;
		var varargf = function(f2) {
			var ret = new promhx.Stream();
			var p = promhx.Stream.wheneverAll([s1,s2]);
			p._update.push(function(x) {
				ret.resolve(f2(s1._val,s2._val));
			});
			p._error.push($bind(ret,ret.handleError));
			return ret;
		};
		$r = { then : varargf};
		return $r;
	}(this))).then(function(x,y) {
		console.log("hi");
		status.html("clicked target 1 on " + x.timeStamp + " \n                and  clicked target 2 on " + y.timeStamp);
	});
}
var HxOverrides = function() { }
HxOverrides.iter = function(a) {
	return { cur : 0, arr : a, hasNext : function() {
		return this.cur < this.arr.length;
	}, next : function() {
		return this.arr[this.cur++];
	}};
}
var List = function() {
	this.length = 0;
};
List.prototype = {
	pop: function() {
		if(this.h == null) return null;
		var x = this.h[0];
		this.h = this.h[1];
		if(this.h == null) this.q = null;
		this.length--;
		return x;
	}
	,add: function(item) {
		var x = [item];
		if(this.h == null) this.h = x; else this.q[1] = x;
		this.q = x;
		this.length++;
	}
}
var js = {}
js.promhx = {}
js.promhx.JQueryTools = function() { }
js.promhx.JQueryTools.eventStream = function(jq,events) {
	var s = new promhx.Stream();
	jq.on(events,$bind(s,s.update));
	return s;
}
js.promhx.JQueryTools.clickStream = function(jq) {
	var s = new promhx.Stream();
	jq.on("click",$bind(s,s.update));
	return s;
}
var promhx = {}
promhx.util = {}
promhx.util.AsyncBase = function(errorf) {
	this.id = promhx.util.AsyncBase._idctr += 1;
	this._resolved = false;
	this._fulfilling = false;
	this._fulfilled = false;
	this._update = new Array();
	this._error = new Array();
	if(errorf != null) this._error.push(errorf);
};
promhx.util.AsyncBase.link = function(current,next,f) {
	current._error.push($bind(next,next.handleError));
	current._update.push(function(x) {
		next.resolve(f(x));
	});
	if(current._resolved && !current._fulfilling) try {
		next.resolve(f(current._val));
	} catch( e ) {
		next.handleError(e);
	}
}
promhx.util.AsyncBase.linkAll = function(all,next) {
	var cthen = function(arr,current,v) {
		if(arr.length == 0 || promhx.util.AsyncBase.allFulfilled(arr)) {
			var vals = (function($this) {
				var $r;
				var _g = [];
				var $it0 = $iterator(all)();
				while( $it0.hasNext() ) {
					var a = $it0.next();
					_g.push(a == current?v:a._val);
				}
				$r = _g;
				return $r;
			}(this));
			next.resolve(vals);
		}
	};
	var $it1 = $iterator(all)();
	while( $it1.hasNext() ) {
		var a = $it1.next();
		a._update.push((function(f,a1,a2) {
			return function(v) {
				return f(a1,a2,v);
			};
		})(cthen,(function($this) {
			var $r;
			var _g = [];
			var $it2 = $iterator(all)();
			while( $it2.hasNext() ) {
				var a2 = $it2.next();
				if(a2 != a) _g.push(a2);
			}
			$r = _g;
			return $r;
		}(this)),a));
		a._error.push($bind(next,next.handleError));
	}
	if(promhx.util.AsyncBase.allFulfilled(all)) next.resolve((function($this) {
		var $r;
		var _g = [];
		var $it3 = $iterator(all)();
		while( $it3.hasNext() ) {
			var a = $it3.next();
			_g.push(a._val);
		}
		$r = _g;
		return $r;
	}(this)));
}
promhx.util.AsyncBase.pipeLink = function(current,ret,f) {
	current.then(function(x) {
		f(x).then($bind(ret,ret.resolve));
	});
}
promhx.util.AsyncBase.allResolved = function($as) {
	var atLeastOneAsyncBase = false;
	var $it0 = $iterator($as)();
	while( $it0.hasNext() ) {
		var a = $it0.next();
		if(!a._resolved) return false; else atLeastOneAsyncBase = true;
	}
	return atLeastOneAsyncBase;
}
promhx.util.AsyncBase.allFulfilled = function($as) {
	var atLeastOneAsyncBase = false;
	var $it0 = $iterator($as)();
	while( $it0.hasNext() ) {
		var a = $it0.next();
		if(!a._fulfilled) return false; else atLeastOneAsyncBase = true;
	}
	return atLeastOneAsyncBase;
}
promhx.util.AsyncBase.prototype = {
	then: function(f) {
		var ret = new promhx.util.AsyncBase();
		promhx.util.AsyncBase.link(this,ret,f);
		return ret;
	}
	,handleError: function(d) {
		if(this._error.length == 0) throw d; else {
			var _g = 0, _g1 = this._error;
			while(_g < _g1.length) {
				var ef = _g1[_g];
				++_g;
				ef(d);
			}
		}
	}
	,_resolve: function(val,cleanup) {
		var _g = this;
		if(this._fulfilling) return (function($this) {
			var $r;
			promhx.util.EventLoop.queue.add((function(f,a1,a2) {
				return function() {
					return f(a1,a2);
				};
			})($bind($this,$this._resolve),val,cleanup));
			$r = promhx.util.EventLoop.continueOnNextLoop();
			return $r;
		}(this));
		this._resolved = true;
		this._fulfilling = true;
		promhx.util.EventLoop.queue.add(function() {
			_g._val = val;
			var _g1 = 0, _g2 = _g._update;
			while(_g1 < _g2.length) {
				var f = _g2[_g1];
				++_g1;
				try {
					f(val);
				} catch( e ) {
					_g.handleError(e);
				}
			}
			_g._fulfilled = true;
			_g._fulfilling = false;
			if(cleanup != null) cleanup();
		});
		promhx.util.EventLoop.continueOnNextLoop();
	}
	,resolve: function(val) {
		this._resolve(val);
	}
	,isFulfilling: function() {
		return this._fulfilling;
	}
	,isFulfilled: function() {
		return this._fulfilled;
	}
	,isResolved: function() {
		return this._resolved;
	}
	,error: function(f) {
		this._error.push(f);
		return this;
	}
}
promhx.Stream = function(errorf) {
	promhx.util.AsyncBase.call(this,errorf);
	this._end = false;
	this._onend = [];
};
$hxExpose(promhx.Stream, "promhx.Stream");
promhx.Stream.wheneverAll = function(itb) {
	var ret = new promhx.Stream();
	promhx.util.AsyncBase.linkAll(itb,ret);
	return ret;
}
promhx.Stream.stream = function(_val,errorf) {
	var ret = new promhx.Stream(errorf);
	ret.resolve(_val);
	return ret;
}
promhx.Stream.__super__ = promhx.util.AsyncBase;
promhx.Stream.prototype = $extend(promhx.util.AsyncBase.prototype,{
	merge: function(s) {
		var ret = new promhx.Stream();
		this._update.push($bind(ret,ret.update));
		this._error.push($bind(ret,ret.handleError));
		s._update.push($bind(ret,ret.update));
		s._error.push($bind(ret,ret.handleError));
		return ret;
	}
	,concat: function(s) {
		var ret = new promhx.Stream();
		this._onend.push(function() {
			ret._update.push($bind(s,s.update));
			ret._error.push($bind(s,s.handleError));
		});
		this._update.push($bind(ret,ret.update));
		this._error.push($bind(ret,ret.handleError));
		return ret;
	}
	,filter: function(f) {
		var ret = new promhx.Stream();
		this._update.push(function(x) {
			if(f(x)) ret.resolve(x);
		});
		this._error.push($bind(ret,ret.handleError));
		return ret;
	}
	,end: function() {
		this._end = true;
		var _g = 0, _g1 = this._onend;
		while(_g < _g1.length) {
			var f = _g1[_g];
			++_g;
			try {
				f();
			} catch( e ) {
				this.handleError(e);
			}
		}
		this._update = [];
		this._error = [];
	}
	,pipe: function(f) {
		var ret = new promhx.Stream();
		promhx.util.AsyncBase.pipeLink(this,ret,f);
		return ret;
	}
	,resolve: function(val) {
		if(!this._end) this._resolve(val);
	}
	,update: function(val) {
		this.resolve(val);
	}
});
promhx.util.EventLoop = function() { }
promhx.util.EventLoop.enqueue = function(eqf) {
	promhx.util.EventLoop.queue.add(eqf);
	promhx.util.EventLoop.continueOnNextLoop();
}
promhx.util.EventLoop.continueOnNextLoop = function() {
	var f = function() {
		if(promhx.util.EventLoop.queue.length > 0) {
			(promhx.util.EventLoop.queue.pop())();
			promhx.util.EventLoop.continueOnNextLoop();
		}
	};
	setImmediate(f);
}
function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; };
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; };
var q = window.jQuery;
js.JQuery = q;
var global = window;
(function (global, undefined) {
    "use strict";

    var tasks = (function () {
        function Task(handler, args) {
            this.handler = handler;
            this.args = args;
        }
        Task.prototype.run = function () {
            // See steps in section 5 of the spec.
            if (typeof this.handler === "function") {
                // Choice of `thisArg` is not in the setImmediate spec; `undefined` is in the setTimeout spec though:
                // http://www.whatwg.org/specs/web-apps/current-work/multipage/timers.html
                this.handler.apply(undefined, this.args);
            } else {
                var scriptSource = "" + this.handler;
                /*jshint evil: true */
                eval(scriptSource);
            }
        };

        var nextHandle = 1; // Spec says greater than zero
        var tasksByHandle = {};
        var currentlyRunningATask = false;

        return {
            addFromSetImmediateArguments: function (args) {
                var handler = args[0];
                var argsToHandle = Array.prototype.slice.call(args, 1);
                var task = new Task(handler, argsToHandle);

                var thisHandle = nextHandle++;
                tasksByHandle[thisHandle] = task;
                return thisHandle;
            },
            runIfPresent: function (handle) {
                // From the spec: "Wait until any invocations of this algorithm started before this one have completed."
                // So if we're currently running a task, we'll need to delay this invocation.
                if (!currentlyRunningATask) {
                    var task = tasksByHandle[handle];
                    if (task) {
                        currentlyRunningATask = true;
                        try {
                            task.run();
                        } finally {
                            delete tasksByHandle[handle];
                            currentlyRunningATask = false;
                        }
                    }
                } else {
                    // Delay by doing a setTimeout. setImmediate was tried instead, but in Firefox 7 it generated a
                    // "too much recursion" error.
                    global.setTimeout(function () {
                        tasks.runIfPresent(handle);
                    }, 0);
                }
            },
            remove: function (handle) {
                delete tasksByHandle[handle];
            }
        };
    }());

    function canUseNextTick() {
        // Don't get fooled by e.g. browserify environments.
        return typeof process === "object" &&
               Object.prototype.toString.call(process) === "[object process]";
    }

    function canUseMessageChannel() {
        return !!global.MessageChannel;
    }

    function canUsePostMessage() {
        // The test against `importScripts` prevents this implementation from being installed inside a web worker,
        // where `global.postMessage` means something completely different and can't be used for this purpose.

        if (!global.postMessage || global.importScripts) {
            return false;
        }

        var postMessageIsAsynchronous = true;
        var oldOnMessage = global.onmessage;
        global.onmessage = function () {
            postMessageIsAsynchronous = false;
        };
        global.postMessage("", "*");
        global.onmessage = oldOnMessage;

        return postMessageIsAsynchronous;
    }

    function canUseReadyStateChange() {
        return "document" in global && "onreadystatechange" in global.document.createElement("script");
    }

    function installNextTickImplementation(attachTo) {
        attachTo.setImmediate = function () {
            var handle = tasks.addFromSetImmediateArguments(arguments);

            process.nextTick(function () {
                tasks.runIfPresent(handle);
            });

            return handle;
        };
    }

    function installMessageChannelImplementation(attachTo) {
        var channel = new global.MessageChannel();
        channel.port1.onmessage = function (event) {
            var handle = event.data;
            tasks.runIfPresent(handle);
        };
        attachTo.setImmediate = function () {
            var handle = tasks.addFromSetImmediateArguments(arguments);

            channel.port2.postMessage(handle);

            return handle;
        };
    }

    function installPostMessageImplementation(attachTo) {
        // Installs an event handler on `global` for the `message` event: see
        // * https://developer.mozilla.org/en/DOM/window.postMessage
        // * http://www.whatwg.org/specs/web-apps/current-work/multipage/comms.html#crossDocumentMessages

        var MESSAGE_PREFIX = "com.bn.NobleJS.setImmediate" + Math.random();

        function isStringAndStartsWith(string, putativeStart) {
            return typeof string === "string" && string.substring(0, putativeStart.length) === putativeStart;
        }

        function onGlobalMessage(event) {
            // This will catch all incoming messages (even from other windows!), so we need to try reasonably hard to
            // avoid letting anyone else trick us into firing off. We test the origin is still this window, and that a
            // (randomly generated) unpredictable identifying prefix is present.
            if (event.source === global && isStringAndStartsWith(event.data, MESSAGE_PREFIX)) {
                var handle = event.data.substring(MESSAGE_PREFIX.length);
                tasks.runIfPresent(handle);
            }
        }
        if (global.addEventListener) {
            global.addEventListener("message", onGlobalMessage, false);
        } else {
            global.attachEvent("onmessage", onGlobalMessage);
        }

        attachTo.setImmediate = function () {
            var handle = tasks.addFromSetImmediateArguments(arguments);

            // Make `global` post a message to itself with the handle and identifying prefix, thus asynchronously
            // invoking our onGlobalMessage listener above.
            global.postMessage(MESSAGE_PREFIX + handle, "*");

            return handle;
        };
    }

    function installReadyStateChangeImplementation(attachTo) {
        attachTo.setImmediate = function () {
            var handle = tasks.addFromSetImmediateArguments(arguments);

            // Create a <script> element; its readystatechange event will be fired asynchronously once it is inserted
            // into the document. Do so, thus queuing up the task. Remember to clean up once it's been called.
            var scriptEl = global.document.createElement("script");
            scriptEl.onreadystatechange = function () {
                tasks.runIfPresent(handle);

                scriptEl.onreadystatechange = null;
                scriptEl.parentNode.removeChild(scriptEl);
                scriptEl = null;
            };
            global.document.documentElement.appendChild(scriptEl);

            return handle;
        };
    }

    function installSetTimeoutImplementation(attachTo) {
        attachTo.setImmediate = function () {
            var handle = tasks.addFromSetImmediateArguments(arguments);

            global.setTimeout(function () {
                tasks.runIfPresent(handle);
            }, 0);

            return handle;
        };
    }

    if (!global.setImmediate) {
        // If supported, we should attach to the prototype of global, since that is where setTimeout et al. live.
        var attachTo = typeof Object.getPrototypeOf === "function" && "setTimeout" in Object.getPrototypeOf(global) ?
                          Object.getPrototypeOf(global)
                        : global;

        if (canUseNextTick()) {
            // For Node.js before 0.9
            installNextTickImplementation(attachTo);
        } else if (canUsePostMessage()) {
            // For non-IE10 modern browsers
            installPostMessageImplementation(attachTo);
        } else if (canUseMessageChannel()) {
            // For web workers, where supported
            installMessageChannelImplementation(attachTo);
        } else if (canUseReadyStateChange()) {
            // For IE 6–8
            installReadyStateChangeImplementation(attachTo);
        } else {
            // For older browsers
            installSetTimeoutImplementation(attachTo);
        }

        attachTo.clearImmediate = tasks.remove;
    }
}(typeof global === "object" && global ? global : this));
;
promhx.util.AsyncBase._idctr = 0;
promhx.util.EventLoop.queue = new List();
Demo.main();
function $hxExpose(src, path) {
	var o = typeof window != "undefined" ? window : exports;
	var parts = path.split(".");
	for(var ii = 0; ii < parts.length-1; ++ii) {
		var p = parts[ii];
		if(typeof o[p] == "undefined") o[p] = {};
		o = o[p];
	}
	o[parts[parts.length-1]] = src;
}
})();
