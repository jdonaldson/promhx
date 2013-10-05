import haxe.unit.TestRunner;
import promhx.TestPromhx;
import promhx.TestMPromhx;
class TestAll {
	static function main() {
		var r = new TestRunner();
		// r.add(new TestPromhx());
		r.add(new TestMPromhx());
		r.run();
	}
}
