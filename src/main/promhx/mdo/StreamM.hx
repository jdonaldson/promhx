
/****
* Copyright (c) 2013 Justin Donaldson 
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
* 
****/

package promhx.mdo;
import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;

class StreamM {

    macro public static function dO(body : Expr)  // the function to trigger the Monad macro.
        return Monad._dO("promhx.StreamM", body, Context);

    inline public static function ret<A>(x : A) // creates an element
        return Stream.stream(x);

    inline public static function map < A, B > (x : Stream<A>, f : A -> B) 
        return x.then(f);

    inline public static function flatMap<A, B>(x : Stream<A>, f : A -> Stream<B>)
        return x.pipe(f);
}
