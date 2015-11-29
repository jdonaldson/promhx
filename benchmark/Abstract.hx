import promhx.abs.AbstractStream;
class Abstract {
	static function main() {
		var p = new promhx.PublicStream<String>();
		var s:AbstractStream<String> = p; 
		var k = s >> function(x) { return x + ' foo';}
			>> function(x) { return x + ' bar';}
			|| function(x) {trace(x); return new promhx.Stream<Int>();}
		$type(k);

		p.resolve('baz');
	}
}

