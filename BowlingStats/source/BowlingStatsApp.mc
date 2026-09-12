import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BowlingStatsApp extends Application.AppBase {
    const ENTRY_MODE_STORAGE_KEY = "entryMode";
    const ENTRY_MODE_SIMPLE = "simple";
    const ENTRY_MODE_PIN = "pin";
    const PIN_ENTRY_AVAILABLE = false;

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
        var menu = new WatchUi.Menu2({ :title => bowlingString(Rez.Strings.MainMenuTitle) });
        menu.addItem(new WatchUi.MenuItem(bowlingString(Rez.Strings.StartNewGame), null, "newgame", null));
        menu.addItem(new WatchUi.MenuItem(bowlingString(Rez.Strings.ViewGames), null, "viewgames", null));
        menu.addItem(new WatchUi.MenuItem(bowlingString(Rez.Strings.Settings), null, "settings", null));

        return menu;
    }

    function buildSettingsMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({ :title => bowlingString(Rez.Strings.Settings) });
        if (PIN_ENTRY_AVAILABLE) {
            var entryModeLabel = Lang.format(bowlingString(Rez.Strings.EntryModeFormat), [getEntryModeLabel()]);
            menu.addItem(new WatchUi.MenuItem(entryModeLabel, null, "togglemode", null));
        }
        menu.addItem(new WatchUi.MenuItem(bowlingString(Rez.Strings.ClearSavedGames), null, "cleargames", null));

        return menu;
    }

    function getEntryModeLabel() {
        return usePinEntryMode ? bowlingString(Rez.Strings.EntryModePin) : bowlingString(Rez.Strings.EntryModeSimple);
    }

    function toggleEntryMode() {
        setUsePinEntryMode(!usePinEntryMode);
    }

    function setUsePinEntryMode(value) {
        usePinEntryMode = PIN_ENTRY_AVAILABLE && value;
        Application.Storage.setValue(ENTRY_MODE_STORAGE_KEY, usePinEntryMode ? ENTRY_MODE_PIN : ENTRY_MODE_SIMPLE);
    }

    private function loadSettings() {
        var entryMode = Application.Storage.getValue(ENTRY_MODE_STORAGE_KEY);
        usePinEntryMode = PIN_ENTRY_AVAILABLE && entryMode == ENTRY_MODE_PIN;
    }

}

function getApp() as BowlingStatsApp {
    return Application.getApp() as BowlingStatsApp;
}
