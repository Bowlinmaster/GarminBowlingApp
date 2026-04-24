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

        drawHeader(dc, width);
        drawFrameCard(dc, centerX, height);
        drawPinSelector(dc, width, height);
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

    private function drawHeader(dc, width) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var title;
        if (_game.isGameComplete()) {
            title = "Game Complete";
        } else {
            title = "Frame " + _game.getCurrentFrameNumber() + "  Ball " + _game.getCurrentBallNumber();
        }

        dc.drawText(width / 2, 8, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawFrameCard(dc, centerX, height) {
        var cardWidth = 118;
        var cardHeight = 88;
        var left = centerX - (cardWidth / 2);
        var top = 34;
        var rollBoxWidth = 34;
        var rollBoxHeight = 30;
        var rollLeft = left + cardWidth - (rollBoxWidth * 2);
        var rollCenterY = top + (rollBoxHeight / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(left, top, cardWidth, cardHeight);
        dc.drawLine(rollLeft, top, rollLeft, top + rollBoxHeight);
        dc.drawLine(rollLeft + rollBoxWidth, top, rollLeft + rollBoxWidth, top + rollBoxHeight);
        dc.drawLine(rollLeft, top + rollBoxHeight, left + cardWidth, top + rollBoxHeight);

        var frame = _game.getFrame(_game.getCurrentFrameNumber() - 1);
        drawCenteredText(dc, left + 15, rollCenterY, Graphics.FONT_XTINY, _game.getCurrentFrameNumber().toString());
        drawCenteredText(dc, rollLeft + (rollBoxWidth / 2), rollCenterY, Graphics.FONT_SMALL, getRollLabel(frame, 0));
        drawCenteredText(dc, rollLeft + rollBoxWidth + (rollBoxWidth / 2), rollCenterY, Graphics.FONT_SMALL, getRollLabel(frame, 1));

        var score = _game.getCumulativeScoreThrough(_game.getCurrentFrameNumber() - 1);
        var scoreText = score == null ? "" : score.toString();
        if (_game.isGameComplete()) {
            scoreText = _game.getScore().toString();
        }

        dc.drawText(centerX, top + 48, Graphics.FONT_LARGE, scoreText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawPinSelector(dc, width, height) {
        var y = (height / 2) + 36;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y, Graphics.FONT_XTINY, "Pins Down", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_game.isGameComplete()) {
            dc.drawText(width / 2, y + 20, Graphics.FONT_SMALL, "Select to finish", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(width / 2, y + 20, Graphics.FONT_LARGE, _selectedPins.toString(), Graphics.TEXT_JUSTIFY_CENTER);
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
