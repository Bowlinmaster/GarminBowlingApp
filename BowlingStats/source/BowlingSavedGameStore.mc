import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

const BOWLING_SAVED_GAMES_STORAGE_KEY = "games.v2";
const BOWLING_SAVED_GAMES_FORMAT_VERSION = 2;
const BOWLING_SAVED_GAMES_HEADER_SIZE = 2;
const BOWLING_SAVED_GAME_RECORD_SIZE = 6;
const BOWLING_SAVED_GAMES_MAX_COUNT = 100;
const BOWLING_SAVED_GAME_PIN_GROUP_SIZE = 7;
const BOWLING_SAVED_GAME_PIN_GROUP_COUNT = 3;

const BOWLING_SAVED_GAME_SAVED_AT = "t";
const BOWLING_SAVED_GAME_SCORE = "s";
const BOWLING_SAVED_GAME_ROLL_COUNT = "n";
const BOWLING_SAVED_GAME_PIN_COUNTS = "p";
const BOWLING_SAVED_GAME_MODEL = "g";

class BowlingSavedGameStore {
    // Store layout: [version, count], then newest-first fixed records.
    // Each record is savedAt, score, rollCount, and three packed pin-count fields.
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

            var updated = [];
            updated.add(BOWLING_SAVED_GAMES_FORMAT_VERSION);
            updated.add(recordsToKeep + 1);
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
            if (!(values instanceof Lang.Array) || values.size() < BOWLING_SAVED_GAMES_HEADER_SIZE ||
                !(values[0] instanceof Number) || values[0] != BOWLING_SAVED_GAMES_FORMAT_VERSION) {
                return emptyStore();
            }

            return values;
        } catch (ex) {
            return emptyStore();
        }
    }

    private static function emptyStore() as Lang.Array {
        return [BOWLING_SAVED_GAMES_FORMAT_VERSION, 0];
    }

    private static function getStoredCount(values as Lang.Array) as Number {
        var count = values[1];
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
            var updated = [BOWLING_SAVED_GAMES_FORMAT_VERSION, count - 1];

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
