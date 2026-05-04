import Toybox.Lang;
import Toybox.WatchUi;

class BowlingStatsDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new BowlingStatsMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onSelect() {
        return true;
    }

}
