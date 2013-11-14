package promhx;
typedef Thenable<T> = {
    function then<A>(f : T->A): Thenable<A>;
    // function pipe<A>(f : T->Thenable<A>) : Thenable<A>;
    function resolve(v : T): Void;
    function reject(e : Dynamic): Void;
    // function isResolved(): Bool;
    function isRejected(): Bool;
}
