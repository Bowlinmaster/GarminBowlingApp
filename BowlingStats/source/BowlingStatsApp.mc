import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BowlingStatsApp extends Application.AppBase {
    const ENTRY_MODE_STORAGE_KEY = "entryMode";
    const ENTRY_MODE_SIMPLE = "simple";
    const ENTRY_MODE_PIN = "pin";

    var usePinEntryMode = false;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        loadSettings();
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var menu = buildMainMenu();
        return [menu, new $.BowlingMainMenu2Delegate()];
    }

    function buildMainMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({ :title => "Bowling" });
        menu.addItem(new WatchUi.MenuItem("Start New Game", null, "newgame", null));
        menu.addItem(new WatchUi.MenuItem("View Games", null, "viewgames", null));
        menu.addItem(new WatchUi.MenuItem("Settings", null, "settings", null));

        return menu;
    }

    function buildSettingsMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({ :title => "Settings" });
        menu.addItem(new WatchUi.MenuItem("Entry Mode: " + getEntryModeLabel(), null, "togglemode", null));

        return menu;
    }

    function getEntryModeLabel() {
        return usePinEntryMode ? "Pin" : "Simple";
    }

    function toggleEntryMode() {
        setUsePinEntryMode(!usePinEntryMode);
    }

    function setUsePinEntryMode(value) {
        usePinEntryMode = value;
        Application.Storage.setValue(ENTRY_MODE_STORAGE_KEY, usePinEntryMode ? ENTRY_MODE_PIN : ENTRY_MODE_SIMPLE);
    }

    private function loadSettings() {
        var entryMode = Application.Storage.getValue(ENTRY_MODE_STORAGE_KEY);
        usePinEntryMode = entryMode == ENTRY_MODE_PIN;
    }

}

function getApp() as BowlingStatsApp {
    return Application.getApp() as BowlingStatsApp;
}
