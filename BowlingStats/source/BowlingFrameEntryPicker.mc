import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

//Class that is used to collect rolls for a frame
class BowlingFrameEntryPicker extends WatchUi.Picker {
    public var _factory as BowlingRollFactory;
    private var _title as Text;
    private var _pickerOptions;

    //Initialize the picker.
    public function initialize() {
        //I basically want to get the current frame number and the current ball roll.
        //I then want to use those as the title

        _factory = new BowlingRollFactory();
        //On the very initialization of this picker, it will be the very beginning of the game.
        //So in that case, the valid characters are going to be 0-X
        //_factory.setCharacterSet("0123456789X");
        _factory.setCharacterSet("-123456789X");
        var titleText = "Frame: 1 Ball: 1";
        _pickerOptions = {:pattern=>[_factory]};
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

        _pickerOptions[:title] = _title;
        _pickerOptions[:defaults] = [10];
        Picker.initialize(_pickerOptions);
        
    }

    //Update the view...
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    //TODO:  Need to update the factory based on... the current frame and roll
    public function setPickerTitle(score as String, frame as String, roll as String) {
        //_pickerOptions[:title] = "Frame: " + frame + " Ball: " + roll;
        _pickerOptions[:title] = new WatchUi.Text({
            :text=>"Score: " + score + "\nFrame: " + frame + " Ball: " + roll,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM,
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_XTINY
        });
        Picker.initialize(_pickerOptions);
    }

    public function setPickerFactoryCharacterSetFromScore(maxScore as Number) {
        var newCharacterSet = "";
        var loopScore = 0;
        while(loopScore <= maxScore){
            if(loopScore == maxScore){
                newCharacterSet = newCharacterSet + "/";
            }
            else if (loopScore == 0) {
                newCharacterSet = newCharacterSet + "-";
            }
            else {
                newCharacterSet = newCharacterSet + loopScore.toString();
            }
            loopScore++;
        }
        self.setPickerFactoryCharacterSet(newCharacterSet);
    }
    public function setPickerFactoryCharacterSet(newCharSet as String) {
        System.println("New score set is going to be: " + newCharSet);
        self._factory.setCharacterSet(newCharSet);
        self._pickerOptions[:pattern] = [self._factory];
        System.println("Default is about to be: " + (newCharSet.length()-1));
        self._pickerOptions[:defaults] = [newCharSet.length()-1];
        Picker.initialize(self._pickerOptions);
    }
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
        //$.getApp().player.getCurrentGame().unroll();
        return true;
    }

    public function onAccept(values as Array) as Boolean {
        var chosenValue = values[0] as String;
        var myRollIndex = _picker._factory.getIndex(chosenValue);
        //var myRoll = 10-myRollIndex;
        var myRoll = myRollIndex;
        System.println("About to roll: " + myRoll);
        //$.getApp().player.getCurrentGame().roll(myRoll);

        //Now that we have rolled the ball, go ahead and update visual information for the next roll.
        
        //Update the title 
        /*var nextRollNum = $.getApp().player.getCurrentGame().getCurrentRollNumber();
        var nextFrameNum = $.getApp().player.getCurrentGame().getCurrentFrameNumber();
        var nextScore = $.getApp().player.getCurrentGame().getScore();
        System.println("The next frame and roll is now going to be: " + nextFrameNum + " " + nextRollNum);
        _picker.setPickerTitle(nextScore.toString(), nextFrameNum.toString(), nextRollNum.toString());

        //Update the factory options based on the score just selected.
        if(nextRollNum == 1){
            //Then we just threw a strike or completed a spare.
            _picker.setPickerFactoryCharacterSet("-123456789X");
        } else {
            //TODO: Need to handle 10th frame case.
            _picker.setPickerFactoryCharacterSetFromScore(10-myRoll);
        }*/

        //TODO: Should we instead push a new picker instead of trying to update the above?
        //      The reason why updating above might not be good is because once I update the options, I'm given an empty choice.
        
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
            :font=>Graphics.FONT_SYSTEM_LARGE,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER
        });
    }
}