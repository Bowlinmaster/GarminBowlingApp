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

class BowlingSavedGameStore {
    // Store layout: [version, count], then newest-first fixed records.
    // Each record is savedAt, score, rollCount, and three packed pin-count fields.
    static function saveGame(game) {
        return saveGameAt(game, Time.now().value());
    }

    static function saveGameAt(game, savedAtSeconds) {
        if (game == null || !game.isGameComplete()) {
            return false;
        }

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

        try {
            Application.Storage.setValue(BOWLING_SAVED_GAMES_STORAGE_KEY, updated);
        } catch (ex) {
            return false;
        }

        return true;
    }

    static function getSavedGames() {
        var games = [];
        var values = getStoredValues();
        var count = getStoredCount(values);

        for (var i = 0; i < count; i++) {
            games.add(decodeRecord(values, BOWLING_SAVED_GAMES_HEADER_SIZE + (i * BOWLING_SAVED_GAME_RECORD_SIZE)));
        }

        return games;
    }

    static function getSavedGameCount() {
        return getStoredCount(getStoredValues());
    }

    static function clearSavedGames() {
        Application.Storage.deleteValue(BOWLING_SAVED_GAMES_STORAGE_KEY);
    }

    static function buildRecord(game, savedAtSeconds) {
        var record = [];
        var rollCount = game.getRecordedRollCount();

        record.add(savedAtSeconds);
        record.add(game.getScore());
        record.add(rollCount);

        for (var group = 0; group < BOWLING_SAVED_GAME_PIN_GROUP_COUNT; group++) {
            record.add(packPinGroup(game, rollCount, group * BOWLING_SAVED_GAME_PIN_GROUP_SIZE));
        }

        return record;
    }

    static function decodeRecord(values, offset) {
        var rollCount = values[offset + 2];
        return {
            BOWLING_SAVED_GAME_SAVED_AT => values[offset],
            BOWLING_SAVED_GAME_SCORE => values[offset + 1],
            BOWLING_SAVED_GAME_ROLL_COUNT => rollCount,
            BOWLING_SAVED_GAME_PIN_COUNTS => unpackPins(values, offset + 3, rollCount)
        };
    }

    private static function getStoredValues() {
        var values = Application.Storage.getValue(BOWLING_SAVED_GAMES_STORAGE_KEY);
        if (!(values instanceof Lang.Array) || values.size() < BOWLING_SAVED_GAMES_HEADER_SIZE || values[0] != BOWLING_SAVED_GAMES_FORMAT_VERSION) {
            return emptyStore();
        }

        return values;
    }

    private static function emptyStore() {
        return [BOWLING_SAVED_GAMES_FORMAT_VERSION, 0];
    }

    private static function getStoredCount(values) {
        var count = values[1];
        var availableRecords = (values.size() - BOWLING_SAVED_GAMES_HEADER_SIZE) / BOWLING_SAVED_GAME_RECORD_SIZE;
        if (count > availableRecords) {
            return availableRecords;
        }

        if (count > BOWLING_SAVED_GAMES_MAX_COUNT) {
            return BOWLING_SAVED_GAMES_MAX_COUNT;
        }

        return count;
    }

    private static function packPinGroup(game, rollCount, startRollIndex) {
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

    private static function unpackPins(values, offset, rollCount) {
        var pins = [];
        for (var i = 0; i < rollCount; i++) {
            var packed = values[offset + (i / BOWLING_SAVED_GAME_PIN_GROUP_SIZE)];
            var shift = (i % BOWLING_SAVED_GAME_PIN_GROUP_SIZE) * 4;
            pins.add((packed >> shift) & 0x0f);
        }

        return pins;
    }
}
