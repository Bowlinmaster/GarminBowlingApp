import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SavedSeriesListView extends WatchUi.View {
    const VISIBLE_ROW_COUNT = 3;

    private var _seriesCount as Number;
    private var _selectedIndex as Number;

    function initialize() {
        WatchUi.View.initialize();
        _seriesCount = BowlingSavedGameStore.getSavedSeriesCount();
        _selectedIndex = 0;
    }

    function nextSeries() as Void {
        if (_seriesCount == 0) {
            return;
        }
        _selectedIndex = (_selectedIndex + 1) % _seriesCount;
        WatchUi.requestUpdate();
    }

    function previousSeries() as Void {
        if (_seriesCount == 0) {
            return;
        }
        _selectedIndex -= 1;
        if (_selectedIndex < 0) {
            _selectedIndex = _seriesCount - 1;
        }
        WatchUi.requestUpdate();
    }

    function openSelectedSeries() as Void {
        var summary = BowlingSavedGameStore.getSavedSeriesSummary(_selectedIndex);
        if (summary == null) {
            return;
        }

        var view = new SavedSeriesGamesView(summary);
        WatchUi.pushView(view, new BowlingSeriesMenuDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    }

    function onShow() as Void {
        _seriesCount = BowlingSavedGameStore.getSavedSeriesCount();
        if (_seriesCount == 0) {
            _selectedIndex = 0;
        } else if (_selectedIndex >= _seriesCount) {
            _selectedIndex = _seriesCount - 1;
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var safeInset = BowlingScreenGeometry.getSafeInset(width, height);
        var title = bowlingString(Rez.Strings.SeriesListTitle);
        var titleY = BowlingScreenGeometry.fitTopCenteredTextY(
            dc, width, height, Graphics.FONT_SMALL, title, height < 260 ? 20 : 28, safeInset
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (_seriesCount == 0) {
            dc.drawText(centerX, height / 2, Graphics.FONT_XTINY, bowlingString(Rez.Strings.NoSavedGames), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        drawRows(dc, width, height);
        var positionText = (_selectedIndex + 1).toString() + "/" + _seriesCount.toString();
        var positionY = BowlingScreenGeometry.fitBottomCenteredTextY(
            dc, width, height, Graphics.FONT_XTINY, positionText,
            height - (height < 260 ? 18 : 24), safeInset
        );
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, positionY, Graphics.FONT_XTINY, positionText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawRows(dc as Dc, width as Number, height as Number) as Void {
        var rowHeight = height < 260 ? 42 : 50;
        if (height >= 360) {
            rowHeight = 62;
        }
        var top = (height - (rowHeight * VISIBLE_ROW_COUNT)) / 2;
        var firstIndex = _selectedIndex - 1;

        for (var row = 0; row < VISIBLE_ROW_COUNT; row++) {
            var index = firstIndex + row;
            if (index < 0 || index >= _seriesCount) {
                continue;
            }

            var summary = BowlingSavedGameStore.getSavedSeriesSummary(index);
            if (summary != null) {
                drawSeriesRow(dc, summary, index == _selectedIndex, width, top + (row * rowHeight), rowHeight);
            }
        }
    }

    private function drawSeriesRow(dc as Dc, summary as Lang.Dictionary, selected as Boolean, width as Number, y as Number, height as Number) as Void {
        var bounds = getRowBounds(dc, width, y, height);
        var left = bounds[0];
        var right = bounds[1];
        if (selected) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRectangle(left, y, right - left, height - 2);
        }

        var startedAt = summary[BOWLING_SAVED_SERIES_STARTED_AT] as Number;
        var info = Gregorian.info(new Time.Moment(startedAt), Time.FORMAT_SHORT);
        var dateText = info.month.format("%02d") + "/" + info.day.format("%02d") + "/" +
            (info.year % 100).format("%02d") + " " + info.hour.format("%02d") + ":" + info.min.format("%02d");
        var gameCount = summary[BOWLING_SAVED_SERIES_GAME_COUNT] as Number;
        var countText = gameCount == 1 ? bowlingString(Rez.Strings.OneGame) :
            Lang.format(bowlingString(Rez.Strings.GameCountFormat), [gameCount]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var centerX = (left + right) / 2;
        dc.drawText(centerX, y + (height / 4), Graphics.FONT_XTINY, dateText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y + ((height * 3) / 4) - 2, Graphics.FONT_XTINY, countText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function getRowBounds(dc as Dc, width as Number, y as Number, height as Number) as Array<Number> {
        var horizontalInset = width < 260 ? 18 : 28;
        var maximumWidth = width - (horizontalInset * 2);
        var safeWidth = BowlingScreenGeometry.getSafeWidthForBand(
            width, dc.getHeight(), y, y + height, BowlingScreenGeometry.getSafeInset(width, dc.getHeight())
        );
        if (safeWidth <= 0 || safeWidth > maximumWidth) {
            safeWidth = maximumWidth;
        }
        var left = (width - safeWidth) / 2;
        return [left, left + safeWidth];
    }
}
