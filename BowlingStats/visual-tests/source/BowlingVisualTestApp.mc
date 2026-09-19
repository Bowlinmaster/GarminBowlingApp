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
        var cellHeight = _height / 8;
        for (var index = 0; index < 24; index++) {
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
            var font = _height < 260 ? Graphics.FONT_XTINY : Graphics.FONT_SMALL;
            dc.drawText(centerX, centerY, font, (index + 1).format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
        "all-statistics-series",
        "series-statistics-accuracy",
        "series-statistics-spares",
        "series-statistics-counts",
        "history-menu",
        "saved-games",
        "series-list",
        "series-games",
        "game-detail",
        "all-statistics",
        "all-statistics-accuracy",
        "all-statistics-spares",
        "all-statistics-counts",
        "game-statistics",
        "game-statistics-accuracy",
        "game-statistics-spares",
        "game-statistics-counts",
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
        } else if (id.equals("history-menu")) {
            seedSavedGames();
            var historyView = new BowlingHistoryMenuView();
            WatchUi.pushView(historyView, new BowlingHistoryMenuDelegate(historyView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("series-list")) {
            seedSavedGames();
            var seriesListView = new SavedSeriesListView();
            WatchUi.pushView(seriesListView, new SavedSeriesListDelegate(seriesListView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("series-games")) {
            seedSavedGames();
            var selectedSeries = BowlingSavedGameStore.getSavedSeriesSummary(0) as Lang.Dictionary;
            var seriesGamesView = new SavedSeriesGamesView(selectedSeries);
            WatchUi.pushView(seriesGamesView, new BowlingSeriesMenuDelegate(seriesGamesView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("game-detail")) {
            seedSavedGames();
            var detailView = new SavedGameDetailView(0);
            WatchUi.pushView(detailView, new SavedGameDetailDelegate(detailView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("all-statistics")) {
            seedSavedGames();
            var statisticsView = new BowlingStatisticsView(
                BowlingSavedGameStore.getAggregateStatistics(),
                bowlingString(Rez.Strings.AllStatistics)
            );
            WatchUi.pushView(statisticsView, new BowlingStatisticsDelegate(statisticsView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("all-statistics-accuracy")) {
            seedSavedGames();
            var accuracyView = new BowlingStatisticsView(
                BowlingSavedGameStore.getAggregateStatistics(),
                bowlingString(Rez.Strings.AllStatistics)
            );
            accuracyView.nextPage();
            WatchUi.pushView(accuracyView, new BowlingStatisticsDelegate(accuracyView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("all-statistics-spares")) {
            seedSavedGames();
            var allSparesView = new BowlingStatisticsView(
                BowlingSavedGameStore.getAggregateStatistics(),
                bowlingString(Rez.Strings.AllStatistics)
            );
            allSparesView.nextPage();
            allSparesView.nextPage();
            WatchUi.pushView(allSparesView, new BowlingStatisticsDelegate(allSparesView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("all-statistics-counts")) {
            seedSavedGames();
            var allCountsView = new BowlingStatisticsView(
                BowlingSavedGameStore.getAggregateStatistics(),
                bowlingString(Rez.Strings.AllStatistics)
            );
            allCountsView.nextPage();
            allCountsView.nextPage();
            allCountsView.nextPage();
            WatchUi.pushView(allCountsView, new BowlingStatisticsDelegate(allCountsView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("all-statistics-series")) {
            var seriesView = new BowlingStatisticsView(
                buildSeriesStatistics(),
                bowlingString(Rez.Strings.SeriesStatistics)
            );
            WatchUi.pushView(seriesView, new BowlingStatisticsDelegate(seriesView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("series-statistics-accuracy")) {
            var seriesAccuracyView = new BowlingStatisticsView(
                buildSeriesStatistics(),
                bowlingString(Rez.Strings.SeriesStatistics)
            );
            seriesAccuracyView.nextPage();
            WatchUi.pushView(seriesAccuracyView, new BowlingStatisticsDelegate(seriesAccuracyView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("series-statistics-spares")) {
            var seriesSparesView = new BowlingStatisticsView(
                buildSeriesStatistics(),
                bowlingString(Rez.Strings.SeriesStatistics)
            );
            seriesSparesView.nextPage();
            seriesSparesView.nextPage();
            WatchUi.pushView(seriesSparesView, new BowlingStatisticsDelegate(seriesSparesView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("series-statistics-counts")) {
            var seriesCountsView = new BowlingStatisticsView(
                buildSeriesStatistics(),
                bowlingString(Rez.Strings.SeriesStatistics)
            );
            seriesCountsView.nextPage();
            seriesCountsView.nextPage();
            seriesCountsView.nextPage();
            WatchUi.pushView(seriesCountsView, new BowlingStatisticsDelegate(seriesCountsView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("game-statistics")) {
            seedSavedGames();
            var gameStatisticsView = new SavedGameDetailView(0);
            gameStatisticsView.nextPage();
            WatchUi.pushView(gameStatisticsView, new SavedGameDetailDelegate(gameStatisticsView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("game-statistics-accuracy")) {
            seedSavedGames();
            var gameAccuracyView = new SavedGameDetailView(0);
            gameAccuracyView.nextPage();
            gameAccuracyView.nextPage();
            WatchUi.pushView(gameAccuracyView, new SavedGameDetailDelegate(gameAccuracyView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("game-statistics-spares")) {
            seedSavedGames();
            var gameSparesView = new SavedGameDetailView(0);
            gameSparesView.nextPage();
            gameSparesView.nextPage();
            gameSparesView.nextPage();
            WatchUi.pushView(gameSparesView, new SavedGameDetailDelegate(gameSparesView), WatchUi.SLIDE_IMMEDIATE);
        } else if (id.equals("game-statistics-counts")) {
            seedSavedGames();
            var gameCountsView = new SavedGameDetailView(0);
            gameCountsView.nextPage();
            gameCountsView.nextPage();
            gameCountsView.nextPage();
            gameCountsView.nextPage();
            WatchUi.pushView(gameCountsView, new SavedGameDetailDelegate(gameCountsView), WatchUi.SLIDE_IMMEDIATE);
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

    private function buildSeriesStatistics() as Lang.Dictionary {
        return {
            BOWLING_STAT_GAME_COUNT => 2,
            BOWLING_STAT_TOTAL_SCORE => 300,
            BOWLING_STAT_HIGH_SCORE => 300,
            BOWLING_STAT_LOW_SCORE => 0,
            BOWLING_STAT_FIRST_BALL_PINS => 100,
            BOWLING_STAT_FIRST_BALL_ATTEMPTS => 20,
            BOWLING_STAT_STRIKES => 10,
            BOWLING_STAT_STRIKE_ATTEMPTS => 20,
            BOWLING_STAT_SPARES => 0,
            BOWLING_STAT_SPARE_ATTEMPTS => 10,
            BOWLING_STAT_OPEN_FRAMES => 10,
            BOWLING_STAT_SINGLE_PIN_ATTEMPTS => 4,
            BOWLING_STAT_SINGLE_PIN_SPARES => 3,
            BOWLING_STAT_MULTI_PIN_ATTEMPTS => 6,
            BOWLING_STAT_MULTI_PIN_SPARES => 2,
            BOWLING_STAT_CLEAN_FRAMES => 10
        };
    }

    private function seedSavedGames() as Void {
        BowlingSavedGameStore.clearSavedGames();
        BowlingSavedGameStore.saveGameAt(buildGutterGame(), 1767225600);
        BowlingSavedGameStore.saveGameAt(buildAllFivesGame(), 1767227400);
        BowlingSavedGameStore.saveGameAt(buildPerfectGame(), 1767229200);
        BowlingSavedGameStore.saveGameAt(buildGutterGame(), 1767312000);
        BowlingSavedGameStore.saveGameAt(buildPerfectGame(), 1767313800);
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
