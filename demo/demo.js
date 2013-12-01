(function () { "use strict";
function $extend(from, fields) {
	function inherit() {}; inherit.prototype = from; var proto = new inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var Demo = function() { }
Demo.__name__ = true;
Demo.main = function() {
	var j = js.promhx.JQueryTools.eventStream(new js.JQuery("#status"),"focus");
	var h = new promhx.haxe.Http("test.txt");
	h.then(function(x) {
		console.log(x);
	});
	h.request();
	j.then(function(x) {
		console.log(x);
	});
}
var HxOverrides = function() { }
HxOverrides.__name__ = true;
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
List.__name__ = true;
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
	,__class__: List
}
var IMap = function() { }
IMap.__name__ = true;
var StringTools = function() { }
StringTools.__name__ = true;
StringTools.urlEncode = function(s) {
	return encodeURIComponent(s);
}
var haxe = {}
haxe.Http = function(url) {
	this.url = url;
	this.headers = new haxe.ds.StringMap();
	this.params = new haxe.ds.StringMap();
	this.async = true;
};
haxe.Http.__name__ = true;
haxe.Http.prototype = {
	onStatus: function(status) {
	}
	,onError: function(msg) {
	}
	,onData: function(data) {
	}
	,request: function(post) {
		var me = this;
		me.responseData = null;
		var r = js.Browser.createXMLHttpRequest();
		var onreadystatechange = function(_) {
			if(r.readyState != 4) return;
			var s = (function($this) {
				var $r;
				try {
					$r = r.status;
				} catch( e ) {
					$r = null;
				}
				return $r;
			}(this));
			if(s == undefined) s = null;
			if(s != null) me.onStatus(s);
			if(s != null && s >= 200 && s < 400) me.onData(me.responseData = r.responseText); else if(s == null) me.onError("Failed to connect or resolve host"); else switch(s) {
			case 12029:
				me.onError("Failed to connect to host");
				break;
			case 12007:
				me.onError("Unknown host");
				break;
			default:
				me.responseData = r.responseText;
				me.onError("Http Error #" + r.status);
			}
		};
		if(this.async) r.onreadystatechange = onreadystatechange;
		var uri = this.postData;
		if(uri != null) post = true; else {
			var $it0 = this.params.keys();
			while( $it0.hasNext() ) {
				var p = $it0.next();
				if(uri == null) uri = ""; else uri += "&";
				uri += StringTools.urlEncode(p) + "=" + StringTools.urlEncode(this.params.get(p));
			}
		}
		try {
			if(post) r.open("POST",this.url,this.async); else if(uri != null) {
				var question = this.url.split("?").length <= 1;
				r.open("GET",this.url + (question?"?":"&") + uri,this.async);
				uri = null;
			} else r.open("GET",this.url,this.async);
		} catch( e ) {
			this.onError(e.toString());
			return;
		}
		if(this.headers.get("Content-Type") == null && post && this.postData == null) r.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
		var $it1 = this.headers.keys();
		while( $it1.hasNext() ) {
			var h = $it1.next();
			r.setRequestHeader(h,this.headers.get(h));
		}
		r.send(uri);
		if(!this.async) onreadystatechange(null);
	}
	,setPostData: function(data) {
		this.postData = data;
		return this;
	}
	,setParameter: function(param,value) {
		this.params.set(param,value);
		return this;
	}
	,setHeader: function(header,value) {
		this.headers.set(header,value);
		return this;
	}
	,__class__: haxe.Http
}
haxe.ds = {}
haxe.ds.StringMap = function() {
	this.h = { };
};
haxe.ds.StringMap.__name__ = true;
haxe.ds.StringMap.__interfaces__ = [IMap];
haxe.ds.StringMap.prototype = {
	keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key.substr(1));
		}
		return HxOverrides.iter(a);
	}
	,get: function(key) {
		return this.h["$" + key];
	}
	,set: function(key,value) {
		this.h["$" + key] = value;
	}
	,__class__: haxe.ds.StringMap
}
var js = {}
js.Boot = function() { }
js.Boot.__name__ = true;
js.Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0, _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js.Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js.Boot.__interfLoop(cc.__super__,cl);
}
js.Boot.__instanceof = function(o,cl) {
	if(cl == null) return false;
	switch(cl) {
	case Int:
		return (o|0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return typeof(o) == "boolean";
	case String:
		return typeof(o) == "string";
	case Dynamic:
		return true;
	default:
		if(o != null) {
			if(typeof(cl) == "function") {
				if(o instanceof cl) {
					if(cl == Array) return o.__enum__ == null;
					return true;
				}
				if(js.Boot.__interfLoop(o.__class__,cl)) return true;
			}
		} else return false;
		if(cl == Class && o.__name__ != null) return true;
		if(cl == Enum && o.__ename__ != null) return true;
		return o.__enum__ == cl;
	}
}
js.Browser = function() { }
js.Browser.__name__ = true;
js.Browser.createXMLHttpRequest = function() {
	if(typeof XMLHttpRequest != "undefined") return new XMLHttpRequest();
	if(typeof ActiveXObject != "undefined") return new ActiveXObject("Microsoft.XMLHTTP");
	throw "Unable to create XMLHttpRequest object.";
}
js.promhx = {}
js.promhx.JQueryTools = function() { }
js.promhx.JQueryTools.__name__ = true;
js.promhx.JQueryTools.bindStream = function(f) {
	var str = new promhx.Stream();
	f($bind(str,str.update));
	return str;
}
js.promhx.JQueryTools.eventStream = function(jq,events) {
	var str = new promhx.Stream();
	jq.on(events,$bind(str,str.update));
	return str;
}
js.promhx.JQueryTools.loadPromise = function(jq,url,data) {
	var pro = new promhx.Promise();
	jq.load(url,data,function(responseText,textStatus) {
		pro.resolve({ responseText : responseText, textStatus : textStatus});
	});
	return pro;
}
js.promhx.JQueryTools.buildEventStream = function(jq,events,stream) {
	jq.on(events,$bind(stream,stream.update));
	return stream;
}
js.promhx.JQueryTools.clickStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"click",new promhx.Stream());
}
js.promhx.JQueryTools.dblclickStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"dblclick",new promhx.Stream());
}
js.promhx.JQueryTools.mousedownStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"mousedown",new promhx.Stream());
}
js.promhx.JQueryTools.mouseenterStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"mouseenter",new promhx.Stream());
}
js.promhx.JQueryTools.mouseleaveStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"mouseleave",new promhx.Stream());
}
js.promhx.JQueryTools.mouseoutStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"mouseout",new promhx.Stream());
}
js.promhx.JQueryTools.mouseoverStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"mouseover",new promhx.Stream());
}
js.promhx.JQueryTools.mousemoveStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"mousemove",new promhx.Stream());
}
js.promhx.JQueryTools.mouseupStream = function(jq) {
	return js.promhx.JQueryTools.buildEventStream(jq,"mouseup",new promhx.Stream());
}
var promhx = {}
promhx.base = {}
promhx.base.AsyncBase = function(errorf) {
	this._resolved = false;
	this._fulfilling = false;
	this._fulfilled = false;
	this._update = new Array();
	this._error = new Array();
	if(errorf != null) this._error.push(errorf);
};
promhx.base.AsyncBase.__name__ = true;
promhx.base.AsyncBase.link = function(current,next,f) {
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
promhx.base.AsyncBase.linkAll = function(all,next) {
	var cthen = function(arr,current,v) {
		if(arr.length == 0 || promhx.base.AsyncBase.allFulfilled(arr)) {
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
	if(promhx.base.AsyncBase.allFulfilled(all)) next.resolve((function($this) {
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
promhx.base.AsyncBase.pipeLink = function(current,ret,f) {
	current.then(function(x) {
		f(x).then($bind(ret,ret.resolve));
	});
}
promhx.base.AsyncBase.allResolved = function($as) {
	var atLeastOneAsyncBase = false;
	var $it0 = $iterator($as)();
	while( $it0.hasNext() ) {
		var a = $it0.next();
		if(!a._resolved) return false; else atLeastOneAsyncBase = true;
	}
	return atLeastOneAsyncBase;
}
promhx.base.AsyncBase.allFulfilled = function($as) {
	var atLeastOneAsyncBase = false;
	var $it0 = $iterator($as)();
	while( $it0.hasNext() ) {
		var a = $it0.next();
		if(!a._fulfilled) return false; else atLeastOneAsyncBase = true;
	}
	return atLeastOneAsyncBase;
}
promhx.base.AsyncBase.prototype = {
	then: function(f) {
		var ret = new promhx.base.AsyncBase();
		promhx.base.AsyncBase.link(this,ret,f);
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
			promhx.base.EventLoop.queue.add((function(f,a1,a2) {
				return function() {
					return f(a1,a2);
				};
			})($bind($this,$this._resolve),val,cleanup));
			$r = promhx.base.EventLoop.continueOnNextLoop();
			return $r;
		}(this));
		this._resolved = true;
		this._fulfilling = true;
		promhx.base.EventLoop.queue.add(function() {
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
		promhx.base.EventLoop.continueOnNextLoop();
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
	,__class__: promhx.base.AsyncBase
}
promhx.Promise = function(errorf) {
	promhx.base.AsyncBase.call(this,errorf);
	this._rejected = false;
};
$hxExpose(promhx.Promise, "promhx.Promise");
promhx.Promise.__name__ = true;
promhx.Promise.whenAll = function(itb) {
	var ret = new promhx.Promise();
	promhx.base.AsyncBase.linkAll(itb,ret);
	return ret;
}
promhx.Promise.promise = function(_val,errorf) {
	var ret = new promhx.Promise(errorf);
	ret.resolve(_val);
	return ret;
}
promhx.Promise.__super__ = promhx.base.AsyncBase;
promhx.Promise.prototype = $extend(promhx.base.AsyncBase.prototype,{
	pipe: function(f) {
		var ret = new promhx.Promise();
		promhx.base.AsyncBase.pipeLink(this,ret,f);
		return ret;
	}
	,then: function(f) {
		var ret = new promhx.Promise();
		promhx.base.AsyncBase.link(this,ret,f);
		return ret;
	}
	,resolve: function(val) {
		var _g = this;
		if(this._resolved) throw "Promise has already been resolved";
		this._resolve(val,function() {
			_g._update = new Array();
		});
	}
	,reject: function(e) {
		this._update = new Array();
		this.handleError(e);
	}
	,isRejected: function() {
		return this._rejected;
	}
	,__class__: promhx.Promise
});
promhx.Stream = function(errorf) {
	promhx.base.AsyncBase.call(this,errorf);
	this._end = false;
	this._onend = [];
};
$hxExpose(promhx.Stream, "promhx.Stream");
promhx.Stream.__name__ = true;
promhx.Stream.wheneverAll = function(itb) {
	var ret = new promhx.Stream();
	promhx.base.AsyncBase.linkAll(itb,ret);
	return ret;
}
promhx.Stream.stream = function(_val,errorf) {
	var ret = new promhx.Stream(errorf);
	ret.resolve(_val);
	return ret;
}
promhx.Stream.__super__ = promhx.base.AsyncBase;
promhx.Stream.prototype = $extend(promhx.base.AsyncBase.prototype,{
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
		promhx.base.AsyncBase.pipeLink(this,ret,f);
		return ret;
	}
	,resolve: function(val) {
		if(!this._end) this._resolve(val);
	}
	,update: function(val) {
		this.resolve(val);
	}
	,first: function() {
		var s = new promhx.Promise();
		this.then(function(x) {
			if(!s._resolved) s.resolve(x);
		});
		return s;
	}
	,__class__: promhx.Stream
});
promhx.base.EventLoop = function() { }
promhx.base.EventLoop.__name__ = true;
promhx.base.EventLoop.enqueue = function(eqf) {
	promhx.base.EventLoop.queue.add(eqf);
	promhx.base.EventLoop.continueOnNextLoop();
}
promhx.base.EventLoop.set_nextLoop = function(f) {
	if(promhx.base.EventLoop.nextLoop != null) throw "nextLoop has already been set"; else promhx.base.EventLoop.nextLoop = f;
	return promhx.base.EventLoop.nextLoop;
}
promhx.base.EventLoop.continueOnNextLoop = function() {
	var f = function() {
		if(promhx.base.EventLoop.queue.length > 0) {
			(promhx.base.EventLoop.queue.pop())();
			promhx.base.EventLoop.continueOnNextLoop();
		}
	};
	if(promhx.base.EventLoop.nextLoop != null) promhx.base.EventLoop.nextLoop(f); else setImmediate(f);
}
promhx.haxe = {}
promhx.haxe.EventTools = function() { }
promhx.haxe.EventTools.__name__ = true;
promhx.haxe.EventTools.eventStream = function(el,event,useCapture) {
	var str = new promhx.Stream();
	el.addEventListener(event,$bind(str,str.update),useCapture);
	return str;
}
promhx.haxe.Http = function(url) {
	promhx.Promise.call(this);
	this._http = new haxe.Http(url);
	this._http.onData = $bind(this,this.resolve);
	this._http.onError = $bind(this,this.reject);
};
promhx.haxe.Http.__name__ = true;
promhx.haxe.Http.__super__ = promhx.Promise;
promhx.haxe.Http.prototype = $extend(promhx.Promise.prototype,{
	request: function(post) {
		this._http.request(post);
	}
	,setPostData: function(data) {
		this._http.setPostData(data);
		return this;
	}
	,setParameter: function(param,value) {
		this._http.setParameter(param,value);
		return this;
	}
	,setHeader: function(header,value) {
		this._http.setHeader(header,value);
		return this;
	}
	,get_status: function() {
		if(this._status == null) {
			this._status = new promhx.Stream();
			this._http.onStatus = ($_=this._status,$bind($_,$_.update));
		}
		return this._status;
	}
	,__class__: promhx.haxe.Http
});
function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; };
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; };
String.prototype.__class__ = String;
String.__name__ = true;
Array.prototype.__class__ = Array;
Array.__name__ = true;
var Int = { __name__ : ["Int"]};
var Dynamic = { __name__ : ["Dynamic"]};
var Float = Number;
Float.__name__ = ["Float"];
var Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = { __name__ : ["Class"]};
var Enum = { };
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
promhx.base.EventLoop.queue = new List();
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
