import haxe.unit.TestRunner;
import promhx.TestPromise;
import promhx.TestPromiseM;
class TestAll {
	static function main() {
		var r = new TestRunner();
		r.add(new TestPromise());
		r.add(new TestPromiseM());
		r.run();
	}
}
