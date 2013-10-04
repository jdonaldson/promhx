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
class OptionM {

    @:macro public static function dO(body : Expr) return // the function to trigger the Monad macro.
        Monad.dO("promhx.OptionM", body, Context)

        inline public static function ret<T>(x : T) return // creates an element
        Promise.promise(x);

        inline public static function map < T, U > (x : Option<T>, f : T -> U) : Option<U> {
            switch (x) {
                case Some(x) : return Some(f(x));
                default : return None;
            }
        }

    inline public static function flatMap<T, U>(x : Option<T>, f : T -> Option<U>) : Option<U> {
        switch (x) {
            case Some(x) : return f(x);
            default : return None;
        }
    }
}
