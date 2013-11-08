import utest.Runner;
import utest.ui.Report;

import promhx.TestPromise;
import promhx.TestStream;
import promhx.TestPromiseM;

class TestAll {
	static function main() {
		var r = new Runner();
		r.addCase(new TestPromise());
		r.addCase(new TestStream());
		// r.addCase(new TestPromiseM());
		Report.create(r);
		r.run();
	}
}
