import Toybox.Application;
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
    var savedGame = BowlingSavedGameStore.getSavedGame(0);
    BowlingSavedGameStore.clearSavedGames();

    return saved &&
           savedGame[BOWLING_SAVED_GAME_SAVED_AT] == 1770000200 &&
           savedGame[BOWLING_SAVED_GAME_SCORE] == 300;
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

(:test)
function testSavedGameStoreRejectsIncompleteGame(logger) {
    BowlingSavedGameStore.clearSavedGames();

    var game = new BowlingGame();
    game.recordThrow(10);

    return !BowlingSavedGameStore.saveGameAt(game, 1770000400) &&
           BowlingSavedGameStore.getSavedGameCount() == 0;
}

(:test)
function testUnavailablePinEntryModeFallsBackToSimple(logger) {
    var app = $.getApp();
    app.setUsePinEntryMode(true);
    var usesPinEntry = app.usePinEntryMode;
    app.setUsePinEntryMode(false);

    return !usesPinEntry && app.getEntryModeLabel().equals("Simple");
}

(:test)
function testSavedGameStoreRejectsMalformedMetadata(logger) {
    var game = buildPerfectGameForStorageTest();
    var record = BowlingSavedGameStore.buildRecord(game, 1770000500);

    var invalidTimestamp = record.slice(0, record.size());
    invalidTimestamp[0] = -1;
    var invalidScore = record.slice(0, record.size());
    invalidScore[1] = 299;
    var invalidRollCount = record.slice(0, record.size());
    invalidRollCount[2] = 22;
    var invalidPackedPins = record.slice(0, record.size());
    invalidPackedPins[3] = -1;
    var invalidPinCount = record.slice(0, record.size());
    invalidPinCount[3] = 15;

    return BowlingSavedGameStore.decodeRecord(invalidTimestamp, 0) == null &&
           BowlingSavedGameStore.decodeRecord(invalidScore, 0) == null &&
           BowlingSavedGameStore.decodeRecord(invalidRollCount, 0) == null &&
           BowlingSavedGameStore.decodeRecord(invalidPackedPins, 0) == null &&
           BowlingSavedGameStore.decodeRecord(invalidPinCount, 0) == null;
}

(:test)
function testSavedGameStoreRejectsIllegalRollSequence(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 20; i++) {
        game.recordThrow(0);
    }

    var record = BowlingSavedGameStore.buildRecord(game, 1770000600);
    record[3] = 8 | (5 << 4);

    return BowlingSavedGameStore.decodeRecord(record, 0) == null;
}

(:test)
function testSavedGameStoreRemovesBadRecordWhenRead(logger) {
    BowlingSavedGameStore.clearSavedGames();

    var validRecord = BowlingSavedGameStore.buildRecord(buildPerfectGameForStorageTest(), 1770000700);
    var invalidRecord = validRecord.slice(0, validRecord.size());
    invalidRecord[1] = 299;
    var stored = [BOWLING_SAVED_GAMES_FORMAT_VERSION, 2];
    stored.addAll(invalidRecord);
    stored.addAll(validRecord);
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, stored);

    var countBeforeRead = BowlingSavedGameStore.getSavedGameCount();
    var savedGame = BowlingSavedGameStore.getSavedGame(0);
    var countAfterRead = BowlingSavedGameStore.getSavedGameCount();
    BowlingSavedGameStore.clearSavedGames();

    return countBeforeRead == 2 && countAfterRead == 1 &&
           savedGame[BOWLING_SAVED_GAME_SCORE] == 300;
}

(:test)
function testSavedGameStoreHandlesMalformedHeader(logger) {
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, [BOWLING_SAVED_GAMES_FORMAT_VERSION, "two"]);
    var invalidCount = BowlingSavedGameStore.getSavedGameCount();

    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, [999, 1]);
    var invalidVersionCount = BowlingSavedGameStore.getSavedGameCount();
    BowlingSavedGameStore.clearSavedGames();

    return invalidCount == 0 && invalidVersionCount == 0;
}

(:test)
function testSavedGameStoreDefersHistoricalValidationUntilRead(logger) {
    BowlingSavedGameStore.clearSavedGames();

    var validRecord = BowlingSavedGameStore.buildRecord(buildPerfectGameForStorageTest(), 1770000800);
    var invalidRecord = validRecord.slice(0, validRecord.size());
    invalidRecord[1] = 299;
    var stored = [BOWLING_SAVED_GAMES_FORMAT_VERSION, 2];
    stored.addAll(invalidRecord);
    stored.addAll(validRecord);
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, stored);

    var newGame = new BowlingGame();
    for (var i = 0; i < 20; i++) {
        newGame.recordThrow(0);
    }

    var saved = BowlingSavedGameStore.saveGameAt(newGame, 1770000900);
    var storedAfterSave = Application.Storage.getValue(BOWLING_SAVED_GAMES_STORAGE_KEY);
    var newestGame = BowlingSavedGameStore.getSavedGame(0);
    var countBeforeHistoricalRead = BowlingSavedGameStore.getSavedGameCount();
    var olderGame = BowlingSavedGameStore.getSavedGame(1);
    var countAfterHistoricalRead = BowlingSavedGameStore.getSavedGameCount();
    BowlingSavedGameStore.clearSavedGames();

    return saved && storedAfterSave[1] == 3 &&
           newestGame[BOWLING_SAVED_GAME_SCORE] == 0 &&
           countBeforeHistoricalRead == 3 &&
           olderGame[BOWLING_SAVED_GAME_SCORE] == 300 &&
           countAfterHistoricalRead == 2;
}

function buildPerfectGameForStorageTest() {
    var game = new BowlingGame();
    for (var i = 0; i < 12; i++) {
        game.recordThrow(10);
    }

    return game;
}
