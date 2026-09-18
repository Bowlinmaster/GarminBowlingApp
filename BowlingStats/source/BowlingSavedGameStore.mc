import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

const BOWLING_SAVED_GAMES_STORAGE_KEY = "games.v2";
const BOWLING_SAVED_GAMES_FORMAT_VERSION = 4;
const BOWLING_SAVED_GAMES_PREVIOUS_FORMAT_VERSION = 3;
const BOWLING_SAVED_GAMES_LEGACY_FORMAT_VERSION = 2;
const BOWLING_SAVED_GAMES_LEGACY_HEADER_SIZE = 2;
const BOWLING_SAVED_GAMES_PREVIOUS_HEADER_SIZE = 10;
const BOWLING_SAVED_GAMES_HEADER_SIZE = 14;
const BOWLING_SAVED_GAME_RECORD_SIZE = 6;
const BOWLING_SAVED_GAMES_MAX_COUNT = 100;
const BOWLING_SAVED_GAME_PIN_GROUP_SIZE = 7;
const BOWLING_SAVED_GAME_PIN_GROUP_COUNT = 3;
const BOWLING_SAVED_GAME_SERIES_GAP_SECONDS = 7200;

const BOWLING_SAVED_GAME_SAVED_AT = "t";
const BOWLING_SAVED_GAME_SCORE = "s";
const BOWLING_SAVED_GAME_ROLL_COUNT = "n";
const BOWLING_SAVED_GAME_PIN_COUNTS = "p";
const BOWLING_SAVED_GAME_MODEL = "g";

const BOWLING_SAVED_GAMES_COUNT_INDEX = 1;
const BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX = 2;
const BOWLING_SAVED_GAMES_TOTAL_SCORE_INDEX = 3;
const BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX = 4;
const BOWLING_SAVED_GAMES_FIRST_BALL_PINS_INDEX = 5;
const BOWLING_SAVED_GAMES_STRIKES_INDEX = 6;
const BOWLING_SAVED_GAMES_SPARE_ATTEMPTS_INDEX = 7;
const BOWLING_SAVED_GAMES_SPARES_INDEX = 8;
const BOWLING_SAVED_GAMES_OPEN_FRAMES_INDEX = 9;
const BOWLING_SAVED_GAMES_SERIES_COUNT_INDEX = 10;
const BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX = 11;
const BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX = 12;
const BOWLING_SAVED_GAMES_ACTIVE_SERIES_GAMES_INDEX = 13;

class BowlingSavedGameStore {
    // The header keeps lifetime totals and current-series state in fixed integer fields. Game records
    // remain six values each: savedAt, score, rollCount, and three packed rolls.
    static function saveGame(game as BowlingGame) as Boolean {
        return saveGameAt(game, Time.now().value());
    }

    static function saveGameAt(game as BowlingGame, savedAtSeconds as Number) as Boolean {
        if (game == null || !game.isGameComplete() || !isValidTimestamp(savedAtSeconds)) {
            return false;
        }

        try {
            var existing = getStoredValues();
            var existingCount = getStoredCount(existing);
            var recordsToKeep = existingCount;
            if (recordsToKeep >= BOWLING_SAVED_GAMES_MAX_COUNT) {
                recordsToKeep = BOWLING_SAVED_GAMES_MAX_COUNT - 1;
            }

            var updated = existing.slice(0, BOWLING_SAVED_GAMES_HEADER_SIZE) as Lang.Array;
            updated[BOWLING_SAVED_GAMES_COUNT_INDEX] = recordsToKeep + 1;
            addStatisticsToHeader(updated, BowlingStatistics.forGame(game));
            addGameToSeriesHeader(updated, game.getScore(), savedAtSeconds, getNewestSavedAt(existing));
            updated.addAll(buildRecord(game, savedAtSeconds));

            if (recordsToKeep > 0) {
                updated.addAll(existing.slice(BOWLING_SAVED_GAMES_HEADER_SIZE, BOWLING_SAVED_GAMES_HEADER_SIZE + (recordsToKeep * BOWLING_SAVED_GAME_RECORD_SIZE)));
            }

            Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, updated);
        } catch (ex) {
            return false;
        }

        return true;
    }

    static function getSavedGame(index as Number) as Lang.Dictionary or Null {
        if (!(index instanceof Number) || index < 0) {
            return null;
        }

        var values = getStoredValues();
        var count = getStoredCount(values);
        if (index >= count) {
            return null;
        }

        // Corruption is exceptional. Remove only records encountered while resolving
        // the requested index, leaving normal reads proportional to one game.
        while (index < count) {
            var game = decodeRecord(values, BOWLING_SAVED_GAMES_HEADER_SIZE + (index * BOWLING_SAVED_GAME_RECORD_SIZE));
            if (game != null) {
                return game;
            }

            if (!removeStoredRecord(values, index, count)) {
                return null;
            }

            values = getStoredValues();
            count = getStoredCount(values);
        }

        return null;
    }

    static function getSavedGameSummary(index as Number) as Lang.Dictionary or Null {
        if (!(index instanceof Number) || index < 0) {
            return null;
        }

        var values = getStoredValues();
        var count = getStoredCount(values);
        if (index >= count) {
            return null;
        }

        while (index < count) {
            var summary = decodeSummary(values, BOWLING_SAVED_GAMES_HEADER_SIZE + (index * BOWLING_SAVED_GAME_RECORD_SIZE));
            if (summary != null) {
                return summary;
            }

            if (!removeStoredRecord(values, index, count)) {
                return null;
            }

            values = getStoredValues();
            count = getStoredCount(values);
        }

        return null;
    }

    static function getSavedGameCount() as Number {
        return getStoredCount(getStoredValues());
    }

    static function getAggregateStatistics() as Lang.Dictionary {
        var values = getStoredValues();
        var gameCount = values[BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX] as Number;

        return {
            BOWLING_STAT_GAME_COUNT => gameCount,
            BOWLING_STAT_TOTAL_SCORE => values[BOWLING_SAVED_GAMES_TOTAL_SCORE_INDEX],
            BOWLING_STAT_HIGH_SCORE => values[BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX],
            BOWLING_STAT_FIRST_BALL_PINS => values[BOWLING_SAVED_GAMES_FIRST_BALL_PINS_INDEX],
            BOWLING_STAT_FIRST_BALL_ATTEMPTS => gameCount * 10,
            BOWLING_STAT_STRIKES => values[BOWLING_SAVED_GAMES_STRIKES_INDEX],
            BOWLING_STAT_STRIKE_ATTEMPTS => gameCount * 10,
            BOWLING_STAT_SPARE_ATTEMPTS => values[BOWLING_SAVED_GAMES_SPARE_ATTEMPTS_INDEX],
            BOWLING_STAT_SPARES => values[BOWLING_SAVED_GAMES_SPARES_INDEX],
            BOWLING_STAT_OPEN_FRAMES => values[BOWLING_SAVED_GAMES_OPEN_FRAMES_INDEX],
            BOWLING_STAT_SERIES_COUNT => values[BOWLING_SAVED_GAMES_SERIES_COUNT_INDEX],
            BOWLING_STAT_HIGH_SERIES => values[BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX]
        };
    }

    static function clearSavedGames() as Void {
        Application.Storage.deleteValue(BOWLING_SAVED_GAMES_STORAGE_KEY);
    }

    static function buildRecord(game as BowlingGame, savedAtSeconds as Number) as Lang.Array {
        var record = [] as Lang.Array;
        var rollCount = game.getRecordedRollCount();

        record.add(savedAtSeconds);
        record.add(game.getScore());
        record.add(rollCount);

        for (var group = 0; group < BOWLING_SAVED_GAME_PIN_GROUP_COUNT; group++) {
            record.add(packPinGroup(game, rollCount, group * BOWLING_SAVED_GAME_PIN_GROUP_SIZE));
        }

        return record;
    }

    static function decodeRecord(values as Lang.Array, offset as Number) as Lang.Dictionary or Null {
        try {
            if (!(values instanceof Lang.Array) || !(offset instanceof Number) || offset < 0 || offset + BOWLING_SAVED_GAME_RECORD_SIZE > values.size()) {
                return null;
            }

            var savedAt = values[offset];
            var score = values[offset + 1];
            var rollCount = values[offset + 2];
            if (!isValidTimestamp(savedAt) || !(score instanceof Number) || score < 0 || score > 300 ||
                !(rollCount instanceof Number) || rollCount < 11 || rollCount > 21 ||
                !hasValidPackedPinGroups(values, offset + 3, rollCount)) {
                return null;
            }

            var pins = unpackPins(values, offset + 3, rollCount);
            var game = buildValidatedGame(pins, score);
            if (game == null) {
                return null;
            }

            return {
                BOWLING_SAVED_GAME_SAVED_AT => savedAt,
                BOWLING_SAVED_GAME_SCORE => score,
                BOWLING_SAVED_GAME_ROLL_COUNT => rollCount,
                BOWLING_SAVED_GAME_PIN_COUNTS => pins,
                BOWLING_SAVED_GAME_MODEL => game
            };
        } catch (ex) {
            return null;
        }
    }

    private static function decodeSummary(values as Lang.Array, offset as Number) as Lang.Dictionary or Null {
        try {
            if (!(values instanceof Lang.Array) || !(offset instanceof Number) || offset < 0 || offset + BOWLING_SAVED_GAME_RECORD_SIZE > values.size()) {
                return null;
            }

            var savedAt = values[offset];
            var score = values[offset + 1];
            var rollCount = values[offset + 2];
            if (!isValidTimestamp(savedAt) || !(score instanceof Number) || score < 0 || score > 300 ||
                !(rollCount instanceof Number) || rollCount < 11 || rollCount > 21 ||
                !hasValidPackedPinGroups(values, offset + 3, rollCount)) {
                return null;
            }

            return {
                BOWLING_SAVED_GAME_SAVED_AT => savedAt,
                BOWLING_SAVED_GAME_SCORE => score
            };
        } catch (ex) {
            return null;
        }
    }

    private static function getStoredValues() as Lang.Array {
        try {
            var values = Application.Storage.getValue(BOWLING_SAVED_GAMES_STORAGE_KEY);
            if (!(values instanceof Lang.Array) || values.size() < BOWLING_SAVED_GAMES_LEGACY_HEADER_SIZE ||
                !(values[0] instanceof Number)) {
                return emptyStore();
            }

            if (values[0] == BOWLING_SAVED_GAMES_LEGACY_FORMAT_VERSION) {
                return rebuildStore(values, BOWLING_SAVED_GAMES_LEGACY_HEADER_SIZE);
            }

            if (values[0] == BOWLING_SAVED_GAMES_PREVIOUS_FORMAT_VERSION) {
                return rebuildStore(values, BOWLING_SAVED_GAMES_PREVIOUS_HEADER_SIZE);
            }

            if (values[0] != BOWLING_SAVED_GAMES_FORMAT_VERSION ||
                values.size() < BOWLING_SAVED_GAMES_HEADER_SIZE) {
                return emptyStore();
            }

            if (!hasValidHeader(values)) {
                return rebuildStore(values, BOWLING_SAVED_GAMES_HEADER_SIZE);
            }

            return values;
        } catch (ex) {
            return emptyStore();
        }
    }

    private static function emptyStore() as Lang.Array {
        return [BOWLING_SAVED_GAMES_FORMAT_VERSION, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    }

    private static function getStoredCount(values as Lang.Array) as Number {
        var count = values[BOWLING_SAVED_GAMES_COUNT_INDEX];
        if (!(count instanceof Number) || count < 0) {
            return 0;
        }

        var availableRecords = (values.size() - BOWLING_SAVED_GAMES_HEADER_SIZE) / BOWLING_SAVED_GAME_RECORD_SIZE;
        if (count > availableRecords) {
            return availableRecords;
        }

        if (count > BOWLING_SAVED_GAMES_MAX_COUNT) {
            return BOWLING_SAVED_GAMES_MAX_COUNT;
        }

        return count;
    }

    private static function removeStoredRecord(values as Lang.Array, index as Number, count as Number) as Boolean {
        try {
            var offset = BOWLING_SAVED_GAMES_HEADER_SIZE + (index * BOWLING_SAVED_GAME_RECORD_SIZE);
            var end = BOWLING_SAVED_GAMES_HEADER_SIZE + (count * BOWLING_SAVED_GAME_RECORD_SIZE);
            var updated = values.slice(0, BOWLING_SAVED_GAMES_HEADER_SIZE) as Lang.Array;
            updated[BOWLING_SAVED_GAMES_COUNT_INDEX] = count - 1;

            if (offset > BOWLING_SAVED_GAMES_HEADER_SIZE) {
                updated.addAll(values.slice(BOWLING_SAVED_GAMES_HEADER_SIZE, offset));
            }

            if (offset + BOWLING_SAVED_GAME_RECORD_SIZE < end) {
                updated.addAll(values.slice(offset + BOWLING_SAVED_GAME_RECORD_SIZE, end));
            }

            Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, updated);
            return true;
        } catch (ex) {
            return false;
        }
    }

    private static function hasValidHeader(values as Lang.Array) as Boolean {
        for (var index = BOWLING_SAVED_GAMES_COUNT_INDEX; index < BOWLING_SAVED_GAMES_HEADER_SIZE; index++) {
            if (!(values[index] instanceof Number) || values[index] < 0) {
                return false;
            }
        }

        var savedCount = values[BOWLING_SAVED_GAMES_COUNT_INDEX] as Number;
        var gameCount = values[BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX] as Number;
        var totalScore = values[BOWLING_SAVED_GAMES_TOTAL_SCORE_INDEX] as Number;
        var highScore = values[BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX] as Number;
        var firstBallPins = values[BOWLING_SAVED_GAMES_FIRST_BALL_PINS_INDEX] as Number;
        var strikes = values[BOWLING_SAVED_GAMES_STRIKES_INDEX] as Number;
        var spareAttempts = values[BOWLING_SAVED_GAMES_SPARE_ATTEMPTS_INDEX] as Number;
        var spares = values[BOWLING_SAVED_GAMES_SPARES_INDEX] as Number;
        var openFrames = values[BOWLING_SAVED_GAMES_OPEN_FRAMES_INDEX] as Number;
        var seriesCount = values[BOWLING_SAVED_GAMES_SERIES_COUNT_INDEX] as Number;
        var highSeries = values[BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX] as Number;
        var activeSeriesScore = values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX] as Number;
        var activeSeriesGames = values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_GAMES_INDEX] as Number;

        return savedCount <= BOWLING_SAVED_GAMES_MAX_COUNT &&
               savedCount <= gameCount &&
               totalScore <= gameCount * 300 &&
               highScore <= 300 &&
               firstBallPins <= gameCount * 100 &&
               strikes <= gameCount * 10 &&
               spareAttempts <= gameCount * 10 &&
               spares <= spareAttempts &&
               openFrames <= spareAttempts &&
               strikes + spareAttempts == gameCount * 10 &&
               spares + openFrames == spareAttempts &&
               ((gameCount == 0 && seriesCount == 0 && activeSeriesGames == 0) ||
                (gameCount > 0 && seriesCount > 0 && seriesCount <= gameCount && activeSeriesGames > 0 && activeSeriesGames <= gameCount)) &&
               activeSeriesScore <= activeSeriesGames * 300 &&
               highSeries >= activeSeriesScore;
    }

    private static function rebuildStore(values as Lang.Array, sourceHeaderSize as Number) as Lang.Array {
        var rebuilt = emptyStore();
        var declaredCount = values.size() > 1 && values[1] instanceof Number ? values[1] : 0;
        var availableCount = (values.size() - sourceHeaderSize) / BOWLING_SAVED_GAME_RECORD_SIZE;
        var count = declaredCount;
        if (count < 0) {
            count = 0;
        }
        if (count > availableCount) {
            count = availableCount;
        }
        if (count > BOWLING_SAVED_GAMES_MAX_COUNT) {
            count = BOWLING_SAVED_GAMES_MAX_COUNT;
        }

        for (var index = 0; index < count; index++) {
            var offset = sourceHeaderSize + (index * BOWLING_SAVED_GAME_RECORD_SIZE);
            var decoded = decodeRecord(values, offset);
            if (decoded == null) {
                continue;
            }

            rebuilt[BOWLING_SAVED_GAMES_COUNT_INDEX] += 1;
            addStatisticsToHeader(rebuilt, BowlingStatistics.forGame(decoded[BOWLING_SAVED_GAME_MODEL] as BowlingGame));
            rebuilt.addAll(values.slice(offset, offset + BOWLING_SAVED_GAME_RECORD_SIZE));
        }

        rebuildSeriesHeader(rebuilt);

        Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, rebuilt);
        return rebuilt;
    }

    private static function addStatisticsToHeader(values as Lang.Array, statistics as Lang.Dictionary) as Void {
        values[BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX] += statistics[BOWLING_STAT_GAME_COUNT] as Number;
        values[BOWLING_SAVED_GAMES_TOTAL_SCORE_INDEX] += statistics[BOWLING_STAT_TOTAL_SCORE] as Number;
        var score = statistics[BOWLING_STAT_HIGH_SCORE] as Number;
        if (score > values[BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX]) {
            values[BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX] = score;
        }
        values[BOWLING_SAVED_GAMES_FIRST_BALL_PINS_INDEX] += statistics[BOWLING_STAT_FIRST_BALL_PINS] as Number;
        values[BOWLING_SAVED_GAMES_STRIKES_INDEX] += statistics[BOWLING_STAT_STRIKES] as Number;
        values[BOWLING_SAVED_GAMES_SPARE_ATTEMPTS_INDEX] += statistics[BOWLING_STAT_SPARE_ATTEMPTS] as Number;
        values[BOWLING_SAVED_GAMES_SPARES_INDEX] += statistics[BOWLING_STAT_SPARES] as Number;
        values[BOWLING_SAVED_GAMES_OPEN_FRAMES_INDEX] += statistics[BOWLING_STAT_OPEN_FRAMES] as Number;
    }

    private static function getNewestSavedAt(values as Lang.Array) as Number or Null {
        if (getStoredCount(values) == 0) {
            return null;
        }

        var savedAt = values[BOWLING_SAVED_GAMES_HEADER_SIZE];
        return isValidTimestamp(savedAt) ? savedAt : null;
    }

    private static function addGameToSeriesHeader(values as Lang.Array, score as Number, savedAt as Number, previousSavedAt as Number or Null) as Void {
        var sameSeries = previousSavedAt != null && savedAt >= previousSavedAt &&
            savedAt - previousSavedAt <= BOWLING_SAVED_GAME_SERIES_GAP_SECONDS;

        if (sameSeries) {
            values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX] += score;
            values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_GAMES_INDEX] += 1;
        } else {
            values[BOWLING_SAVED_GAMES_SERIES_COUNT_INDEX] += 1;
            values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX] = score;
            values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_GAMES_INDEX] = 1;
        }

        if (values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX] > values[BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX]) {
            values[BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX] = values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX];
        }
    }

    private static function rebuildSeriesHeader(values as Lang.Array) as Void {
        var previousSavedAt = null;
        for (var index = getStoredCount(values) - 1; index >= 0; index--) {
            var offset = BOWLING_SAVED_GAMES_HEADER_SIZE + (index * BOWLING_SAVED_GAME_RECORD_SIZE);
            var savedAt = values[offset] as Number;
            var score = values[offset + 1] as Number;
            addGameToSeriesHeader(values, score, savedAt, previousSavedAt);
            previousSavedAt = savedAt;
        }
    }

    private static function isValidTimestamp(savedAtSeconds) as Boolean {
        return savedAtSeconds instanceof Number && savedAtSeconds > 0;
    }

    private static function hasValidPackedPinGroups(values as Lang.Array, offset as Number, rollCount as Number) as Boolean {
        for (var group = 0; group < BOWLING_SAVED_GAME_PIN_GROUP_COUNT; group++) {
            var packed = values[offset + group];
            if (!(packed instanceof Number) || packed < 0 || packed > 0x0fffffff) {
                return false;
            }
        }

        // Unused nibbles are always zero in this format.
        for (var i = rollCount; i < BOWLING_SAVED_GAME_PIN_GROUP_SIZE * BOWLING_SAVED_GAME_PIN_GROUP_COUNT; i++) {
            var packedGroup = values[offset + (i / BOWLING_SAVED_GAME_PIN_GROUP_SIZE)];
            var shift = (i % BOWLING_SAVED_GAME_PIN_GROUP_SIZE) * 4;
            if (((packedGroup >> shift) & 0x0f) != 0) {
                return false;
            }
        }

        return true;
    }

    private static function buildValidatedGame(pins as Array<Number>, expectedScore as Number) as BowlingGame or Null {
        var game = new BowlingGame();
        for (var i = 0; i < pins.size(); i++) {
            if (pins[i] > 10 || !game.recordThrow(pins[i])) {
                return null;
            }
        }

        if (!game.isGameComplete() || game.getScore() != expectedScore) {
            return null;
        }

        return game;
    }

    private static function packPinGroup(game as BowlingGame, rollCount as Number, startRollIndex as Number) as Number {
        var packed = 0;
        var shift = 0;

        for (var offset = 0; offset < BOWLING_SAVED_GAME_PIN_GROUP_SIZE; offset++) {
            var rollIndex = startRollIndex + offset;
            var pins = rollIndex < rollCount ? game.getRecordedPinsAt(rollIndex) : 0;
            packed = packed | ((pins & 0x0f) << shift);
            shift += 4;
        }

        return packed;
    }

    private static function unpackPins(values as Lang.Array, offset as Number, rollCount as Number) as Array<Number> {
        var pins = [] as Array<Number>;
        for (var i = 0; i < rollCount; i++) {
            var packed = values[offset + (i / BOWLING_SAVED_GAME_PIN_GROUP_SIZE)];
            var shift = (i % BOWLING_SAVED_GAME_PIN_GROUP_SIZE) * 4;
            pins.add((packed >> shift) & 0x0f);
        }

        return pins;
    }
}
