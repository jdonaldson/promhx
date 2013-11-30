package promhx.haxe;
import promhx.Promise;
import promhx.Stream;

class Http extends Promise<Null<String>>{
    var _http : haxe.Http;
    var status(get, null) : Stream<Dynamic>;
    var _status : Stream<Dynamic>;

#if sys
	public var noShutdown : Bool;
	public var cnxTimeout : Float;
	public var responseHeaders : haxe.ds.StringMap<String>;
#elseif js
	public var async : Bool;
#end

	#if sys
	public static var PROXY : { host : String, port : Int, auth : { user : String, pass : String } } = null;
	#end

    public function new(url : String){
        super();
        _http = new haxe.Http(url);
        _http.onData = resolve;
        _http.onError = reject;
    }
    function get_status() : Stream<Dynamic> {
        if (_status == null){
            _status = new Stream<Dynamic>();
            _http.onStatus = _status.update;
        }
        return _status;
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
