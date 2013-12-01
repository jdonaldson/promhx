import promhx.Stream;
using flash.promhx.EventTools;

class DemoFlash {
    static function main() {
        var cur = flash.Lib.current.stage;
        EventTools.eventStream(cur, 'click');
         
        

    }
}
