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

package promhx;
import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.monads.Monad;

class PromiseM {

    macro public static function dO(body : Expr)  // the function to trigger the Monad macro.
        return Monad._dO("promhx.PromiseM", body, Context);

    inline public static function ret<T>(x : T) // creates an element
        return Promise.promise(x);

    inline public static function map < T, U > (x : Promise<T>, f : T -> U) 
        return x.then(function(y) return f(y));

    inline public static function flatMap<T, U>(x : Promise<T>, f : T -> Promise<U>)
        return x.pipe(function(y) return f(y));
}
