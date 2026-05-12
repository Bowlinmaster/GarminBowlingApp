import Toybox.Lang;
import Toybox.WatchUi;

class BowlingSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        WatchUi.Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;

        if (id.equals("togglemode")) {
            var app = $.getApp();
            app.toggleEntryMode();

            var settingsMenu = app.buildSettingsMenu();
            WatchUi.switchToView(settingsMenu, new $.BowlingSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("cleargames")) {
            var confirmation = new WatchUi.Confirmation("Clear saved games?");
            WatchUi.pushView(confirmation, new $.BowlingClearSavedGamesConfirmationDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
