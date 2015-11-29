import utest.Runner;
import utest.ui.Report;

import promhx.TestPromise;
import promhx.TestStream;
import promhx.TestMacroPromise;

import promhx.Stream;

class TestAll {
    public static function main() start();

	public static function start(?precheck:Void->Void) {
        var r = new Runner();
		r.addCase(new TestPromise());
		r.addCase(new TestStream());
		r.addCase(new TestMacroPromise());
		Report.create(r);
		if (precheck != null) r.onPrecheck.add(function(x) precheck());
		r.run();
    }
}
