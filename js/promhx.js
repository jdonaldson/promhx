(function () { "use strict";
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
var promhx = {}
promhx.Promise = function(errorf) {
	this._set = false;
	this._update = new Array();
	this._error = new Array();
	if(errorf != null) this._error.push(errorf);
};
$hxExpose(promhx.Promise, "promhx.Promise");
promhx.Promise.__name__ = true;
promhx.Promise._next = function(f) {
	setTimeout(f);
}
promhx.Promise.allSet = function($as) {
	var $it0 = $as.iterator();
	while( $it0.hasNext() ) {
		var a = $it0.next();
		if(!a._set) return false;
	}
	return true;
}
promhx.Promise.whenAll = function(itb) {
	var p = new promhx.Promise();
	var itr = itb.iterator();
	var cur = itr.hasNext()?itr.next():null;
	var cthen = function(v) {
		while(cur != null) if(!cur._set) return; else cur = itr.next();
		if(!p._set) try {
			p.resolve((function($this) {
				var $r;
				var _g = [];
				var $it0 = itb.iterator();
				while( $it0.hasNext() ) {
					var v1 = $it0.next();
					_g.push(v1._val);
				}
				$r = _g;
				return $r;
			}(this)));
		} catch( e ) {
			p.handleError(e);
		}
	};
	if(promhx.Promise.allSet(itb)) cthen(null); else {
		var $it1 = itb.iterator();
		while( $it1.hasNext() ) {
			var p1 = $it1.next();
			p1.then(cthen);
		}
	}
	return p;
}
promhx.Promise.promise = function(_val,errorf) {
	var ret = new promhx.Promise(errorf);
	ret.resolve(_val);
	return ret;
}
promhx.Promise.prototype = {
	reject: function(e) {
		this._update = new Array();
		this.handleError(e);
	}
	,pipe: function(f) {
		if(this._set) {
			var fret = f(this._val);
			return fret;
		} else {
			var ret = new promhx.Promise();
			var this_update = function(x) {
				var fret = f(x);
				if(fret._set) ret.resolve(fret._val); else {
					fret._update.push($bind(ret,ret.resolve));
					fret._error.push($bind(ret,ret.handleError));
				}
			};
			this._update.push(this_update);
			this._error.push($bind(ret,ret.handleError));
			return ret;
		}
	}
	,then: function(f) {
		var ret = new promhx.Promise();
		var fret = function(v) {
			var res = f(v);
			ret.resolve(res);
			return res;
		};
		if(this._set) try {
			fret(this._val);
		} catch( e ) {
			this.handleError(e);
		} else {
			this._update.push(fret);
			this._error.push($bind(ret,ret.handleError));
		}
		return ret;
	}
	,handleError: function(d) {
		if(this._errorf != null) this._errorf(d); else if(this._error.length == 0) throw d; else {
			var _g = 0, _g1 = this._error;
			while(_g < _g1.length) {
				var ef = _g1[_g];
				++_g;
				ef(d);
			}
		}
		var p1 = new promhx.Promise();
		return null;
	}
	,resolve: function(val) {
		var _g = this;
		if(this._set) throw "Promise has already been resolved";
		this._set = true;
		this._val = val;
		setTimeout(function() {
			var _g1 = 0, _g2 = _g._update;
			while(_g1 < _g2.length) {
				var f = _g2[_g1];
				++_g1;
				try {
					f(_g._val);
				} catch( e ) {
					_g.handleError(e);
				}
			}
			_g._update = new Array();
		});
	}
	,error: function(f) {
		this._errorf = f;
		return this;
	}
	,__class__: promhx.Promise
}
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
