import Toybox.Application;
import Toybox.Lang;
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
function testRejectsPinsOutsideLegalRange(logger) {
    var game = new BowlingGame();

    return !game.recordThrow(-1) &&
           !game.recordThrow(11) &&
           game.getRecordedRollCount() == 0 &&
           game.getCurrentFrameNumber() == 1;
}

(:test)
function testTenthFrameStrikeResetsPinsAfterSecondStrike(logger) {
    var game = buildGameThroughNineFramesForTest();
    game.recordThrow(10);
    var maxAfterFirstStrike = game.getMaxPinsForCurrentThrow();
    game.recordThrow(10);
    var maxAfterSecondStrike = game.getMaxPinsForCurrentThrow();

    return maxAfterFirstStrike == 10 &&
           maxAfterSecondStrike == 10 &&
           game.recordThrow(7) &&
           game.isGameComplete() &&
           game.getScore() == 27;
}

(:test)
function testTenthFramePinsDoNotResetAfterNonStrikeBonus(logger) {
    var game = buildGameThroughNineFramesForTest();
    game.recordThrow(10);
    game.recordThrow(7);

    return game.getMaxPinsForCurrentThrow() == 3 &&
           !game.recordThrow(4) &&
           game.recordThrow(3) &&
           game.isGameComplete() &&
           game.getScore() == 20;
}

(:test)
function testOpenTenthCompletesWithoutBonusRoll(logger) {
    var game = buildGameThroughNineFramesForTest();
    game.recordThrow(4);
    game.recordThrow(5);

    return game.isGameComplete() &&
           game.getRecordedRollCount() == 20 &&
           !game.recordThrow(1) &&
           game.getScore() == 9;
}

(:test)
function testUndoCompletedGameRestoresFinalRoll(logger) {
    var game = buildGameThroughNineFramesForTest();
    game.recordThrow(4);
    game.recordThrow(5);

    return game.undoLastThrow() &&
           !game.isGameComplete() &&
           game.getCurrentFrameNumber() == 10 &&
           game.getCurrentBallNumber() == 2 &&
           game.getPinsRemaining() == 6;
}

(:test)
function testSavedGameRecordPacksPerfectGame(logger) {
    var game = new BowlingGame();
    for (var i = 0; i < 12; i++) {
        game.recordThrow(10);
    }

    var record = BowlingSavedGameStore.buildRecord(game, 1770000000);
    var decoded = BowlingSavedGameStore.decodeRecord(record, 0) as Lang.Dictionary;
    var pins = decoded[BOWLING_SAVED_GAME_PIN_COUNTS] as Array<Number>;

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
    var decoded = BowlingSavedGameStore.decodeRecord(record, 0) as Lang.Dictionary;
    var pins = decoded[BOWLING_SAVED_GAME_PIN_COUNTS] as Array<Number>;

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
    var savedGame = BowlingSavedGameStore.getSavedGame(0) as Lang.Dictionary;
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
function testSavedGameStoreRejectsInvalidIndexes(logger) {
    BowlingSavedGameStore.clearSavedGames();

    return BowlingSavedGameStore.getSavedGame(-1) == null &&
           BowlingSavedGameStore.getSavedGame(0) == null &&
           BowlingSavedGameStore.getSavedGameSummary(-1) == null &&
           BowlingSavedGameStore.getSavedGameSummary(0) == null;
}

(:test)
function testSavedGameStoreEvictsOldestAtCapacity(logger) {
    BowlingSavedGameStore.clearSavedGames();

    var perfectGame = buildPerfectGameForStorageTest();
    var oldRecord = BowlingSavedGameStore.buildRecord(perfectGame, 1770000450);
    var stored = buildPerfectGameStoreForTest(BOWLING_SAVED_GAMES_MAX_COUNT);
    for (var i = 0; i < BOWLING_SAVED_GAMES_MAX_COUNT; i++) {
        stored.addAll(oldRecord);
    }
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, stored);

    var gutterGame = buildGameThroughNineFramesForTest();
    gutterGame.recordThrow(0);
    gutterGame.recordThrow(0);
    var saved = BowlingSavedGameStore.saveGameAt(gutterGame, 1770000460);
    var newest = BowlingSavedGameStore.getSavedGameSummary(0) as Lang.Dictionary?;
    var oldest = BowlingSavedGameStore.getSavedGameSummary(BOWLING_SAVED_GAMES_MAX_COUNT - 1) as Lang.Dictionary?;
    var count = BowlingSavedGameStore.getSavedGameCount();
    var aggregate = BowlingSavedGameStore.getAggregateStatistics();
    BowlingSavedGameStore.clearSavedGames();

    return saved && count == BOWLING_SAVED_GAMES_MAX_COUNT &&
           newest != null && newest[BOWLING_SAVED_GAME_SAVED_AT] == 1770000460 &&
           oldest != null && oldest[BOWLING_SAVED_GAME_SAVED_AT] == 1770000450 &&
           aggregate[BOWLING_STAT_GAME_COUNT] == BOWLING_SAVED_GAMES_MAX_COUNT + 1;
}

(:test)
function testUnavailablePinEntryModeFallsBackToSimple(logger) {
    var app = $.getApp();
    app.setUsePinEntryMode(true);
    var usesPinEntry = app.usePinEntryMode;
    app.setUsePinEntryMode(false);

    return !usesPinEntry && app.getEntryModeLabel().equals(bowlingString(Rez.Strings.EntryModeSimple));
}

(:test)
function testSavedGameStoreRejectsMalformedMetadata(logger) {
    var game = buildPerfectGameForStorageTest();
    var record = BowlingSavedGameStore.buildRecord(game, 1770000500);

    var invalidTimestamp = record.slice(0, record.size()) as Lang.Array;
    invalidTimestamp[0] = -1;
    var invalidScore = record.slice(0, record.size()) as Lang.Array;
    invalidScore[1] = 299;
    var invalidRollCount = record.slice(0, record.size()) as Lang.Array;
    invalidRollCount[2] = 22;
    var invalidPackedPins = record.slice(0, record.size()) as Lang.Array;
    invalidPackedPins[3] = -1;
    var invalidPinCount = record.slice(0, record.size()) as Lang.Array;
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
    var invalidRecord = validRecord.slice(0, validRecord.size()) as Lang.Array;
    invalidRecord[1] = 299;
    var stored = buildPerfectGameStoreForTest(2);
    stored.addAll(invalidRecord);
    stored.addAll(validRecord);
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, stored);

    var countBeforeRead = BowlingSavedGameStore.getSavedGameCount();
    var savedGame = BowlingSavedGameStore.getSavedGame(0) as Lang.Dictionary;
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
    var invalidRecord = validRecord.slice(0, validRecord.size()) as Lang.Array;
    invalidRecord[1] = 299;
    var stored = buildPerfectGameStoreForTest(2);
    stored.addAll(invalidRecord);
    stored.addAll(validRecord);
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, stored);

    var newGame = new BowlingGame();
    for (var i = 0; i < 20; i++) {
        newGame.recordThrow(0);
    }

    var saved = BowlingSavedGameStore.saveGameAt(newGame, 1770000900);
    var storedAfterSave = Application.Storage.getValue(BOWLING_SAVED_GAMES_STORAGE_KEY) as Lang.Array;
    var newestGame = BowlingSavedGameStore.getSavedGame(0) as Lang.Dictionary;
    var countBeforeHistoricalRead = BowlingSavedGameStore.getSavedGameCount();
    var olderGame = BowlingSavedGameStore.getSavedGame(1) as Lang.Dictionary;
    var countAfterHistoricalRead = BowlingSavedGameStore.getSavedGameCount();
    BowlingSavedGameStore.clearSavedGames();

    return saved && storedAfterSave[1] == 3 &&
           newestGame[BOWLING_SAVED_GAME_SCORE] == 0 &&
           countBeforeHistoricalRead == 3 &&
           olderGame[BOWLING_SAVED_GAME_SCORE] == 300 &&
           countAfterHistoricalRead == 2;
}

(:test)
function testSavedGameSummaryReadsMetadataWithoutBuildingGame(logger) {
    BowlingSavedGameStore.clearSavedGames();

    var game = buildPerfectGameForStorageTest();
    BowlingSavedGameStore.saveGameAt(game, 1770001000);
    var summary = BowlingSavedGameStore.getSavedGameSummary(0) as Lang.Dictionary?;
    BowlingSavedGameStore.clearSavedGames();

    return summary != null &&
           summary[BOWLING_SAVED_GAME_SAVED_AT] == 1770001000 &&
           summary[BOWLING_SAVED_GAME_SCORE] == 300 &&
           !summary.hasKey(BOWLING_SAVED_GAME_MODEL) &&
           !summary.hasKey(BOWLING_SAVED_GAME_PIN_COUNTS);
}

(:test)
function testSavedGameSummaryRemovesMalformedRecord(logger) {
    BowlingSavedGameStore.clearSavedGames();

    var validRecord = BowlingSavedGameStore.buildRecord(buildPerfectGameForStorageTest(), 1770001100);
    var invalidRecord = validRecord.slice(0, validRecord.size()) as Lang.Array;
    invalidRecord[0] = 0;
    var stored = buildPerfectGameStoreForTest(2);
    stored.addAll(invalidRecord);
    stored.addAll(validRecord);
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, stored);

    var summary = BowlingSavedGameStore.getSavedGameSummary(0) as Lang.Dictionary?;
    var remainingCount = BowlingSavedGameStore.getSavedGameCount();
    BowlingSavedGameStore.clearSavedGames();

    return summary != null &&
           summary[BOWLING_SAVED_GAME_SAVED_AT] == 1770001100 &&
           summary[BOWLING_SAVED_GAME_SCORE] == 300 &&
           remainingCount == 1;
}

(:test)
function testPerGameStatisticsUseFirstBallFrameOpportunities(logger) {
    var game = new BowlingGame();
    game.recordThrow(10);
    game.recordThrow(7);
    game.recordThrow(3);
    game.recordThrow(7);
    game.recordThrow(2);
    for (var frame = 3; frame < 9; frame++) {
        game.recordThrow(0);
        game.recordThrow(0);
    }
    game.recordThrow(5);
    game.recordThrow(5);
    game.recordThrow(5);

    var statistics = BowlingStatistics.forGame(game);
    return game.isGameComplete() &&
           statistics[BOWLING_STAT_FIRST_BALL_PINS] == 29 &&
           statistics[BOWLING_STAT_FIRST_BALL_ATTEMPTS] == 10 &&
           statistics[BOWLING_STAT_STRIKES] == 1 &&
           statistics[BOWLING_STAT_SPARE_ATTEMPTS] == 9 &&
           statistics[BOWLING_STAT_SPARES] == 2 &&
           statistics[BOWLING_STAT_OPEN_FRAMES] == 7 &&
           statistics[BOWLING_STAT_SINGLE_PIN_ATTEMPTS] == 0 &&
           statistics[BOWLING_STAT_MULTI_PIN_ATTEMPTS] == 9 &&
           statistics[BOWLING_STAT_MULTI_PIN_SPARES] == 2 &&
           statistics[BOWLING_STAT_CLEAN_FRAMES] == 3;
}

(:test)
function testPerfectGameStatisticsHaveNoSpareAttempts(logger) {
    var statistics = BowlingStatistics.forGame(buildPerfectGameForStorageTest());

    return statistics[BOWLING_STAT_FIRST_BALL_PINS] == 100 &&
           statistics[BOWLING_STAT_STRIKES] == 10 &&
           statistics[BOWLING_STAT_SPARE_ATTEMPTS] == 0 &&
           statistics[BOWLING_STAT_SPARES] == 0 &&
           statistics[BOWLING_STAT_OPEN_FRAMES] == 0 &&
           statistics[BOWLING_STAT_CLEAN_FRAMES] == 10 &&
           BowlingStatistics.formatPercent(0, 0).equals("--");
}

(:test)
function testStatisticsSeparateSingleAndMultiPinSpares(logger) {
    var game = new BowlingGame();
    game.recordThrow(9);
    game.recordThrow(1);
    game.recordThrow(9);
    game.recordThrow(0);
    game.recordThrow(8);
    game.recordThrow(2);
    for (var frame = 3; frame < 10; frame++) {
        game.recordThrow(0);
        game.recordThrow(0);
    }

    var statistics = BowlingStatistics.forGame(game);
    return game.isGameComplete() &&
           statistics[BOWLING_STAT_SINGLE_PIN_ATTEMPTS] == 2 &&
           statistics[BOWLING_STAT_SINGLE_PIN_SPARES] == 1 &&
           statistics[BOWLING_STAT_MULTI_PIN_ATTEMPTS] == 8 &&
           statistics[BOWLING_STAT_MULTI_PIN_SPARES] == 1 &&
           BowlingStatistics.formatPercent(1, 2).equals("50%");
}

(:test)
function testSavedGameStoreMaintainsLifetimeStatistics(logger) {
    BowlingSavedGameStore.clearSavedGames();
    BowlingSavedGameStore.saveGameAt(buildPerfectGameForStorageTest(), 1770001200);

    var gutterGame = buildGameThroughNineFramesForTest();
    gutterGame.recordThrow(0);
    gutterGame.recordThrow(0);
    BowlingSavedGameStore.saveGameAt(gutterGame, 1770001300);

    var statistics = BowlingSavedGameStore.getAggregateStatistics();
    BowlingSavedGameStore.clearSavedGames();

    return statistics[BOWLING_STAT_GAME_COUNT] == 2 &&
           statistics[BOWLING_STAT_TOTAL_SCORE] == 300 &&
           statistics[BOWLING_STAT_HIGH_SCORE] == 300 &&
           statistics[BOWLING_STAT_LOW_SCORE] == 0 &&
           statistics[BOWLING_STAT_FIRST_BALL_PINS] == 100 &&
           statistics[BOWLING_STAT_STRIKES] == 10 &&
           statistics[BOWLING_STAT_SPARE_ATTEMPTS] == 10 &&
           statistics[BOWLING_STAT_SPARES] == 0 &&
           statistics[BOWLING_STAT_OPEN_FRAMES] == 10 &&
           statistics[BOWLING_STAT_CLEAN_FRAMES] == 10 &&
           statistics[BOWLING_STAT_SERIES_COUNT] == 1 &&
           statistics[BOWLING_STAT_HIGH_SERIES] == 300 &&
           BowlingStatistics.formatAverage(300, 2).equals("150.0") &&
           BowlingStatistics.formatPercent(10, 20).equals("50%");
}

(:test)
function testClearingGamesAlsoClearsLifetimeStatistics(logger) {
    BowlingSavedGameStore.clearSavedGames();
    BowlingSavedGameStore.saveGameAt(buildPerfectGameForStorageTest(), 1770001400);
    BowlingSavedGameStore.clearSavedGames();

    var statistics = BowlingSavedGameStore.getAggregateStatistics();
    return BowlingSavedGameStore.getSavedGameCount() == 0 &&
           statistics[BOWLING_STAT_GAME_COUNT] == 0 &&
           statistics[BOWLING_STAT_TOTAL_SCORE] == 0 &&
           statistics[BOWLING_STAT_HIGH_SCORE] == 0 &&
           statistics[BOWLING_STAT_LOW_SCORE] == 0 &&
           statistics[BOWLING_STAT_SERIES_COUNT] == 0 &&
           statistics[BOWLING_STAT_HIGH_SERIES] == 0;
}

(:test)
function testSavedGameStoreGroupsNearbyGamesIntoSeries(logger) {
    BowlingSavedGameStore.clearSavedGames();
    BowlingSavedGameStore.saveGameAt(buildPerfectGameForStorageTest(), 1770002000);

    var gutterGame = buildGameThroughNineFramesForTest();
    gutterGame.recordThrow(0);
    gutterGame.recordThrow(0);
    BowlingSavedGameStore.saveGameAt(gutterGame, 1770002000 + BOWLING_SAVED_GAME_SERIES_GAP_SECONDS);
    BowlingSavedGameStore.saveGameAt(buildPerfectGameForStorageTest(), 1770002001 + (BOWLING_SAVED_GAME_SERIES_GAP_SECONDS * 2));

    var statistics = BowlingSavedGameStore.getAggregateStatistics();
    BowlingSavedGameStore.clearSavedGames();

    return statistics[BOWLING_STAT_GAME_COUNT] == 3 &&
           statistics[BOWLING_STAT_SERIES_COUNT] == 2 &&
           statistics[BOWLING_STAT_HIGH_SERIES] == 300 &&
           BowlingStatistics.formatAverage(statistics[BOWLING_STAT_TOTAL_SCORE] as Number, statistics[BOWLING_STAT_SERIES_COUNT] as Number).equals("300.0") &&
           BowlingStatistics.formatAverage(statistics[BOWLING_STAT_GAME_COUNT] as Number, statistics[BOWLING_STAT_SERIES_COUNT] as Number).equals("1.5");
}

(:test)
function testSavedSeriesSummariesAndStatistics(logger) {
    BowlingSavedGameStore.clearSavedGames();
    var firstSavedAt = 1770010000;
    BowlingSavedGameStore.saveGameAt(buildPerfectGameForStorageTest(), firstSavedAt);

    var gutterGame = buildGameThroughNineFramesForTest();
    gutterGame.recordThrow(0);
    gutterGame.recordThrow(0);
    BowlingSavedGameStore.saveGameAt(gutterGame, firstSavedAt + 1200);
    BowlingSavedGameStore.saveGameAt(
        buildPerfectGameForStorageTest(),
        firstSavedAt + 1201 + BOWLING_SAVED_GAME_SERIES_GAP_SECONDS
    );

    var seriesCount = BowlingSavedGameStore.getSavedSeriesCount();
    var newest = BowlingSavedGameStore.getSavedSeriesSummary(0) as Lang.Dictionary;
    var older = BowlingSavedGameStore.getSavedSeriesSummary(1) as Lang.Dictionary;
    var statistics = BowlingSavedGameStore.getSavedSeriesStatistics(older);
    BowlingSavedGameStore.clearSavedGames();

    return seriesCount == 2 &&
           newest[BOWLING_SAVED_SERIES_START_INDEX] == 0 &&
           newest[BOWLING_SAVED_SERIES_GAME_COUNT] == 1 &&
           newest[BOWLING_SAVED_SERIES_TOTAL_SCORE] == 300 &&
           older[BOWLING_SAVED_SERIES_START_INDEX] == 1 &&
           older[BOWLING_SAVED_SERIES_GAME_COUNT] == 2 &&
           older[BOWLING_SAVED_SERIES_STARTED_AT] == firstSavedAt &&
           older[BOWLING_SAVED_SERIES_TOTAL_SCORE] == 300 &&
           statistics[BOWLING_STAT_GAME_COUNT] == 2 &&
           statistics[BOWLING_STAT_TOTAL_SCORE] == 300 &&
           statistics[BOWLING_STAT_HIGH_SCORE] == 300 &&
           statistics[BOWLING_STAT_LOW_SCORE] == 0 &&
           statistics[BOWLING_STAT_FIRST_BALL_PINS] == 100 &&
           statistics[BOWLING_STAT_STRIKES] == 10 &&
           statistics[BOWLING_STAT_OPEN_FRAMES] == 10 &&
           statistics[BOWLING_STAT_CLEAN_FRAMES] == 10;
}

(:test)
function testVersionTwoStoreMigratesStatisticsOnce(logger) {
    BowlingSavedGameStore.clearSavedGames();
    var perfectRecord = BowlingSavedGameStore.buildRecord(buildPerfectGameForStorageTest(), 1770001500);
    var gutterGame = buildGameThroughNineFramesForTest();
    gutterGame.recordThrow(0);
    gutterGame.recordThrow(0);
    var gutterRecord = BowlingSavedGameStore.buildRecord(gutterGame, 1770001600);
    var legacy = [BOWLING_SAVED_GAMES_LEGACY_FORMAT_VERSION, 2] as Lang.Array;
    legacy.addAll(gutterRecord);
    legacy.addAll(perfectRecord);
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, legacy);

    var statistics = BowlingSavedGameStore.getAggregateStatistics();
    var migrated = Application.Storage.getValue(BOWLING_SAVED_GAMES_STORAGE_KEY) as Lang.Array;
    var savedCount = BowlingSavedGameStore.getSavedGameCount();
    BowlingSavedGameStore.clearSavedGames();

    return migrated[0] == BOWLING_SAVED_GAMES_FORMAT_VERSION &&
           migrated.size() == BOWLING_SAVED_GAMES_HEADER_SIZE + (2 * BOWLING_SAVED_GAME_RECORD_SIZE) &&
           savedCount == 2 &&
           statistics[BOWLING_STAT_GAME_COUNT] == 2 &&
           statistics[BOWLING_STAT_TOTAL_SCORE] == 300 &&
           statistics[BOWLING_STAT_OPEN_FRAMES] == 10 &&
           statistics[BOWLING_STAT_SERIES_COUNT] == 1 &&
           statistics[BOWLING_STAT_HIGH_SERIES] == 300;
}

(:test)
function testVersionFourStoreMigratesDetailedStatistics(logger) {
    BowlingSavedGameStore.clearSavedGames();
    var perfectRecord = BowlingSavedGameStore.buildRecord(buildPerfectGameForStorageTest(), 1770001700);
    var gutterGame = buildGameThroughNineFramesForTest();
    gutterGame.recordThrow(0);
    gutterGame.recordThrow(0);
    var gutterRecord = BowlingSavedGameStore.buildRecord(gutterGame, 1770001800);
    var previous = [
        BOWLING_SAVED_GAMES_PREVIOUS_FORMAT_VERSION,
        2,
        2,
        300,
        300,
        100,
        10,
        10,
        0,
        10,
        1,
        300,
        300,
        2
    ] as Lang.Array;
    previous.addAll(gutterRecord);
    previous.addAll(perfectRecord);
    Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, previous);

    var statistics = BowlingSavedGameStore.getAggregateStatistics();
    var migrated = Application.Storage.getValue(BOWLING_SAVED_GAMES_STORAGE_KEY) as Lang.Array;
    BowlingSavedGameStore.clearSavedGames();

    return migrated[0] == BOWLING_SAVED_GAMES_FORMAT_VERSION &&
           migrated.size() == BOWLING_SAVED_GAMES_HEADER_SIZE + (2 * BOWLING_SAVED_GAME_RECORD_SIZE) &&
           statistics[BOWLING_STAT_LOW_SCORE] == 0 &&
           statistics[BOWLING_STAT_CLEAN_FRAMES] == 10 &&
           statistics[BOWLING_STAT_SINGLE_PIN_ATTEMPTS] == 0 &&
           statistics[BOWLING_STAT_MULTI_PIN_ATTEMPTS] == 10;
}

function buildPerfectGameForStorageTest() as BowlingGame {
    var game = new BowlingGame();
    for (var i = 0; i < 12; i++) {
        game.recordThrow(10);
    }

    return game;
}

function buildGameThroughNineFramesForTest() as BowlingGame {
    var game = new BowlingGame();
    for (var i = 0; i < 18; i++) {
        game.recordThrow(0);
    }

    return game;
}

function buildPerfectGameStoreForTest(count as Number) as Lang.Array {
    return [
        BOWLING_SAVED_GAMES_FORMAT_VERSION,
        count,
        count,
        count * 300,
        count > 0 ? 300 : 0,
        count * 100,
        count * 10,
        0,
        0,
        0,
        count > 0 ? 1 : 0,
        count * 300,
        count * 300,
        count,
        count > 0 ? 300 : 0,
        0,
        0,
        0,
        0,
        count * 10
    ] as Lang.Array;
}
