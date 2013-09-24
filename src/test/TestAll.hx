import haxe.unit.TestRunner;
import promhx.TestPromhx;
class TestAll {
	static function main() {
		var r = new TestRunner();
		r.add(new TestPromhx());
		r.run();
	}
}
