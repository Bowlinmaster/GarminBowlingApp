import Toybox.Lang;

class BowlingThrow {
    var pins;
    var pinMask;

    function initialize(pinCount, knockedDownPinMask) {
        pins = pinCount;
        pinMask = knockedDownPinMask;
    }

    function toStorage() {
        return {
            "pins" => pins,
            "pinMask" => pinMask
        };
    }
}

class BowlingFrame {
    var rolls;
    var frameIndex;

    function initialize(index) {
        frameIndex = index;
        rolls = [];
    }

    function addThrow(ball) {
        rolls.add(ball);
    }

    function removeLastThrow() {
        if (rolls.size() == 0) {
            return null;
        }

        var removed = rolls[rolls.size() - 1];
        rolls = rolls.slice(0, -1);
        return removed;
    }

    function getRollCount() {
        return rolls.size();
    }

    function getPinsAt(index) {
        if (index < 0 || index >= rolls.size()) {
            return null;
        }

        return rolls[index].pins;
    }

    function totalPins() {
        var total = 0;
        for (var i = 0; i < rolls.size(); i++) {
            total += rolls[i].pins;
        }

        return total;
    }

    function isTenthFrame() {
        return frameIndex == 9;
    }

    function isStrike() {
        return rolls.size() > 0 && rolls[0].pins == 10;
    }

    function isSpare() {
        return rolls.size() > 1 && rolls[0].pins < 10 && (rolls[0].pins + rolls[1].pins) == 10;
    }

    function isComplete() {
        if (!isTenthFrame()) {
            return isStrike() || rolls.size() >= 2;
        }

        if (rolls.size() < 2) {
            return false;
        }

        var first = rolls[0].pins;
        var second = rolls[1].pins;
        if (first == 10 || (first + second) == 10) {
            return rolls.size() >= 3;
        }

        return true;
    }

    function toStorage() {
        var storedRolls = [];
        for (var i = 0; i < rolls.size(); i++) {
            storedRolls.add(rolls[i].toStorage());
        }

        return storedRolls;
    }
}

class BowlingGame {
    var frames;
    var currentFrame;
    var isComplete;

    function initialize() {
        frames = [];
        for (var i = 0; i < 10; i++) {
            frames.add(new BowlingFrame(i));
        }

        currentFrame = 0;
        isComplete = false;
    }

    function recordThrow(pinCount) {
        return recordThrowWithPins(pinCount, null);
    }

    function recordThrowWithPins(pinCount, knockedDownPinMask) {
        if (isComplete || !isLegalPinCount(pinCount)) {
            return false;
        }

        frames[currentFrame].addThrow(new BowlingThrow(pinCount, knockedDownPinMask));
        advanceIfNeeded();
        return true;
    }

    function undoLastThrow() {
        if (currentFrame == 0 && frames[0].getRollCount() == 0) {
            return false;
        }

        if (isComplete) {
            isComplete = false;
        } else if (frames[currentFrame].getRollCount() == 0 && currentFrame > 0) {
            currentFrame -= 1;
        }

        if (frames[currentFrame].removeLastThrow() == null && currentFrame > 0) {
            currentFrame -= 1;
            frames[currentFrame].removeLastThrow();
        }

        return true;
    }

    function getLegalPinCounts() {
        var values = [];
        var maxPins = getMaxPinsForCurrentThrow();
        if (maxPins == null) {
            return values;
        }

        for (var i = 0; i <= maxPins; i++) {
            values.add(i);
        }

        return values;
    }

    function getMaxPinsForCurrentThrow() {
        if (isComplete) {
            return null;
        }

        var frame = frames[currentFrame];
        var rollCount = frame.getRollCount();

        if (currentFrame < 9) {
            if (rollCount == 0) {
                return 10;
            }

            return 10 - frame.getPinsAt(0);
        }

        if (rollCount == 0) {
            return 10;
        }

        var first = frame.getPinsAt(0);
        if (rollCount == 1) {
            if (first == 10) {
                return 10;
            }

            return 10 - first;
        }

        var second = frame.getPinsAt(1);
        if (first == 10) {
            return second == 10 ? 10 : 10 - second;
        }

        if ((first + second) == 10) {
            return 10;
        }

        return null;
    }

    function isLegalPinCount(pinCount) {
        var maxPins = getMaxPinsForCurrentThrow();
        return maxPins != null && pinCount >= 0 && pinCount <= maxPins;
    }

    function getPinsRemaining() {
        var maxPins = getMaxPinsForCurrentThrow();
        return maxPins == null ? 0 : maxPins;
    }

    function getCurrentFrameNumber() {
        return currentFrame + 1;
    }

    function getCurrentBallNumber() {
        if (isComplete) {
            return 0;
        }

        return frames[currentFrame].getRollCount() + 1;
    }

    function getFrame(index) {
        return frames[index];
    }

    function getScore() {
        var score = 0;
        for (var i = 0; i < 10; i++) {
            var frameScore = getFrameScore(i);
            if (frameScore == null) {
                return score;
            }

            score += frameScore;
        }

        return score;
    }

    function getFrameScore(index) {
        var frame = frames[index];
        if (!frame.isComplete()) {
            return null;
        }

        if (index == 9) {
            return frame.totalPins();
        }

        if (frame.isStrike()) {
            var strikeBonus = getNextRolls(index, 2);
            if (strikeBonus.size() < 2) {
                return null;
            }

            return 10 + strikeBonus[0] + strikeBonus[1];
        }

        if (frame.isSpare()) {
            var spareBonus = getNextRolls(index, 1);
            if (spareBonus.size() < 1) {
                return null;
            }

            return 10 + spareBonus[0];
        }

        return frame.totalPins();
    }

    function getCumulativeScoreThrough(index) {
        var score = 0;
        for (var i = 0; i <= index; i++) {
            var frameScore = getFrameScore(i);
            if (frameScore == null) {
                return null;
            }

            score += frameScore;
        }

        return score;
    }

    function isGameComplete() {
        return isComplete;
    }

    function toStorage() {
        var storedFrames = [];
        for (var i = 0; i < frames.size(); i++) {
            storedFrames.add(frames[i].toStorage());
        }

        return {
            "score" => getScore(),
            "frames" => storedFrames
        };
    }

    private function advanceIfNeeded() {
        if (!frames[currentFrame].isComplete()) {
            return;
        }

        if (currentFrame >= 9) {
            isComplete = true;
            return;
        }

        currentFrame += 1;
    }

    private function getNextRolls(frameIndex, count) {
        var nextRolls = [];
        var index = frameIndex + 1;

        while (index < 10 && nextRolls.size() < count) {
            var frame = frames[index];
            for (var roll = 0; roll < frame.getRollCount() && nextRolls.size() < count; roll++) {
                nextRolls.add(frame.getPinsAt(roll));
            }

            index += 1;
        }

        return nextRolls;
    }
}

class Game extends BowlingGame {
    function initialize() {
        BowlingGame.initialize();
    }
}
