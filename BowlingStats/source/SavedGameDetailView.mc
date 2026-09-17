import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SavedGameDetailView extends WatchUi.View {
    var _gameCount as Number;
    var _selectedIndex as Number;
    var _selectedGame as Lang.Dictionary or Null;

    function initialize(selectedIndex) {
        WatchUi.View.initialize();
        _gameCount = BowlingSavedGameStore.getSavedGameCount();
        _selectedIndex = selectedIndex;
        loadSelectedGame();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        if (_selectedGame == null) {
            drawEmptyState(dc, centerX, height / 2);
            return;
        }

        var savedGame = _selectedGame as Lang.Dictionary;
        var game = savedGame[BOWLING_SAVED_GAME_MODEL] as BowlingGame;

        var scorecardTop = drawHeader(dc, savedGame, centerX, width, height);
        drawScorecard(dc, game, width, height, scorecardTop);
        drawPosition(dc, centerX, height);
    }

    private function drawEmptyState(dc, centerX, centerY) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, centerX, centerY - 12, Graphics.FONT_SMALL, bowlingString(Rez.Strings.NoSavedGames));

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, centerX, centerY + 14, Graphics.FONT_XTINY, bowlingString(Rez.Strings.FinishGameFirst));
    }

    private function drawHeader(dc, savedGame as Lang.Dictionary, centerX, width, height) {
        var dateText = getSavedAtText(savedGame);
        var safeInset = BowlingScreenGeometry.getSafeInset(width, height);
        var dateY = BowlingScreenGeometry.fitTopCenteredTextY(
            dc,
            width,
            height,
            Graphics.FONT_XTINY,
            dateText,
            height < 260 ? 18 : 24,
            safeInset
        );

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, centerX, dateY, Graphics.FONT_XTINY, dateText);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var score = savedGame[BOWLING_SAVED_GAME_SCORE];
        var scoreText = Lang.format(bowlingString(Rez.Strings.ScoreFormat), [score]);
        var scoreY = dateY + (dc.getFontHeight(Graphics.FONT_XTINY) / 2) +
            (dc.getFontHeight(Graphics.FONT_MEDIUM) / 2) + 2;
        drawCenteredText(dc, centerX, scoreY, Graphics.FONT_MEDIUM, scoreText);

        return scoreY + (dc.getFontHeight(Graphics.FONT_MEDIUM) / 2) + 8;
    }

    private function drawScorecard(dc, game, width, height, top) {
        var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY) + 2;
        var rowHeight = lineHeight * 3;
        var rowGap = 4;
        var gridBottom = top + (rowHeight * 2) + rowGap;
        var safeInset = BowlingScreenGeometry.getSafeInset(width, height);
        var totalWidth = BowlingScreenGeometry.getSafeWidthForBand(width, height, top, gridBottom, safeInset);
        var maximumWidth = width - 28;
        if (totalWidth <= 0 || totalWidth > maximumWidth) {
            totalWidth = maximumWidth;
        }
        if (totalWidth > 360) {
            totalWidth = 360;
        }

        var cellWidth = totalWidth / 5;
        var left = (width - (cellWidth * 5)) / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var frameIndex = 0; frameIndex < 10; frameIndex++) {
            var column = frameIndex % 5;
            var row = frameIndex / 5;
            var x = left + (column * cellWidth);
            var y = top + (row * (rowHeight + rowGap));
            drawMiniFrame(dc, game, frameIndex, x, y, cellWidth, rowHeight);
        }
    }

    private function drawMiniFrame(dc, game, frameIndex, x, y, width, height) {
        var headerHeight = height / 3;
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
        if (_gameCount <= 1) {
            return;
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var positionText = (_selectedIndex + 1).toString() + "/" + _gameCount.toString();
        var preferredY = height - (height < 260 ? 20 : 28);
        var y = BowlingScreenGeometry.fitBottomCenteredTextY(
            dc,
            dc.getWidth(),
            height,
            Graphics.FONT_XTINY,
            positionText,
            preferredY,
            BowlingScreenGeometry.getSafeInset(dc.getWidth(), height)
        );
        drawCenteredText(dc, centerX, y, Graphics.FONT_XTINY, positionText);
    }

    private function loadSelectedGame() {
        _selectedGame = BowlingSavedGameStore.getSavedGame(_selectedIndex);
        _gameCount = BowlingSavedGameStore.getSavedGameCount();

        if (_gameCount == 0) {
            _selectedIndex = 0;
            _selectedGame = null;
        } else if (_selectedIndex >= _gameCount) {
            _selectedIndex = _gameCount - 1;
            _selectedGame = BowlingSavedGameStore.getSavedGame(_selectedIndex);
        }
    }

    private function getFrameRollText(frame, frameIndex) {
        if (frameIndex < 9 && frame.isStrike()) {
            return "X";
        }

        var labels = [] as Array<String>;
        var maxRolls = frameIndex == 9 ? 3 : 2;
        for (var rollIndex = 0; rollIndex < maxRolls; rollIndex++) {
            var label = getRollLabel(frame, rollIndex);
            if (!label.equals("")) {
                labels.add(label);
            }
        }

        return joinLabels(labels);
    }

    private function joinLabels(labels as Array<String>) as String {
        var text = "";
        for (var i = 0; i < labels.size(); i++) {
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

    private function getSavedAtText(savedGame as Lang.Dictionary) {
        var savedAt = savedGame[BOWLING_SAVED_GAME_SAVED_AT] as Number;
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
