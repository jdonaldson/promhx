package promhx.abs;
import promhx.Stream;
abstract AbstractStream<T> (Stream<T>) from Stream<T> to Stream<T> {
    @:op(A >> B) function then<T,A>( b:T->A ) : AbstractStream<A>
        return this.then(b);

    @:op(A || B) function pipe<T,A>( b:T->Stream<A> ) : AbstractStream<A>
        return this.pipe(b);
}
