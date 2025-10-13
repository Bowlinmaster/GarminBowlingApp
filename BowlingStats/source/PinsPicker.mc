using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Graphics;

class PinsPickerFactory extends WatchUi.PickerFactory {

    var _labels; //Array if string labels
    var _values; //Corresponding array of int values

    function initialize(labels, values) {
        WatchUi.PickerFactory.initialize();
        _labels = labels;
        _values = values;
    }

    function getSize() {
        return _labels.size();
    }

    function getDrawable(index, isSelected) {
        return new WatchUi.Text({
            :text => _labels[index],
            :font => Graphics.FONT_NUMBER_MEDIUM,
            :justification => Graphics.TEXT_JUSTIFY_CENTER,
        });
    }

    function getValue(index) {
        return _values[index]; //numeric value
    }
}

class PinsPickerDelegate extends WatchUi.PickerDelegate {
    var _parentView; //optional reference to caller
    var _game; //optional reference to game

    function initialize(parent, game) {
        WatchUi.PickerDelegate.initialize();
        _parentView = parent;
        _game = game;
    }

    function onAccept(values) {
        System.println("Picker Delegate with values: " + values);
        var pickedValue = values[0];

        if(_game != null) {
            _game.recordThrow(pickedValue);
        }

        //pop the picked so the underlying view is visible again
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);

        if(_parentView != null) {
            //TODO....
            //_parentView.onPickerAccepted(pickedValue);
            //TODO: uhhh....
            _parentView.showPicker(_game.getPinsRemaining()); //show the picker again if needed
        }

        return true; //handled
    }

    function onCancel() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}