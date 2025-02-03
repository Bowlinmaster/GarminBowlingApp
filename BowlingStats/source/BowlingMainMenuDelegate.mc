import Toybox.WatchUi;
import Toybox.Lang;

class BowlingMainMenuDelegate extends WatchUi.Menu2InputDelegate{

    //Constructor.
    public function initialize() {
        WatchUi.Menu2InputDelegate.initialize();
    }

    //When an item is selected from the main menu, go to the next view based on the selection.
    //Option 1: New Game (newgame)
    //Option 2: View Games (viewgames)
    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;
        var title = "Some title";
        if(id.equals("newgame")){
            System.println("Selected New Game");
            //Now go into the Picker view that will work through processing the game
        } else if (id.equals("viewgames")){
            System.println("Selected View Games");
            //Now go into the view that allows you to scroll through completed games.
        }
    }

    //If the back key is pressed on the main select menu, the application should exit.
    public function onBack() as Void {
        System.exit();
        //WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}