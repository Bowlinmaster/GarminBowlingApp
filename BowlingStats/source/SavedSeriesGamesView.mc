import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SavedSeriesGamesView extends WatchUi.View {
    private var _seriesSummary as Lang.Dictionary;
    private var _selectedIndex as Number;
    private var _itemCount as Number;

    function initialize(seriesSummary as Lang.Dictionary) {
        WatchUi.View.initialize();
        _seriesSummary = seriesSummary;
        _selectedIndex = 0;
        _itemCount = (seriesSummary[BOWLING_SAVED_SERIES_GAME_COUNT] as Number) + 1;
    }

    function nextItem() as Void {
        _selectedIndex = (_selectedIndex + 1) % _itemCount;
        WatchUi.requestUpdate();
    }

    function previousItem() as Void {
        _selectedIndex = (_selectedIndex + _itemCount - 1) % _itemCount;
        WatchUi.requestUpdate();
    }

    function openSelectedItem() as Void {
        if (_selectedIndex == 0) {
            var statisticsView = new BowlingStatisticsView(
                BowlingSavedGameStore.getSavedSeriesStatistics(_seriesSummary),
                bowlingString(Rez.Strings.SeriesStatistics)
            );
            WatchUi.pushView(statisticsView, new BowlingStatisticsDelegate(statisticsView), WatchUi.SLIDE_IMMEDIATE);
            return;
        }

        var startIndex = _seriesSummary[BOWLING_SAVED_SERIES_START_INDEX] as Number;
        var gameCount = _seriesSummary[BOWLING_SAVED_SERIES_GAME_COUNT] as Number;
        var gameIndex = startIndex + gameCount - _selectedIndex;
        var detail = new SavedGameDetailView(gameIndex);
        WatchUi.pushView(detail, new SavedGameDetailDelegate(detail), WatchUi.SLIDE_IMMEDIATE);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var safeInset = BowlingScreenGeometry.getSafeInset(width, height);
        var title = bowlingString(Rez.Strings.SeriesGames);
        var titleY = BowlingScreenGeometry.fitTopCenteredTextY(
            dc, width, height, Graphics.FONT_SMALL, title, height < 260 ? 20 : 28, safeInset
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var rowHeight = height < 260 ? 42 : (height >= 360 ? 62 : 50);
        var top = (height - (rowHeight * 3)) / 2;
        var firstIndex = _selectedIndex - 1;
        for (var row = 0; row < 3; row++) {
            var itemIndex = firstIndex + row;
            if (itemIndex < 0 || itemIndex >= _itemCount) {
                continue;
            }
            drawItem(dc, itemIndex, itemIndex == _selectedIndex, width, top + (row * rowHeight), rowHeight, safeInset);
        }

        var positionText = (_selectedIndex + 1).toString() + "/" + _itemCount.toString();
        var positionY = BowlingScreenGeometry.fitBottomCenteredTextY(
            dc, width, height, Graphics.FONT_XTINY, positionText,
            height - (height < 260 ? 18 : 24), safeInset
        );
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, positionY, Graphics.FONT_XTINY, positionText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawItem(dc as Dc, itemIndex as Number, selected as Boolean, width as Number, y as Number, height as Number, safeInset as Number) as Void {
        var safeWidth = BowlingScreenGeometry.getSafeWidthForBand(width, dc.getHeight(), y, y + height, safeInset);
        var maximumWidth = width - (width < 260 ? 36 : 56);
        if (safeWidth <= 0 || safeWidth > maximumWidth) {
            safeWidth = maximumWidth;
        }
        var left = (width - safeWidth) / 2;
        if (selected) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRectangle(left, y, safeWidth, height - 2);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (itemIndex == 0) {
            dc.drawText(width / 2, y + (height / 2), Graphics.FONT_XTINY, bowlingString(Rez.Strings.SeriesStatistics), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var startIndex = _seriesSummary[BOWLING_SAVED_SERIES_START_INDEX] as Number;
        var gameCount = _seriesSummary[BOWLING_SAVED_SERIES_GAME_COUNT] as Number;
        var gameIndex = startIndex + gameCount - itemIndex;
        var summary = BowlingSavedGameStore.getSavedGameSummary(gameIndex);
        if (summary == null) {
            return;
        }
        var label = Lang.format(bowlingString(Rez.Strings.GameNumberFormat), [itemIndex]);
        var score = Lang.format(bowlingString(Rez.Strings.ScoreFormat), [summary[BOWLING_SAVED_GAME_SCORE]]);
        dc.drawText(width / 2, y + (height / 4), Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y + ((height * 3) / 4), Graphics.FONT_XTINY, score, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
