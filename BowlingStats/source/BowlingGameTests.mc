import Toybox.Test;

(:test)
function testGutterGame(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 20; i++) {
        game.recordThrow(0);
    }

    return game.isGameComplete() && game.getScore() == 0;
}

(:test)
function testAllOnes(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 20; i++) {
        game.recordThrow(1);
    }

    return game.isGameComplete() && game.getScore() == 20;
}

(:test)
function testSpareBonus(logger) {
    var game = new BowlingGame();
    game.recordThrow(7);
    game.recordThrow(3);
    game.recordThrow(4);
    game.recordThrow(2);

    return game.getFrameScore(0) == 14 && game.getScore() == 20;
}

(:test)
function testStrikeBonus(logger) {
    var game = new BowlingGame();
    game.recordThrow(10);
    game.recordThrow(3);
    game.recordThrow(4);

    return game.getFrameScore(0) == 17 && game.getScore() == 24;
}

(:test)
function testPerfectGame(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 12; i++) {
        game.recordThrow(10);
    }

    return game.isGameComplete() && game.getScore() == 300;
}

(:test)
function testTenthFrameSpare(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 18; i++) {
        game.recordThrow(0);
    }

    game.recordThrow(7);
    game.recordThrow(3);
    game.recordThrow(5);

    return game.isGameComplete() && game.getFrameScore(9) == 15 && game.getScore() == 15;
}

(:test)
function testUndoAfterStrike(logger) {
    var game = new BowlingGame();
    game.recordThrow(10);
    game.recordThrow(4);

    var beforeUndoFrame = game.getCurrentFrameNumber();
    game.undoLastThrow();
    var afterUndoFrame = game.getCurrentFrameNumber();

    return beforeUndoFrame == 2 && afterUndoFrame == 2 && game.getCurrentBallNumber() == 1;
}

(:test)
function testLegalPinsForSecondThrow(logger) {
    var game = new BowlingGame();
    game.recordThrow(6);

    return game.getPinsRemaining() == 4 && !game.recordThrow(5) && game.recordThrow(4);
}
