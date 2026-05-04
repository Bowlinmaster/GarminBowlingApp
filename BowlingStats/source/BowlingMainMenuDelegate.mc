import Toybox.WatchUi;
import Toybox.Lang;

//Menu2 implementation
class BowlingMainMenu2Delegate extends WatchUi.Menu2InputDelegate {
    
    //initialize the delegate
    public function initialize() {
        WatchUi.Menu2InputDelegate.initialize();
        
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;

        if(id.equals("newgame")) {
            var app = $.getApp();
            System.println("Selected New Game");
            //Go ahead and actually start the new game.
            //$.getApp().player.startNewGame();

            //Now go into the Picker view that will work through processing the game
            //Create the picker and also pass it into the delegate.  TODO: Might not need to pass to delegate.  Evaluate dependency in delegate
            //var picker = new $.BowlingFrameEntryPicker();
            //WatchUi.pushView(picker, new $.BowlingFrameEntryPickerDelegate(picker), WatchUi.SLIDE_IMMEDIATE);

            //TODO: Now I want to actually get into the game based on the current pinEntryMode
            var game = new Game();
            var view;
            var theDelegate;
            if(app.usePinEntryMode){
                //view = new PinEntryView();
                view = new SimpleEntryView(game, method(:onGameComplete)); //TMP to compile
                theDelegate = new SimpleEntryDelegate(game, method(:onGameComplete));
            } else {
                view = new SimpleEntryView(game, method(:onGameComplete));
                theDelegate = new SimpleEntryDelegate(game, method(:onGameComplete));
            }

            theDelegate.setView(view);
            WatchUi.pushView(view, theDelegate, WatchUi.SLIDE_IMMEDIATE);

        } else if (id.equals("viewgames")) {
            System.println("Selected view games");
        } else if (id.equals("settings")) {
            var settingsMenu = $.getApp().buildSettingsMenu();
            WatchUi.pushView(settingsMenu, new $.BowlingSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    public function onBack() as Void {
        System.exit();
    }

    public function onGameComplete() as Void {
        System.println("In onGameComplete callback");
        //When the game is complete, pop back to the main menu.
        //WatchUi.popToRootView(WatchUi.SLIDE_IMMEDIATE);
    }
}

/*
//Menu implementation
class BowlingMainMenuDelegate extends WatchUi.MenuInputDelegate{

    //Constructor.
    public function initialize() {
        WatchUi.MenuInputDelegate.initialize();
    }

    //:one is newgame
    //:two is viewgames
    public function onMenuItem(item) {
        if (item == :one) {
            System.println("Selected new game from og menu");
            //Now go into the Picker view that will work through precessing the bowling game.
            //Create the picker and also pass it into the delegate.  TODO: Might not need to pass to delegate.  Evaluate dependency in delegate
            var picker = new $.BowlingFrameEntryPicker();
            WatchUi.pushView(picker, new $.BowlingFrameEntryPickerDelegate(picker), WatchUi.SLIDE_IMMEDIATE);
        }
        else if (item == :two) {
            System.println("Selected view games from og menu");
            //Now go into the view that allows you to scroll through completed games.
        }
    }

    //If the back key is pressed on the main select menu, the application should exit.
    public function onBack() as Void {
        System.exit();
    }
}
*/
