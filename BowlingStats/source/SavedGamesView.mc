import Toybox.Graphics;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SavedGamesView extends WatchUi.View {
    var _games;
    var _selectedIndex;

    function initialize() {
        WatchUi.View.initialize();
        _games = BowlingSavedGameStore.getSavedGames();
        _selectedIndex = 0;
    }

    function nextGame() {
        if (_games.size() <= 1) {
            return;
        }

        _selectedIndex = (_selectedIndex + 1) % _games.size();
        WatchUi.requestUpdate();
    }

    function previousGame() {
        if (_games.size() <= 1) {
            return;
        }

        _selectedIndex -= 1;
        if (_selectedIndex < 0) {
            _selectedIndex = _games.size() - 1;
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        if (_games.size() == 0) {
            drawEmptyState(dc, centerX, height / 2);
            return;
        }

        var savedGame = _games[_selectedIndex];
        var game = buildGame(savedGame[BOWLING_SAVED_GAME_PIN_COUNTS]);

        drawHeader(dc, savedGame, centerX, height);
        drawScorecard(dc, game, width, height);
        drawPosition(dc, centerX, height);
    }

    private function drawEmptyState(dc, centerX, centerY) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, centerX, centerY - 12, Graphics.FONT_SMALL, "No saved games");

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, centerX, centerY + 14, Graphics.FONT_XTINY, "Finish a game first");
    }

    private function drawHeader(dc, savedGame, centerX, height) {
        var dateY = height < 260 ? 18 : 24;
        var scoreY = height < 260 ? 42 : 52;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, centerX, dateY, Graphics.FONT_XTINY, getSavedAtText(savedGame));

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var score = savedGame[BOWLING_SAVED_GAME_SCORE];
        drawCenteredText(dc, centerX, scoreY, Graphics.FONT_MEDIUM, "Score " + score.toString());
    }

    private function drawScorecard(dc, game, width, height) {
        var totalWidth = width - 28;
        if (totalWidth > 360) {
            totalWidth = 360;
        }

        var cellWidth = totalWidth / 5;
        var rowHeight = height < 260 ? 40 : 46;
        if (height >= 360) {
            rowHeight = 58;
        }

        var left = (width - (cellWidth * 5)) / 2;
        var top = height < 260 ? 64 : 76;
        if (height >= 360) {
            top = 104;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var frameIndex = 0; frameIndex < 10; frameIndex++) {
            var column = frameIndex % 5;
            var row = frameIndex / 5;
            var x = left + (column * cellWidth);
            var y = top + (row * (rowHeight + 4));
            drawMiniFrame(dc, game, frameIndex, x, y, cellWidth, rowHeight);
        }
    }

    private function drawMiniFrame(dc, game, frameIndex, x, y, width, height) {
        var headerHeight = height / 4;
        var rollHeight = height / 3;
        var scoreTop = y + headerHeight + rollHeight;

        dc.drawRectangle(x, y, width, height);
        dc.drawLine(x, y + headerHeight, x + width, y + headerHeight);
        dc.drawLine(x, scoreTop, x + width, scoreTop);

        drawCenteredText(dc, x + (width / 2), y + (headerHeight / 2), Graphics.FONT_XTINY, (frameIndex + 1).toString());

        var frame = game.getFrame(frameIndex);
        drawCenteredText(dc, x + (width / 2), y + headerHeight + (rollHeight / 2), Graphics.FONT_XTINY, getFrameRollText(frame, frameIndex));

        var score = game.getCumulativeScoreThrough(frameIndex);
        var scoreText = score == null ? "" : score.toString();
        drawCenteredText(dc, x + (width / 2), scoreTop + ((height - headerHeight - rollHeight) / 2), Graphics.FONT_XTINY, scoreText);
    }

    private function drawPosition(dc, centerX, height) {
        if (_games.size() <= 1) {
            return;
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var y = height - (height < 260 ? 20 : 28);
        drawCenteredText(dc, centerX, y, Graphics.FONT_XTINY, (_selectedIndex + 1).toString() + "/" + _games.size().toString());
    }

    private function buildGame(pins) {
        var game = new BowlingGame();
        for (var i = 0; i < pins.size(); i++) {
            game.recordThrow(pins[i]);
        }

        return game;
    }

    private function getFrameRollText(frame, frameIndex) {
        if (frameIndex < 9 && frame.isStrike()) {
            return "X";
        }

        var labels = [];
        var maxRolls = frameIndex == 9 ? 3 : 2;
        for (var rollIndex = 0; rollIndex < maxRolls; rollIndex++) {
            var label = getRollLabel(frame, rollIndex);
            if (!label.equals("")) {
                labels.add(label);
            }
        }

        return joinLabels(labels);
    }

    private function joinLabels(labels) {
        var text = "";
        for (var i = 0; i < labels.size(); i++) {
            if (i > 0) {
                text += " ";
            }

            text += labels[i];
        }

        return text;
    }

    private function getRollLabel(frame, rollIndex) {
        var pins = frame.getPinsAt(rollIndex);
        if (pins == null) {
            return "";
        }

        if (pins == 0) {
            return "-";
        }

        if (rollIndex == 1) {
            var first = frame.getPinsAt(0);
            if (first != null && first < 10 && (first + pins) == 10) {
                return "/";
            }
        }

        if (rollIndex == 2) {
            var firstRoll = frame.getPinsAt(0);
            var secondRoll = frame.getPinsAt(1);
            if (firstRoll == 10 && secondRoll != null && secondRoll < 10 && (secondRoll + pins) == 10) {
                return "/";
            }
        }

        if (pins == 10) {
            return "X";
        }

        return pins.toString();
    }

    private function getSavedAtText(savedGame) {
        var savedAt = savedGame[BOWLING_SAVED_GAME_SAVED_AT];
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
