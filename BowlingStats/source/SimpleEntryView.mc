using Toybox.WatchUi;
using Toybox.Graphics;

class SimpleEntryView extends WatchUi.View {

    var _game;
    var _onComplete;

    //Constructor
    public function initialize(game, onComplete) {
        WatchUi.View.initialize();

        _game = game;
        _onComplete = onComplete;
        //How do I want to have a game? Should I do a new game here???

    }

    function onShow() as Void {
        System.println("In SimpleEntryView onShow");
        //Called when the view is shown.
        //Maybe I want to show a picker here?
        showPicker(10);
    }

    function showPicker(remainingPins) {
        var labels = [];
        var values = [];

        //TODO: This loop might be wrong including up to reamining
        for (var i = 0; i <= remainingPins; i++) {
            labels.add(i.toString());
            values.add(i);
        }

        if(remainingPins == 10) {
            labels.add("X");
            values.add(10);
        } else if (remainingPins > 0) {
            labels.add("/");
            values.add(remainingPins);
        }

        var factory = new PinsPickerFactory(labels, values);

        var options = {
            :title => new WatchUi.Text({ :text => "Pins knocked down"}),
            :pattern => [ factory ],
            :defaults => [0] //Start index.... TODO: might be wrong
        };

        var picker = new WatchUi.Picker(options);
        var delegate = new PinsPickerDelegate(self, _game);
        WatchUi.pushView(picker, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function onPinsSelected(selectedValue) {
        System.println("Selected: " + selectedValue);
        var knockedDown;
        if(selectedValue.equals("X")) {
            knockedDown = 10;
        } else if(selectedValue.equals("/")) {
            knockedDown = _game.getPinsRemaining();
        } else {
            knockedDown = selectedValue.toNumber();
        }

        _game.recordThrow(knockedDown);
        System.println("Added roll: " + knockedDown);

        if(_game.isGameComplete()){
            if(_onComplete != null){
                _onComplete.invoke(_game);
            }
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else {
            showPicker(_game.getPinsRemaining());
        }

    }

    function onUpdate(dc) {
        System.println("In SimpleEntryView onUpdate");
        dc.clear();
    }
}

//Do I even really care about this doing anything?
class SimpleEntryDelegate extends WatchUi.InputDelegate {

    var _game;
    var _onCompleteCallback;

    //Constructor
    public function initialize(game, onCompleteCallback) {
        WatchUi.InputDelegate.initialize();
        System.println("In SimpleEntryDelegate initialize");
        _game = game;
        _onCompleteCallback = onCompleteCallback;
    }

    function onBack() {
        System.println("In SimpleEntryDelegate onBack");
        //Pop back to the previous view.
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}