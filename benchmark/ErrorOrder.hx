package ;

import haxe.Timer;
import promhx.Deferred;
import promhx.Promise;

class ErrorOrder{
	public static function main() {
		var d1 = new Deferred<Int>();
		var d2 = new Deferred<Int>();
		var d3 = new Deferred<Int>();

		var p1 = d1.promise();
		var p2 = d2.promise();
		var p3 = d3.promise();

		Promise.whenAll([p1, p2, p3])
			.then(function(r:Array<Int>) {
				trace('complete $r');
			}).catchError(function(e:Dynamic) {
				trace('error $e');
			});

		Timer.delay(function() {
			d1.resolve(1);
		}, 10);

		Timer.delay(function() {
			d2.resolve(2);
		}, 20);

		Timer.delay(function() {
			d3.resolve(3);
			d3.throwError("nope");
		}, 5);
		
	}
}
