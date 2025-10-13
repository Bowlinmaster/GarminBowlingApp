class Game {
    var frames;
    var currentFrame;
    var isComplete; //true if the game is complete

    function initialize() {
        frames = [];
        for (var i = 0; i < 10; i++) {
            frames.add(new Frame());
        }
        currentFrame = 0;
        isComplete = false;
    }

    //TODO: refactor and generalize so that I can record specific pins too.
    function recordThrow(pinsKnockedDown) {
        var frame = frames[currentFrame];
        frame.addThrow(pinsKnockedDown);

        //Advance to the next frame if needed;
        if (frame.isComplete()) {
            currentFrame += 1;
            if(currentFrame >= 10) {
                isComplete = true;
            }
        }
    }

    function getPinsRemaining() {
        if (isComplete) {
            return 0;
        }

        var frame = frames[currentFrame];
        return 10 - frame.totalPins();
    }

    function getScore() {
        var total = 0;
        for (var i = 0; i < frames.size(); i++) {
            total += frames[i].totalPins();
        }

        return total;
    }

    function isGameComplete() {
        return isComplete;
    }
}

class Frame {
    var throws; //Array of ints (pins knocked down)

    function initialize() {
        throws = [];
    }

    function addThrow(pins) {
        if(!isComplete()) {
            throws.add(pins);
        }
    }

    function totalPins() {
        var total = 0;
        for (var i = 0; i < throws.size(); i++) {
            total += throws[i];
        }
        return total;
    }

    function isStrike() {
        return throws.size() > 0 && throws[0] == 10;
    }

    function isComplete() {
        if(isStrike()) {
            return true;
        }

        return throws.size() == 2;
    }
}