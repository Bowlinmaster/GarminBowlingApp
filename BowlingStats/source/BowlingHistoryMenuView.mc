import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BowlingHistoryMenuView extends WatchUi.View {
    private var _selectedIndex as Number;

    function initialize() {
        WatchUi.View.initialize();
        _selectedIndex = 0;
    }

    function nextItem() as Void {
        _selectedIndex = (_selectedIndex + 1) % 3;
        WatchUi.requestUpdate();
    }

    function previousItem() as Void {
        _selectedIndex = (_selectedIndex + 2) % 3;
        WatchUi.requestUpdate();
    }

    function openSelectedItem() as Void {
        if (_selectedIndex == 0) {
            var statisticsView = new BowlingStatisticsView(
                BowlingSavedGameStore.getAggregateStatistics(),
                bowlingString(Rez.Strings.AllStatistics)
            );
            WatchUi.pushView(statisticsView, new BowlingStatisticsDelegate(statisticsView), WatchUi.SLIDE_IMMEDIATE);
        } else if (_selectedIndex == 1) {
            var seriesView = new SavedSeriesListView();
            WatchUi.pushView(seriesView, new SavedSeriesListDelegate(seriesView), WatchUi.SLIDE_IMMEDIATE);
        } else {
            var gamesView = new SavedGamesListView();
            WatchUi.pushView(gamesView, new SavedGamesListDelegate(gamesView), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var safeInset = BowlingScreenGeometry.getSafeInset(width, height);
        var title = bowlingString(Rez.Strings.HistoryTitle);
        var titleY = BowlingScreenGeometry.fitTopCenteredTextY(
            dc, width, height, Graphics.FONT_SMALL, title, height < 260 ? 20 : 28, safeInset
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var labels = [
            bowlingString(Rez.Strings.AllStatistics),
            bowlingString(Rez.Strings.Series),
            bowlingString(Rez.Strings.IndividualGames)
        ];
        var rowHeight = height < 260 ? 42 : (height >= 360 ? 62 : 50);
        var top = (height - (rowHeight * 3)) / 2;
        for (var index = 0; index < 3; index++) {
            var y = top + (index * rowHeight);
            var safeWidth = BowlingScreenGeometry.getSafeWidthForBand(width, height, y, y + rowHeight, safeInset);
            var maximumWidth = width - (width < 260 ? 36 : 56);
            if (safeWidth <= 0 || safeWidth > maximumWidth) {
                safeWidth = maximumWidth;
            }
            var left = (width - safeWidth) / 2;
            if (index == _selectedIndex) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(left, y, safeWidth, rowHeight - 2);
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y + (rowHeight / 2), Graphics.FONT_XTINY, labels[index], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
