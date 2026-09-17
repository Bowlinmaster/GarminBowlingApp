import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BowlingVisualTestApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new BowlingVisualGalleryView();
        return [view, new BowlingVisualTestMenuDelegate(view)];
    }
}

class BowlingVisualGalleryView extends WatchUi.View {
    private var _selectedIndex as Number;
    private var _width as Number;
    private var _height as Number;

    function initialize() {
        WatchUi.View.initialize();
        _selectedIndex = 0;
        _width = 0;
        _height = 0;
    }

    function setSelectedIndex(index as Number) as Void {
        _selectedIndex = index;
    }

    function onUpdate(dc as Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cellWidth = _width / 3;
        var cellHeight = _height / 3;
        for (var index = 0; index < 9; index++) {
            var column = index % 3;
            var row = (index / 3).toNumber();
            var centerX = (column * cellWidth) + (cellWidth / 2);
            var centerY = (row * cellHeight) + (cellHeight / 2);
            if (index == _selectedIndex) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
                dc.fillRectangle(column * cellWidth, row * cellHeight, cellWidth, cellHeight);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(column * cellWidth, row * cellHeight, cellWidth, cellHeight);
            }
            dc.drawText(centerX, centerY, Graphics.FONT_SMALL, (index + 1).format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class BowlingVisualTestMenuDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BowlingVisualGalleryView;
    private var _selectedIndex as Number;
    private const SCENARIO_IDS = [
        "new-game",
        "second-ball",
        "tenth-frame",
        "completed-game",
        "save-failure",
        "empty-history",
        "saved-games",
        "game-detail",
        "discard-dialog"
    ];

    function initialize(view as BowlingVisualGalleryView) {
        WatchUi.BehaviorDelegate.initialize();
        _view = view;
        _selectedIndex = 0;
    }

    function onNextPage() as Boolean {
        _selectedIndex = (_selectedIndex + 1) % SCENARIO_IDS.size();
        _view.setSelectedIndex(_selectedIndex);
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        _selectedIndex = (_selectedIndex + SCENARIO_IDS.size() - 1) % SCENARIO_IDS.size();
        _view.setSelectedIndex(_selectedIndex);
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        openScenario(_selectedIndex);
        return true;
    }

    private function openScenario(index as Number) as Void {
        var id = SCENARIO_IDS[index];

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

    function onBack() as Boolean {
        return true;
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
