abstract MyAbstract(Int) from Int to Int {
	@:op(A >> B)
	public inline function repeat(rhs:Int):MyAbstract {
		return this * rhs;
	}
}

class Test {
	static function main() {
		var x : MyAbstract = 1024;
		trace(x >> 2 >> 1);
	}
}
