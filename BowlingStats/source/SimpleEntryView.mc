using Toybox.Graphics;
import Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

class SimpleEntryView extends WatchUi.View {
    var _game;
    var _onComplete;
    var _onDiscard;
    var _selectedPins;
    var _saveFailed;
    var _discardRequested;
    var _discardTouchBounds as Array<Number> or Null;

    function initialize(game, onComplete, onDiscard) {
        WatchUi.View.initialize();
        _game = game;
        _onComplete = onComplete;
        _onDiscard = onDiscard;
        _saveFailed = false;
        _discardRequested = false;
        _discardTouchBounds = null;
        resetSelectionToMax();
    }

    function onShow() {
        if (_discardRequested && _onDiscard != null) {
            _discardRequested = false;
            _onDiscard.invoke();
        }
    }

    function adjustSelection(delta) {
        _selectedPins += delta;
        clampSelection();
        WatchUi.requestUpdate();
    }

    function acceptSelection() {
        if (_game.isGameComplete()) {
            if (_onComplete != null) {
                _saveFailed = _onComplete.invoke() == false;
                if (_saveFailed) {
                    WatchUi.requestUpdate();
                }
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
            _saveFailed = false;
            clampSelection();
            WatchUi.requestUpdate();
            return true;
        }

        return false;
    }

    function hasSaveFailed() {
        return _saveFailed;
    }

    function requestDiscard() {
        _discardRequested = true;
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
        drawConfirmHint(dc, width, height, layout);
        drawDiscardHint(dc, width, height, layout);
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
        var pendingRollIndex = getPendingRollIndex(frame);
        if (frameNumber == 10) {
            drawTenthFrameRolls(dc, frame, pendingRollIndex, left, bodyTop, cardWidth, rollBoxWidth, rollBoxHeight, rollCenterY, layout);
        } else {
            drawStandardFrameRolls(dc, frame, pendingRollIndex, left, bodyTop, cardWidth, rollBoxWidth, rollBoxHeight, rollCenterY, layout);
        }

        var score = _game.getPotentialScoreForCurrentThrow(_selectedPins);
        if (_game.isGameComplete()) {
            score = _game.getScore();
        }

        var scoreText = score == null ? "" : score.toString();
        dc.drawText(centerX, bodyTop + layout.scoreYOffset, layout.scoreFont, scoreText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawStandardFrameRolls(dc, frame, pendingRollIndex, left, bodyTop, cardWidth, rollBoxWidth, rollBoxHeight, rollCenterY, layout) {
        var boxLeft = left + cardWidth - rollBoxWidth;
        dc.drawRectangle(boxLeft, bodyTop, rollBoxWidth, rollBoxHeight);

        if (getRollPins(frame, 0, pendingRollIndex) == 10) {
            drawCenteredText(dc, boxLeft + (rollBoxWidth / 2), rollCenterY, layout.rollFont, "X");
        } else {
            drawCenteredText(dc, boxLeft - layout.firstRollOffset, rollCenterY, layout.rollFont, getRollLabel(frame, 0, pendingRollIndex));
            drawCenteredText(dc, boxLeft + (rollBoxWidth / 2), rollCenterY, layout.rollFont, getRollLabel(frame, 1, pendingRollIndex));
        }
    }

    private function drawTenthFrameRolls(dc, frame, pendingRollIndex, left, bodyTop, cardWidth, rollBoxWidth, rollBoxHeight, rollCenterY, layout) {
        var firstBoxLeft = left + cardWidth - (rollBoxWidth * 2);
        var secondBoxLeft = firstBoxLeft + rollBoxWidth;

        dc.drawRectangle(firstBoxLeft, bodyTop, rollBoxWidth, rollBoxHeight);
        dc.drawRectangle(secondBoxLeft, bodyTop, rollBoxWidth, rollBoxHeight);

        drawCenteredText(dc, firstBoxLeft - layout.firstRollOffset, rollCenterY, layout.rollFont, getRollLabel(frame, 0, pendingRollIndex));
        drawCenteredText(dc, firstBoxLeft + (rollBoxWidth / 2), rollCenterY, layout.rollFont, getRollLabel(frame, 1, pendingRollIndex));
        drawCenteredText(dc, secondBoxLeft + (rollBoxWidth / 2), rollCenterY, layout.rollFont, getRollLabel(frame, 2, pendingRollIndex));
    }

    private function drawPinSelector(dc, width, height, layout) {
        var y = (height / 2) + layout.selectorYOffset;
        var label = bowlingString(Rez.Strings.PinsDown);
        if (_saveFailed) {
            label = bowlingString(Rez.Strings.SaveFailed);
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(width / 2, y, layout.selectorLabelFont, label, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_game.isGameComplete()) {
            var promptY = y + layout.selectorValueOffset;
            var prompt = _saveFailed ? bowlingString(Rez.Strings.RetrySave) : bowlingString(Rez.Strings.FinishGame);
            dc.drawText(width / 2, promptY, layout.finishFont, prompt, Graphics.TEXT_JUSTIFY_CENTER);

            if (_saveFailed) {
                var discardY = promptY + dc.getFontHeight(layout.finishFont);
                dc.drawText(width / 2, discardY, layout.selectorLabelFont, bowlingString(Rez.Strings.DiscardSave), Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else {
            dc.drawText(width / 2, y + layout.selectorValueOffset, layout.selectorValueFont, _selectedPins.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function drawConfirmHint(dc, width, height, layout) {
        if (_game.isGameComplete()) {
            return;
        }

        var x = width - layout.confirmIconRightInset;
        var y = (height / 2) - layout.confirmIconYOffset;
        var size = layout.confirmIconSize;
        var stemX = x - (size / 6);
        var stemY = y + (size / 3);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(layout.confirmIconPenWidth);
        dc.drawLine(x - (size / 2), y, stemX, stemY);
        dc.drawLine(stemX, stemY, x + (size / 2), y - (size / 2));
        dc.setPenWidth(1);
    }

    private function drawDiscardHint(dc, width, height, layout) {
        _discardTouchBounds = null;
        if (_saveFailed || !System.getDeviceSettings().isTouchScreen) {
            return;
        }

        var x = width / 2;
        var y = height - layout.discardIconBottomInset;
        var size = layout.confirmIconSize;
        var halfSize = size / 2;
        var hitRadius = size;

        // Keep discard centered so it reads as a touch action, not a button hint.
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(layout.confirmIconPenWidth);
        dc.drawLine(x - halfSize, y - halfSize, x + halfSize, y + halfSize);
        dc.drawLine(x + halfSize, y - halfSize, x - halfSize, y + halfSize);
        dc.setPenWidth(1);

        _discardTouchBounds = [x - hitRadius, y - hitRadius, x + hitRadius, y + hitRadius];
    }

    function isDiscardTap(coordinates as Array<Number>) as Boolean {
        if (_discardTouchBounds == null) {
            return false;
        }

        var bounds = _discardTouchBounds as Array<Number>;
        return coordinates[0] >= bounds[0]
            && coordinates[0] <= bounds[2]
            && coordinates[1] >= bounds[1]
            && coordinates[1] <= bounds[3];
    }

    private function drawCenteredText(dc, x, y, font, text) {
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function getPendingRollIndex(frame) {
        if (_game.isGameComplete()) {
            return null;
        }

        return frame.getRollCount();
    }

    private function getRollPins(frame, rollIndex, pendingRollIndex) {
        var pins = frame.getPinsAt(rollIndex);
        if (pins != null) {
            return pins;
        }

        if (pendingRollIndex != null && rollIndex == pendingRollIndex) {
            return _selectedPins;
        }

        return null;
    }

    private function getRollLabel(frame, rollIndex, pendingRollIndex) {
        var pins = getRollPins(frame, rollIndex, pendingRollIndex);
        if (pins == null) {
            return "";
        }

        if (pins == 0) {
            return "-";
        }

        if (rollIndex == 1) {
            var first = getRollPins(frame, 0, pendingRollIndex);
            if (first != null && first < 10 && (first + pins) == 10) {
                return "/";
            }
        }

        if (rollIndex == 2) {
            var firstRoll = getRollPins(frame, 0, pendingRollIndex);
            var secondRoll = getRollPins(frame, 1, pendingRollIndex);
            if (firstRoll == 10 && secondRoll != null && secondRoll < 10 && (secondRoll + pins) == 10) {
                return "/";
            }
        }

        if (pins == 10) {
            return "X";
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

    function onKey(event) {
        var key = event.getKey();
        if (key != WatchUi.KEY_ENTER && key != WatchUi.KEY_START) {
            return false;
        }

        acceptSelection();
        return true;
    }

    function onTap(event) {
        if (_view != null && _view.isDiscardTap(event.getCoordinates())) {
            showDiscardConfirmation();
        } else {
            acceptSelection();
        }

        return true;
    }

    function onMenu() {
        showDiscardConfirmation();
        return true;
    }

    function onBack() {
        if (_view != null && _view.hasSaveFailed()) {
            showDiscardConfirmation();
            return true;
        }

        if (_view != null && _view.undoLastThrow()) {
            return true;
        }

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    private function acceptSelection() {
        if (_view != null) {
            _view.acceptSelection();
        }
    }

    private function showDiscardConfirmation() {
        if (_view == null) {
            return;
        }

        var message = _view.hasSaveFailed()
            ? bowlingString(Rez.Strings.DiscardUnsavedGameConfirmation)
            : bowlingString(Rez.Strings.DiscardCurrentGameConfirmation);
        var confirmation = new WatchUi.Confirmation(message);
        WatchUi.pushView(confirmation, new BowlingDiscardGameConfirmationDelegate(_view), WatchUi.SLIDE_IMMEDIATE);
    }
}
