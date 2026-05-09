using Toybox.Graphics;
using Toybox.WatchUi;

class SimpleEntryView extends WatchUi.View {
    var _game;
    var _onComplete;
    var _selectedPins;

    function initialize(game, onComplete) {
        WatchUi.View.initialize();
        _game = game;
        _onComplete = onComplete;
        resetSelectionToMax();
    }

    function adjustSelection(delta) {
        _selectedPins += delta;
        clampSelection();
        WatchUi.requestUpdate();
    }

    function acceptSelection() {
        if (_game.isGameComplete()) {
            if (_onComplete != null) {
                _onComplete.invoke();
            }
            return;
        }

        if (_game.recordThrow(_selectedPins)) {
            resetSelectionToMax();
            WatchUi.requestUpdate();
        }
    }

    function undoLastThrow() {
        if (_game.undoLastThrow()) {
            clampSelection();
            WatchUi.requestUpdate();
            return true;
        }

        return false;
    }

    function resetSelectionToMax() {
        _selectedPins = _game.getPinsRemaining();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var layout = BowlingEntryLayoutProfiles.forDevice(width, height);

        drawFrameCard(dc, centerX, layout);
        drawPinSelector(dc, width, height, layout);
    }

    private function clampSelection() {
        var maxPins = _game.getPinsRemaining();
        if (_selectedPins > maxPins) {
            _selectedPins = maxPins;
        }

        if (_selectedPins < 0) {
            _selectedPins = 0;
        }
    }

    private function drawFrameCard(dc, centerX, layout) {
        var cardWidth = layout.cardWidth;
        var headerHeight = layout.headerHeight;
        var bodyHeight = layout.bodyHeight;
        var left = centerX - (cardWidth / 2);
        var top = layout.top;
        var bodyTop = top + headerHeight;
        var rollBoxWidth = layout.rollBoxWidth;
        var rollBoxHeight = layout.rollBoxHeight;
        var rollCenterY = bodyTop + (rollBoxHeight / 2);
        var frameNumber = _game.getCurrentFrameNumber();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(left, top, cardWidth, headerHeight);
        dc.drawRectangle(left, bodyTop, cardWidth, bodyHeight);
        drawCenteredText(dc, centerX, top + (headerHeight / 2), layout.frameNumberFont, frameNumber.toString());

        var frame = _game.getFrame(frameNumber - 1);
        if (frameNumber == 10) {
            drawTenthFrameRolls(dc, frame, left, bodyTop, cardWidth, rollBoxWidth, rollBoxHeight, rollCenterY, layout);
        } else {
            drawStandardFrameRolls(dc, frame, left, bodyTop, cardWidth, rollBoxWidth, rollBoxHeight, rollCenterY, layout);
        }

        var score = _game.getCumulativeScoreThrough(frameNumber - 1);
        var scoreText = score == null ? "" : score.toString();
        if (_game.isGameComplete()) {
            scoreText = _game.getScore().toString();
        }

        dc.drawText(centerX, bodyTop + layout.scoreYOffset, layout.scoreFont, scoreText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawStandardFrameRolls(dc, frame, left, bodyTop, cardWidth, rollBoxWidth, rollBoxHeight, rollCenterY, layout) {
        var boxLeft = left + cardWidth - rollBoxWidth;
        dc.drawRectangle(boxLeft, bodyTop, rollBoxWidth, rollBoxHeight);

        if (frame.isStrike()) {
            drawCenteredText(dc, boxLeft + (rollBoxWidth / 2), rollCenterY, layout.rollFont, "X");
        } else {
            drawCenteredText(dc, boxLeft - layout.firstRollOffset, rollCenterY, layout.rollFont, getRollLabel(frame, 0));
            drawCenteredText(dc, boxLeft + (rollBoxWidth / 2), rollCenterY, layout.rollFont, getRollLabel(frame, 1));
        }
    }

    private function drawTenthFrameRolls(dc, frame, left, bodyTop, cardWidth, rollBoxWidth, rollBoxHeight, rollCenterY, layout) {
        var firstBoxLeft = left + cardWidth - (rollBoxWidth * 2);
        var secondBoxLeft = firstBoxLeft + rollBoxWidth;

        dc.drawRectangle(firstBoxLeft, bodyTop, rollBoxWidth, rollBoxHeight);
        dc.drawRectangle(secondBoxLeft, bodyTop, rollBoxWidth, rollBoxHeight);

        drawCenteredText(dc, firstBoxLeft - layout.firstRollOffset, rollCenterY, layout.rollFont, getRollLabel(frame, 0));
        drawCenteredText(dc, firstBoxLeft + (rollBoxWidth / 2), rollCenterY, layout.rollFont, getRollLabel(frame, 1));
        drawCenteredText(dc, secondBoxLeft + (rollBoxWidth / 2), rollCenterY, layout.rollFont, getRollLabel(frame, 2));
    }

    private function drawPinSelector(dc, width, height, layout) {
        var y = (height / 2) + layout.selectorYOffset;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y, layout.selectorLabelFont, "Pins Down", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_game.isGameComplete()) {
            dc.drawText(width / 2, y + layout.selectorValueOffset, layout.finishFont, "Select to finish", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(width / 2, y + layout.selectorValueOffset, layout.selectorValueFont, _selectedPins.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function drawCenteredText(dc, x, y, font, text) {
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function getRollLabel(frame, rollIndex) {
        var pins = frame.getPinsAt(rollIndex);
        if (pins == null) {
            return "";
        }

        if (pins == 0) {
            return "-";
        }

        if (pins == 10) {
            return "X";
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

        return pins.toString();
    }
}

class SimpleEntryDelegate extends WatchUi.BehaviorDelegate {
    var _view;
    var _game;
    var _onCompleteCallback;

    function initialize(game, onCompleteCallback) {
        WatchUi.BehaviorDelegate.initialize();
        _game = game;
        _onCompleteCallback = onCompleteCallback;
        _view = null;
    }

    function setView(view) {
        _view = view;
    }

    function onNextPage() {
        if (_view != null) {
            _view.adjustSelection(-1);
        }

        return true;
    }

    function onPreviousPage() {
        if (_view != null) {
            _view.adjustSelection(1);
        }

        return true;
    }

    function onSelect() {
        if (_view != null) {
            _view.acceptSelection();
        }

        return true;
    }

    function onBack() {
        if (_view != null && _view.undoLastThrow()) {
            return true;
        }

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
