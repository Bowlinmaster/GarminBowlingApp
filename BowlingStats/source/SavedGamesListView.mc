import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SavedGamesListView extends WatchUi.View {
    const VISIBLE_ROW_COUNT = 3;

    var _gameCount;
    var _selectedIndex;

    function initialize() {
        WatchUi.View.initialize();
        _gameCount = BowlingSavedGameStore.getSavedGameCount();
        _selectedIndex = 0;
    }

    function nextGame() {
        if (_gameCount <= 1) {
            return;
        }

        _selectedIndex = (_selectedIndex + 1) % _gameCount;
        WatchUi.requestUpdate();
    }

    function previousGame() {
        if (_gameCount <= 1) {
            return;
        }

        _selectedIndex -= 1;
        if (_selectedIndex < 0) {
            _selectedIndex = _gameCount - 1;
        }

        WatchUi.requestUpdate();
    }

    function openSelectedGame() {
        if (_gameCount == 0) {
            return;
        }

        var detail = new SavedGameDetailView(_selectedIndex);
        WatchUi.pushView(detail, new SavedGameDetailDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }

    function onShow() {
        _gameCount = BowlingSavedGameStore.getSavedGameCount();
        if (_gameCount == 0) {
            _selectedIndex = 0;
        } else if (_selectedIndex >= _gameCount) {
            _selectedIndex = _gameCount - 1;
        }
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, centerX, height < 260 ? 20 : 28, Graphics.FONT_SMALL, bowlingString(Rez.Strings.SavedGamesTitle));

        if (_gameCount == 0) {
            drawCenteredText(dc, centerX, height / 2, Graphics.FONT_XTINY, bowlingString(Rez.Strings.NoSavedGames));
            return;
        }

        drawRows(dc, width, height);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, centerX, height - (height < 260 ? 18 : 24), Graphics.FONT_XTINY,
            (_selectedIndex + 1).toString() + "/" + _gameCount.toString());
    }

    private function drawRows(dc, width, height) {
        var rowHeight = height < 260 ? 42 : 50;
        if (height >= 360) {
            rowHeight = 62;
        }

        var listHeight = rowHeight * VISIBLE_ROW_COUNT;
        var top = (height - listHeight) / 2;
        var firstIndex = _selectedIndex - 1;

        for (var row = 0; row < VISIBLE_ROW_COUNT; row++) {
            var index = firstIndex + row;
            if (index < 0 || index >= _gameCount) {
                continue;
            }

            var summary = BowlingSavedGameStore.getSavedGameSummary(index) as Lang.Dictionary?;
            if (summary != null) {
                drawSummaryRow(dc, summary, index == _selectedIndex, width, top + (row * rowHeight), rowHeight);
            }
        }

        _gameCount = BowlingSavedGameStore.getSavedGameCount();
    }

    private function drawSummaryRow(dc, summary as Lang.Dictionary, isSelected, width, y, height) {
        var horizontalInset = width < 260 ? 18 : 28;
        var left = horizontalInset;
        var right = width - horizontalInset;

        if (isSelected) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRectangle(left, y, right - left, height - 2);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left + 8, y + (height / 2), Graphics.FONT_XTINY, getSavedAtText(summary), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(right - 8, y + (height / 2), Graphics.FONT_SMALL, summary[BOWLING_SAVED_GAME_SCORE].toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function getSavedAtText(summary as Lang.Dictionary) {
        var savedAt = summary[BOWLING_SAVED_GAME_SAVED_AT];
        var info = Gregorian.info(new Time.Moment(savedAt), Time.FORMAT_SHORT);
        var year = info.year % 100;

        return info.month.format("%02d") + "/" +
               info.day.format("%02d") + "/" +
               year.format("%02d") + " " +
               info.hour.format("%02d") + ":" +
               info.min.format("%02d");
    }

    private function drawCenteredText(dc, x, y, font, text) {
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
