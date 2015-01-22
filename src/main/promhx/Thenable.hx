package promhx;
typedef Thenable<T> = {
    function then<A>(f : T->A): Thenable<A>;
    function errorThen<A>(f : Dynamic->A): Thenable<A>;
    function catchError<A>(f : Dynamic->Void): Thenable<T>;	
}
