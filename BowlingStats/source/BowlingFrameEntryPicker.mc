import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

//Class that is used to collect rolls for a frame
class BowlingFrameEntryPicker extends WatchUi.Picker {
    public var _factory as BowlingRollFactory;
    private var _title as Text;

    //Initialize the picker.
    public function initialize() {
        //I basically want to get the current frame number and the current ball roll.
        //I then want to use those as the title

        _factory = new BowlingRollFactory();
        //On the very initialization of this picker, it will be the very beginning of the game.
        //So in that case, the valid characters are going to be 0-X
        _factory.setCharacterSet("0123456789X");
        var titleText = "Frame: 1 Ball: 1";
        var pickerOptions = {:pattern=>[_factory]};
        //All possible picker options:
        /*
        :title - Drawable
        :pattern - Array or Drawable or Factory
        :defaults - Array
        :nextArrow - Drawable
        :previousArrow - Drawable
        :confirm - Drawable
        */

        //TODO: work on updating the title
        //TODO: Title is freaking huge.  How to have smaller title with picker?
        _title = new WatchUi.Text({
            :text=>titleText, 
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER, 
            :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, 
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_XTINY
        });

        pickerOptions[:title] = _title;
        Picker.initialize(pickerOptions);
        
    }

    //Update the view...
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    //TODO:  Need to update the factory based on... the current frame and roll
}

class BowlingFrameEntryPickerDelegate extends WatchUi.PickerDelegate {
    private var _picker as BowlingFrameEntryPicker;

    public function initialize(picker as BowlingFrameEntryPicker) {
        PickerDelegate.initialize();
        _picker = picker;
    }

    public function onCancel() as Boolean {
        System.println("trying to cancel");
        //TODO: If frame is 1 and roll is 1, pop the view
        //      else, do an unroll
        //          Probably need to delete the game from the list ad set the current game to null...
        $.getApp().player.getCurrentGame().unroll();
        return true;
    }

    public function onAccept(values as Array) as Boolean {
        var chosenValue = values[0] as String;
        var myRoll = _picker._factory.getIndex(chosenValue);
        System.println("About to roll: " + myRoll);
        $.getApp().player.getCurrentGame().roll(myRoll);
        return true;
    }
}

class BowlingRollFactory extends WatchUi.PickerFactory {
    private var _characterSet as String;
    public function initialize() {
        PickerFactory.initialize();
        self._characterSet = "";
    }

    public function setCharacterSet(characterSet as String) as Void {
        _characterSet = characterSet;
    }

    public function getIndex(value as String) as Number? {
        return _characterSet.find(value);
    }

    //Required method to override
    public function getSize() as Number {
        return _characterSet.length();
    }

    //Required method to override
    //For getValue, do I really want to return the string or do I really want to return the index which is the value of the choice
    public function getValue(index as Number) as Object? {
        return _characterSet.substring(index, index+1);
    }

    //Required method to override
    public function getDrawable(item, isSelected) as Drawable? {
        return new WatchUi.Text({
            :text=>getValue(item) as String,
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_GLANCE,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER
        });
    }
}