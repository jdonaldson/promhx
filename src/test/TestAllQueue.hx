import promhx.base.EventLoop;

/**
  A simple proxy for TestAll that provides a toy event loop mechanism
  for promhx.base.EventLoop.
 **/
class TestAllQueue {
    static function main() {
        var loopQueue : Array<Void->Void> = [];
        EventLoop.nextLoop = loopQueue.push; 
        // call the TestAll start function with a precheck callback.
        TestAll.start(function() EventLoop.finish());
    }
}
