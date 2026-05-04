import Toybox.WatchUi;
import Toybox.Lang;

class BowlingMainMenu2Delegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        WatchUi.Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;

        if(id.equals("newgame")) {
            var app = $.getApp();

            var game = new Game();
            var view;
            var theDelegate;
            if(app.usePinEntryMode){
                // Pin-entry mode is persisted now, but still falls back until the pin-deck view exists.
                view = new SimpleEntryView(game, method(:onGameComplete));
                theDelegate = new SimpleEntryDelegate(game, method(:onGameComplete));
            } else {
                view = new SimpleEntryView(game, method(:onGameComplete));
                theDelegate = new SimpleEntryDelegate(game, method(:onGameComplete));
            }

            theDelegate.setView(view);
            WatchUi.pushView(view, theDelegate, WatchUi.SLIDE_IMMEDIATE);

        } else if (id.equals("viewgames")) {
        } else if (id.equals("settings")) {
            var settingsMenu = $.getApp().buildSettingsMenu();
            WatchUi.pushView(settingsMenu, new $.BowlingSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    public function onBack() as Void {
        System.exit();
    }

    public function onGameComplete() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
