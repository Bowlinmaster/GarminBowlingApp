import Toybox.WatchUi;
import Toybox.Lang;

class BowlingMainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _activeGame;

    public function initialize() {
        WatchUi.Menu2InputDelegate.initialize();
        _activeGame = null;
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;

        if(id.equals("newgame")) {
            var game = new BowlingGame();
            _activeGame = game;
            var view = new SimpleEntryView(game, method(:onGameComplete), method(:onDiscardUnsavedGame));
            var theDelegate = new SimpleEntryDelegate(game, method(:onGameComplete));

            theDelegate.setView(view);
            WatchUi.pushView(view, theDelegate, WatchUi.SLIDE_IMMEDIATE);

        } else if (id.equals("viewgames")) {
            var historyView = new BowlingHistoryMenuView();
            WatchUi.pushView(historyView, new BowlingHistoryMenuDelegate(historyView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("settings")) {
            var settingsMenu = $.getApp().buildSettingsMenu();
            WatchUi.pushView(settingsMenu, new $.BowlingSettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    public function onBack() as Void {
        System.exit();
    }

    public function onGameComplete() {
        if (_activeGame == null || !BowlingSavedGameStore.saveGame(_activeGame)) {
            return false;
        }

        _activeGame = null;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    public function onDiscardUnsavedGame() as Void {
        _activeGame = null;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
