package promhx.haxe;
import promhx.Promise;
import promhx.Stream;
import promhx.haxe.http.Cancel;

class Http extends Promise<Null<String>>{
    var _http : haxe.Http;
    public var status(default, null) : Stream<Dynamic>;

#if sys
	public var noShutdown : Bool;
	public var cnxTimeout : Float;
	public var responseHeaders : Map<String>;
#elseif js
	public var async : Bool;
#end
    var _cancel : promhx.haxe.http.Cancel;

	#if sys
	public static var PROXY : { host : String, port : Int, auth : { user : String, pass : String } } = null;
	#end

    public function new(url : String){
        super();
        _http = new haxe.Http(url);
        _http.onData = handleResolve;
        _http.onError = function(e){
            if (_cancel != null){
                // Http instance is in a cancelled state.
                if (_cancel.reason == null) _cancel = new Cancel(e); 
                // if no reason is given, use the error as a reason.
                reject(_cancel);
            }
            else reject(e);

        }
        var status_def = new Deferred<Dynamic>();
        _http.onStatus = status_def.resolve;
        status = status_def.stream();
    }

    public function cancel<T>(?reason : Dynamic) {
        _cancel = new Cancel(reason);
        _http.cancel();
    }


	/**
		Sets the header identified as [header] to value [value].

		If [header] or [value] are null, the result is unspecified.

		This method provides a fluent interface.
	**/
	public function setHeader( header : String, value : String ):Http {
	    _http.setHeader(header, value);
		return this;
	}

	/**
		Sets the parameter identified as [param] to value [value].

		If [header] or [value] are null, the result is unspecified.

		This method provides a fluent interface.
	**/
	public function setParameter( param : String, value : String ):Http {
		_http.setParameter(param, value);
		return this;
	}

	#if !flash8
	/**
		Sets the post data of [this] Http request to [data].

		There can only be one post data per request. Subsequent calls overwrite
		the previously set value.

		If [data] is null, the post data is considered to be absent.

		This method provides a fluent interface.
	**/
	public function setPostData( data : String ):Http {
		_http.setPostData(data);
		return this;
	}
	#end

	/**
		Sends [this] Http request to the Url specified by [this].url.

		If [post] is true, the request is sent as POST request, otherwise it is
		sent as GET request.

		Depending on the outcome of the request, this method calls the
		onStatus(), onError() or onData() callback functions.

		If [this].url is null, the result is unspecified.

		If [this].url is an invalid or inaccessible Url, the onError() callback
		function is called.

		(Js) If [this].async is false, the callback functions are called before
		this method returns.
	**/
	public function request(?post : Bool) : Void {
        _http.request(post);
    }

#if sys
	public function fileTransfer ( argname : String, filename : String, file : haxe.io.Input, size : Int ) {
		_http.file = { param : argname, filename : filename, io : file, size : size };
    }
	public function customRequest( post : Bool, api : haxe.io.Output, ?sock : AbstractSocket, ?method : String  ) {
	    _http.customRequest(post, api, sock, method);
    }
#end
}

