import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class BowlingVisualTestApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var menu = new WatchUi.Menu2({ :title => "Visual Gallery" });
        menu.addItem(new WatchUi.MenuItem("01 New game", null, "new-game", null));
        menu.addItem(new WatchUi.MenuItem("02 Second ball", null, "second-ball", null));
        menu.addItem(new WatchUi.MenuItem("03 Tenth frame", null, "tenth-frame", null));
        menu.addItem(new WatchUi.MenuItem("04 Completed game", null, "completed-game", null));
        menu.addItem(new WatchUi.MenuItem("05 Save failure", null, "save-failure", null));
        menu.addItem(new WatchUi.MenuItem("06 Empty history", null, "empty-history", null));
        menu.addItem(new WatchUi.MenuItem("07 Saved games", null, "saved-games", null));
        menu.addItem(new WatchUi.MenuItem("08 Game detail", null, "game-detail", null));
        menu.addItem(new WatchUi.MenuItem("09 Discard dialog", null, "discard-dialog", null));
        return [menu, new BowlingVisualTestMenuDelegate()];
    }
}

class BowlingVisualTestMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        WatchUi.Menu2InputDelegate.initialize();
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId() as String;

        if (id.equals("new-game")) {
            pushEntryView(new BowlingGame(), false);
        } else if (id.equals("second-ball")) {
            var secondBallGame = new BowlingGame();
            secondBallGame.recordThrow(6);
            pushEntryView(secondBallGame, false);
        } else if (id.equals("tenth-frame")) {
            var tenthFrameGame = buildGameThroughNineFrames();
            tenthFrameGame.recordThrow(10);
            tenthFrameGame.recordThrow(7);
            pushEntryView(tenthFrameGame, false);
        } else if (id.equals("completed-game")) {
            pushEntryView(buildPerfectGame(), false);
        } else if (id.equals("save-failure")) {
            pushEntryView(buildPerfectGame(), true);
        } else if (id.equals("empty-history")) {
            BowlingSavedGameStore.clearSavedGames();
            var emptyView = new SavedGamesListView();
            WatchUi.pushView(emptyView, new SavedGamesListDelegate(emptyView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("saved-games")) {
            seedSavedGames();
            var listView = new SavedGamesListView();
            WatchUi.pushView(listView, new SavedGamesListDelegate(listView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("game-detail")) {
            seedSavedGames();
            WatchUi.pushView(new SavedGameDetailView(0), new SavedGameDetailDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("discard-dialog")) {
            var confirmation = new WatchUi.Confirmation(bowlingString(Rez.Strings.DiscardCurrentGameConfirmation));
            WatchUi.pushView(confirmation, new BowlingVisualTestConfirmationDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onBack() as Void {
        System.exit();
    }

    private function pushEntryView(game as BowlingGame, forceSaveFailure as Boolean) as Void {
        var callback = forceSaveFailure ? method(:failSave) : method(:keepOpen);
        var view = new SimpleEntryView(game, callback, null);
        var delegate = new SimpleEntryDelegate(game, callback);
        delegate.setView(view);

        if (forceSaveFailure) {
            view.acceptSelection();
        }

        WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function keepOpen() as Boolean {
        return true;
    }

    function failSave() as Boolean {
        return false;
    }

    private function buildGameThroughNineFrames() as BowlingGame {
        var game = new BowlingGame();
        for (var i = 0; i < 18; i++) {
            game.recordThrow(0);
        }
        return game;
    }

    private function buildPerfectGame() as BowlingGame {
        var game = new BowlingGame();
        for (var i = 0; i < 12; i++) {
            game.recordThrow(10);
        }
        return game;
    }

    private function buildAllFivesGame() as BowlingGame {
        var game = new BowlingGame();
        for (var i = 0; i < 21; i++) {
            game.recordThrow(5);
        }
        return game;
    }

    private function buildGutterGame() as BowlingGame {
        var game = new BowlingGame();
        for (var i = 0; i < 20; i++) {
            game.recordThrow(0);
        }
        return game;
    }

    private function seedSavedGames() as Void {
        BowlingSavedGameStore.clearSavedGames();
        BowlingSavedGameStore.saveGameAt(buildGutterGame(), 1767225600);
        BowlingSavedGameStore.saveGameAt(buildAllFivesGame(), 1767312000);
        BowlingSavedGameStore.saveGameAt(buildPerfectGame(), 1767398400);
    }
}

class BowlingVisualTestConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }

    function onResponse(response) as Boolean {
        return true;
    }
}
