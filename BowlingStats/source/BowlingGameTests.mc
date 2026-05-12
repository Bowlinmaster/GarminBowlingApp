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

(:test)
function testPotentialScoreForCurrentThrow(logger) {
    var game = new BowlingGame();
    game.recordThrow(7);
    game.recordThrow(3);

    return game.getPotentialScoreForCurrentThrow(5) == 20;
}

(:test)
function testPotentialPerfectGameScore(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 11; i++) {
        game.recordThrow(10);
    }

    return !game.isGameComplete() && game.getPotentialScoreForCurrentThrow(10) == 300;
}

(:test)
function testSavedGameRecordPacksPerfectGame(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 12; i++) {
        game.recordThrow(10);
    }

    var record = BowlingSavedGameStore.buildRecord(game, 1770000000);
    var decoded = BowlingSavedGameStore.decodeRecord(record, 0);
    var pins = decoded[BOWLING_SAVED_GAME_PIN_COUNTS];

    return record.size() == BOWLING_SAVED_GAME_RECORD_SIZE &&
           decoded[BOWLING_SAVED_GAME_SAVED_AT] == 1770000000 &&
           decoded[BOWLING_SAVED_GAME_SCORE] == 300 &&
           decoded[BOWLING_SAVED_GAME_ROLL_COUNT] == 12 &&
           pins.size() == 12 &&
           pins[0] == 10 &&
           pins[11] == 10;
}

(:test)
function testSavedGameRecordPacksMaxRollCount(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 21; i++) {
        game.recordThrow(5);
    }

    var record = BowlingSavedGameStore.buildRecord(game, 1770000100);
    var decoded = BowlingSavedGameStore.decodeRecord(record, 0);
    var pins = decoded[BOWLING_SAVED_GAME_PIN_COUNTS];

    return game.isGameComplete() &&
           game.getScore() == 150 &&
           decoded[BOWLING_SAVED_GAME_ROLL_COUNT] == 21 &&
           pins.size() == 21 &&
           pins[20] == 5;
}

(:test)
function testSavedGameStoreSavesAndReadsCompletedGame(logger) {
    BowlingSavedGameStore.clearSavedGames();

    var game = new BowlingGame();
    for (var i = 0; i < 12; i++) {
        game.recordThrow(10);
    }

    var saved = BowlingSavedGameStore.saveGameAt(game, 1770000200);
    var games = BowlingSavedGameStore.getSavedGames();
    BowlingSavedGameStore.clearSavedGames();

    return saved &&
           games.size() == 1 &&
           games[0][BOWLING_SAVED_GAME_SAVED_AT] == 1770000200 &&
           games[0][BOWLING_SAVED_GAME_SCORE] == 300;
}

(:test)
function testSavedGameStoreClearsGames(logger) {
    BowlingSavedGameStore.clearSavedGames();

    var game = new BowlingGame();
    for (var i = 0; i < 12; i++) {
        game.recordThrow(10);
    }

    BowlingSavedGameStore.saveGameAt(game, 1770000300);
    var savedCount = BowlingSavedGameStore.getSavedGameCount();
    BowlingSavedGameStore.clearSavedGames();

    return savedCount == 1 && BowlingSavedGameStore.getSavedGameCount() == 0;
}
