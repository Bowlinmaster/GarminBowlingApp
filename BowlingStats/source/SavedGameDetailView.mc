import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SavedGameDetailView extends WatchUi.View {
    var _gameCount as Number;
    var _selectedIndex as Number;
    var _selectedGame as Lang.Dictionary or Null;
    var _page as Number;

    function initialize(selectedIndex) {
        WatchUi.View.initialize();
        _gameCount = BowlingSavedGameStore.getSavedGameCount();
        _selectedIndex = selectedIndex;
        _page = 0;
        loadSelectedGame();
    }

    function nextPage() as Void {
        _page = (_page + 1) % 5;
        WatchUi.requestUpdate();
    }

    function previousPage() as Void {
        _page = (_page + 4) % 5;
        WatchUi.requestUpdate();
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

        if (_page > 0) {
            BowlingStatisticsRenderer.draw(
                dc,
                BowlingStatistics.forGame(game),
                false,
                _page - 1,
                _page + 1,
                5,
                bowlingString(Rez.Strings.GameStatistics)
            );
            return;
        }

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
        // Built-in font sizes vary sharply between MIP and AMOLED devices. Keep the
        // miniature scorecard proportional to the screen instead of the system font.
        var rowHeight = width <= 280 ? height / 5 : height * 18 / 100;
        var rowGap = width <= 280 ? 4 : 6;
        var gridBottom = top + (rowHeight * 2) + rowGap;
        var safeInset = BowlingScreenGeometry.getSafeInset(width, height);
        var totalWidth = BowlingScreenGeometry.getSafeWidthForBand(width, height, top, gridBottom, safeInset);
        var maximumWidth;
        if (width != height) {
            maximumWidth = width - 20;
        } else if (width <= 240) {
            maximumWidth = width * 72 / 100;
        } else if (width <= 280) {
            maximumWidth = width * 74 / 100;
        } else {
            maximumWidth = width * 76 / 100;
        }
        if (totalWidth <= 0 || totalWidth > maximumWidth) {
            totalWidth = maximumWidth;
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
        var right = x + width - 1;

        dc.drawRectangle(x, y, width, height);
        dc.drawLine(x, y + headerHeight, right, y + headerHeight);
        dc.drawLine(x, scoreTop, right, scoreTop);

        drawScorecardText(dc, x, y, width, headerHeight, (frameIndex + 1).toString());

        var frame = game.getFrame(frameIndex);
        drawScorecardText(dc, x, y + headerHeight, width, rollHeight, getFrameRollText(frame, frameIndex));

        var score = game.getCumulativeScoreThrough(frameIndex);
        var scoreText = score == null ? "" : score.toString();
        drawScorecardText(dc, x, scoreTop, width, height - headerHeight - rollHeight, scoreText);
    }

    private function drawScorecardText(dc, x, y, width, height, text) {
        if (text.equals("")) {
            return;
        }

        var characterCount = text.length();
        var gap = 1;
        var glyphHeight = height - 4;
        var glyphWidth = glyphHeight * 3 / 5;
        var availableWidth = width - 4;
        var textWidth = (glyphWidth * characterCount) + (gap * (characterCount - 1));

        if (textWidth > availableWidth) {
            glyphWidth = (availableWidth - (gap * (characterCount - 1))) / characterCount;
            glyphHeight = glyphWidth * 5 / 3;
            textWidth = (glyphWidth * characterCount) + (gap * (characterCount - 1));
        }

        if (glyphWidth < 3) {
            glyphWidth = 3;
        }
        if (glyphHeight < 5) {
            glyphHeight = 5;
        }

        var characterX = x + ((width - textWidth) / 2);
        var characterY = y + ((height - glyphHeight) / 2);
        dc.setPenWidth(1);
        for (var i = 0; i < characterCount; i++) {
            drawScorecardCharacter(dc, characterX, characterY, glyphWidth, glyphHeight, text.substring(i, i + 1));
            characterX += glyphWidth + gap;
        }
        dc.setPenWidth(1);
    }

    private function drawScorecardCharacter(dc, x, y, width, height, character) {
        var right = x + width - 1;
        var middle = y + (height / 2);
        var bottom = y + height - 1;

        if (character.equals("X")) {
            dc.drawLine(x, y, right, bottom);
            dc.drawLine(right, y, x, bottom);
            return;
        }
        if (character.equals("/")) {
            dc.drawLine(right, y, x, bottom);
            return;
        }
        if (character.equals("-")) {
            dc.drawLine(x, middle, right, middle);
            return;
        }

        var mask = getDigitSegments(character.toNumber());
        if ((mask & 1) != 0) { dc.drawLine(x, y, right, y); }
        if ((mask & 2) != 0) { dc.drawLine(right, y, right, middle); }
        if ((mask & 4) != 0) { dc.drawLine(right, middle, right, bottom); }
        if ((mask & 8) != 0) { dc.drawLine(x, bottom, right, bottom); }
        if ((mask & 16) != 0) { dc.drawLine(x, middle, x, bottom); }
        if ((mask & 32) != 0) { dc.drawLine(x, y, x, middle); }
        if ((mask & 64) != 0) { dc.drawLine(x, middle, right, middle); }
    }

    private function getDigitSegments(digit) {
        switch (digit) {
            case 0: return 63;
            case 1: return 6;
            case 2: return 91;
            case 3: return 79;
            case 4: return 102;
            case 5: return 109;
            case 6: return 125;
            case 7: return 7;
            case 8: return 127;
            case 9: return 111;
        }

        return 0;
    }

    private function drawPosition(dc, centerX, height) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var positionText = "1/5";
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
