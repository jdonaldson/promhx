package promhx.error;

enum PromiseError {
    AlreadyResolved(message: String);
    DownstreamNotFullfilled(message: String);
    AlreadyEnded(message: String);
}
