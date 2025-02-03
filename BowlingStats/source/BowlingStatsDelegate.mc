import Toybox.Lang;
import Toybox.WatchUi;

class BowlingStatsDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        System.println("Delegate - initialize()");
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        System.println("Delegate - onMenu()");
        WatchUi.pushView(new Rez.Menus.MainMenu(), new BowlingStatsMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onSelect() {
        System.println("Delegate and I just aded the ability to click select");
        return true;
    }

}