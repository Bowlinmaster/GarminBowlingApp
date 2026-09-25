import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;

const BOWLING_SAVED_GAMES_STORAGE_KEY = "games.v2";
const BOWLING_SAVED_GAMES_META_KEY = "games.meta.v6";
const BOWLING_SAVED_GAMES_PAGE_KEY_PREFIX = "games.page.v6.";
const BOWLING_SAVED_GAMES_FORMAT_VERSION = 6;
const BOWLING_SAVED_GAMES_VERSION_FIVE = 5;
const BOWLING_SAVED_GAMES_PREVIOUS_FORMAT_VERSION = 4;
const BOWLING_SAVED_GAMES_OLDER_FORMAT_VERSION = 3;
const BOWLING_SAVED_GAMES_LEGACY_FORMAT_VERSION = 2;
const BOWLING_SAVED_GAMES_LEGACY_HEADER_SIZE = 2;
const BOWLING_SAVED_GAMES_PREVIOUS_HEADER_SIZE = 14;
const BOWLING_SAVED_GAMES_OLDER_HEADER_SIZE = 10;
const BOWLING_SAVED_GAMES_VERSION_FIVE_HEADER_SIZE = 20;
const BOWLING_SAVED_GAMES_HEADER_SIZE = 23;
const BOWLING_SAVED_GAME_RECORD_SIZE = 6;
const BOWLING_SAVED_GAME_BYTE_RECORD_SIZE = 20;
const BOWLING_SAVED_GAMES_PAGE_SIZE = 20;
const BOWLING_SAVED_GAMES_MAX_COUNT = 500;
const BOWLING_SAVED_GAME_PIN_GROUP_SIZE = 7;
const BOWLING_SAVED_GAME_PIN_GROUP_COUNT = 3;
const BOWLING_SAVED_GAME_SERIES_GAP_SECONDS = 7200;
const BOWLING_SAVED_GAME_TIMESTAMP_EPOCH = 1577836800;

const BOWLING_SAVED_GAME_SAVED_AT = "t";
const BOWLING_SAVED_GAME_SCORE = "s";
const BOWLING_SAVED_GAME_ROLL_COUNT = "n";
const BOWLING_SAVED_GAME_PIN_COUNTS = "p";
const BOWLING_SAVED_GAME_MODEL = "g";
const BOWLING_SAVED_SERIES_START_INDEX = "i";
const BOWLING_SAVED_SERIES_GAME_COUNT = "n";
const BOWLING_SAVED_SERIES_STARTED_AT = "t";
const BOWLING_SAVED_SERIES_TOTAL_SCORE = "s";

const BOWLING_SAVED_GAMES_COUNT_INDEX = 1;
const BOWLING_SAVED_GAMES_OLDEST_SEQUENCE_INDEX = 2;
const BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX = 3;
const BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX = 4;
const BOWLING_SAVED_GAMES_TOTAL_SCORE_INDEX = 5;
const BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX = 6;
const BOWLING_SAVED_GAMES_FIRST_BALL_PINS_INDEX = 7;
const BOWLING_SAVED_GAMES_STRIKES_INDEX = 8;
const BOWLING_SAVED_GAMES_SPARE_ATTEMPTS_INDEX = 9;
const BOWLING_SAVED_GAMES_SPARES_INDEX = 10;
const BOWLING_SAVED_GAMES_OPEN_FRAMES_INDEX = 11;
const BOWLING_SAVED_GAMES_SERIES_COUNT_INDEX = 12;
const BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX = 13;
const BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX = 14;
const BOWLING_SAVED_GAMES_ACTIVE_SERIES_GAMES_INDEX = 15;
const BOWLING_SAVED_GAMES_LOW_SCORE_INDEX = 16;
const BOWLING_SAVED_GAMES_SINGLE_PIN_ATTEMPTS_INDEX = 17;
const BOWLING_SAVED_GAMES_SINGLE_PIN_SPARES_INDEX = 18;
const BOWLING_SAVED_GAMES_MULTI_PIN_ATTEMPTS_INDEX = 19;
const BOWLING_SAVED_GAMES_MULTI_PIN_SPARES_INDEX = 20;
const BOWLING_SAVED_GAMES_CLEAN_FRAMES_INDEX = 21;
const BOWLING_SAVED_GAMES_LAST_SAVED_AT_INDEX = 22;

class BowlingSavedGameStore {
    // Metadata remains fixed-size. Detailed games live in 20-game byte pages so
    // reading or saving one game never loads the complete history.
    static function saveGame(game as BowlingGame) as Boolean {
        return saveGameAt(game, Time.now().value());
    }

    static function saveGameAt(game as BowlingGame, savedAtSeconds as Number) as Boolean {
        if (game == null || !game.isGameComplete() || !canEncodeTimestamp(savedAtSeconds)) {
            return false;
        }
        try {
            var metadata = getMetadata();
            var sequence = metadata[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] as Number;
            if (!writeRecordAtSequence(sequence, encodeByteRecord(game, savedAtSeconds))) {
                return false;
            }

            var updated = metadata.slice(0, metadata.size()) as Lang.Array;
            var previousOldest = updated[BOWLING_SAVED_GAMES_OLDEST_SEQUENCE_INDEX] as Number;
            var retainedCount = updated[BOWLING_SAVED_GAMES_COUNT_INDEX] as Number;
            if (retainedCount < BOWLING_SAVED_GAMES_MAX_COUNT) {
                updated[BOWLING_SAVED_GAMES_COUNT_INDEX] = retainedCount + 1;
            } else {
                updated[BOWLING_SAVED_GAMES_OLDEST_SEQUENCE_INDEX] = previousOldest + 1;
            }
            updated[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] = sequence + 1;
            addGameStatisticsToMetadata(updated, game);
            addGameToSeriesMetadata(updated, game.getScore(), savedAtSeconds,
                metadata[BOWLING_SAVED_GAMES_LAST_SAVED_AT_INDEX] as Number);
            updated[BOWLING_SAVED_GAMES_LAST_SAVED_AT_INDEX] = savedAtSeconds;
            Application.Storage.setValue(BOWLING_SAVED_GAMES_META_KEY, updated);

            var newOldest = updated[BOWLING_SAVED_GAMES_OLDEST_SEQUENCE_INDEX] as Number;
            if (newOldest > previousOldest &&
                (newOldest / BOWLING_SAVED_GAMES_PAGE_SIZE) > (previousOldest / BOWLING_SAVED_GAMES_PAGE_SIZE)) {
                Application.Storage.deleteValue(pageKey(previousOldest / BOWLING_SAVED_GAMES_PAGE_SIZE));
            }
            return true;
        } catch (ex) {
            return false;
        }
    }

    static function getSavedGame(index as Number) as Lang.Dictionary or Null {
        if (index < 0) {
            return null;
        }
        var metadata = getMetadata();
        var count = getMetadataCount(metadata);
        while (index < count) {
            var record = getRecordAtIndex(metadata, index);
            var decoded = record == null ? null : decodeByteRecord(record as Lang.ByteArray);
            if (decoded != null) {
                return decoded;
            }
            if (!removeCorruptRecord(metadata, index)) {
                return null;
            }
            metadata = getMetadata();
            count = getMetadataCount(metadata);
        }
        return null;
    }

    static function getSavedGameSummary(index as Number) as Lang.Dictionary or Null {
        if (index < 0) {
            return null;
        }
        var metadata = getMetadata();
        var count = getMetadataCount(metadata);
        while (index < count) {
            var record = getRecordAtIndex(metadata, index);
            var summary = record == null ? null : decodeByteSummary(record as Lang.ByteArray);
            if (summary != null) {
                return summary;
            }
            if (!removeCorruptRecord(metadata, index)) {
                return null;
            }
            metadata = getMetadata();
            count = getMetadataCount(metadata);
        }
        return null;
    }

    static function getSavedGameCount() as Number {
        return getMetadataCount(getMetadata());
    }

    static function getAggregateStatistics() as Lang.Dictionary {
        var metadata = getMetadata();
        var gameCount = metadata[BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX] as Number;
        return {
            BOWLING_STAT_GAME_COUNT => gameCount,
            BOWLING_STAT_TOTAL_SCORE => metadata[BOWLING_SAVED_GAMES_TOTAL_SCORE_INDEX],
            BOWLING_STAT_HIGH_SCORE => metadata[BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX],
            BOWLING_STAT_LOW_SCORE => metadata[BOWLING_SAVED_GAMES_LOW_SCORE_INDEX],
            BOWLING_STAT_FIRST_BALL_PINS => metadata[BOWLING_SAVED_GAMES_FIRST_BALL_PINS_INDEX],
            BOWLING_STAT_FIRST_BALL_ATTEMPTS => gameCount * 10,
            BOWLING_STAT_STRIKES => metadata[BOWLING_SAVED_GAMES_STRIKES_INDEX],
            BOWLING_STAT_STRIKE_ATTEMPTS => gameCount * 10,
            BOWLING_STAT_SPARE_ATTEMPTS => metadata[BOWLING_SAVED_GAMES_SPARE_ATTEMPTS_INDEX],
            BOWLING_STAT_SPARES => metadata[BOWLING_SAVED_GAMES_SPARES_INDEX],
            BOWLING_STAT_OPEN_FRAMES => metadata[BOWLING_SAVED_GAMES_OPEN_FRAMES_INDEX],
            BOWLING_STAT_SINGLE_PIN_ATTEMPTS => metadata[BOWLING_SAVED_GAMES_SINGLE_PIN_ATTEMPTS_INDEX],
            BOWLING_STAT_SINGLE_PIN_SPARES => metadata[BOWLING_SAVED_GAMES_SINGLE_PIN_SPARES_INDEX],
            BOWLING_STAT_MULTI_PIN_ATTEMPTS => metadata[BOWLING_SAVED_GAMES_MULTI_PIN_ATTEMPTS_INDEX],
            BOWLING_STAT_MULTI_PIN_SPARES => metadata[BOWLING_SAVED_GAMES_MULTI_PIN_SPARES_INDEX],
            BOWLING_STAT_CLEAN_FRAMES => metadata[BOWLING_SAVED_GAMES_CLEAN_FRAMES_INDEX],
            BOWLING_STAT_SERIES_COUNT => metadata[BOWLING_SAVED_GAMES_SERIES_COUNT_INDEX],
            BOWLING_STAT_HIGH_SERIES => metadata[BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX]
        };
    }

    static function getSavedSeriesCount() as Number {
        var metadata = getMetadata();
        var gameCount = getMetadataCount(metadata);
        var seriesCount = 0;
        var previousSavedAt = null;
        var loadedPageId = -1;
        var page = null;
        for (var index = 0; index < gameCount; index++) {
            var sequence = sequenceForIndex(metadata, index);
            var pageId = sequence / BOWLING_SAVED_GAMES_PAGE_SIZE;
            if (pageId != loadedPageId) {
                page = getPage(pageId);
                loadedPageId = pageId;
            }
            var summary = page == null ? null : decodeSummaryFromPage(page as Lang.ByteArray,
                sequence % BOWLING_SAVED_GAMES_PAGE_SIZE);
            if (summary == null) {
                continue;
            }
            var savedAt = summary[BOWLING_SAVED_GAME_SAVED_AT] as Number;
            if (previousSavedAt == null || !areGamesInSameSeries(previousSavedAt, savedAt)) {
                seriesCount += 1;
            }
            previousSavedAt = savedAt;
        }
        return seriesCount;
    }

    static function getSavedSeriesSummary(seriesIndex as Number) as Lang.Dictionary or Null {
        if (seriesIndex < 0) {
            return null;
        }
        var metadata = getMetadata();
        var gameCount = getMetadataCount(metadata);
        var currentSeries = -1;
        var previousSavedAt = null;
        var startIndex = 0;
        var gamesInSeries = 0;
        var startedAt = 0;
        var totalScore = 0;
        var loadedPageId = -1;
        var page = null;
        for (var index = 0; index < gameCount; index++) {
            var sequence = sequenceForIndex(metadata, index);
            var pageId = sequence / BOWLING_SAVED_GAMES_PAGE_SIZE;
            if (pageId != loadedPageId) {
                page = getPage(pageId);
                loadedPageId = pageId;
            }
            var summary = page == null ? null : decodeSummaryFromPage(page as Lang.ByteArray,
                sequence % BOWLING_SAVED_GAMES_PAGE_SIZE);
            if (summary == null) {
                continue;
            }
            var savedAt = summary[BOWLING_SAVED_GAME_SAVED_AT] as Number;
            if (previousSavedAt == null || !areGamesInSameSeries(previousSavedAt, savedAt)) {
                if (currentSeries == seriesIndex) {
                    return buildSeriesSummary(startIndex, gamesInSeries, startedAt, totalScore);
                }
                currentSeries += 1;
                startIndex = index;
                gamesInSeries = 0;
                totalScore = 0;
            }
            if (currentSeries == seriesIndex) {
                gamesInSeries += 1;
                startedAt = savedAt;
                totalScore += summary[BOWLING_SAVED_GAME_SCORE] as Number;
            }
            previousSavedAt = savedAt;
        }
        return currentSeries == seriesIndex && gamesInSeries > 0
            ? buildSeriesSummary(startIndex, gamesInSeries, startedAt, totalScore) : null;
    }

    static function getSavedSeriesStatistics(seriesSummary as Lang.Dictionary) as Lang.Dictionary {
        var startIndex = seriesSummary[BOWLING_SAVED_SERIES_START_INDEX] as Number;
        var requestedCount = seriesSummary[BOWLING_SAVED_SERIES_GAME_COUNT] as Number;
        var metadata = getMetadata();
        var storedCount = getMetadataCount(metadata);
        var validGames = 0;
        var totalScore = 0;
        var highScore = 0;
        var lowScore = 0;
        var firstBallPins = 0;
        var strikes = 0;
        var spareAttempts = 0;
        var spares = 0;
        var openFrames = 0;
        var singlePinAttempts = 0;
        var singlePinSpares = 0;
        for (var offset = 0; offset < requestedCount && startIndex + offset < storedCount; offset++) {
            var record = getRecordAtIndex(metadata, startIndex + offset);
            if (record == null) {
                continue;
            }
            var packedStatistics = getByteRecordStatistics(record as Lang.ByteArray);
            if (packedStatistics == null) {
                continue;
            }
            var score = readUInt16(record as Lang.ByteArray, 4);
            validGames += 1;
            totalScore += score;
            highScore = score > highScore ? score : highScore;
            lowScore = validGames == 1 || score < lowScore ? score : lowScore;
            firstBallPins += packedStatistics & 0x7f;
            strikes += (packedStatistics >> 7) & 0x0f;
            spareAttempts += (packedStatistics >> 11) & 0x0f;
            spares += (packedStatistics >> 15) & 0x0f;
            openFrames += (packedStatistics >> 19) & 0x0f;
            singlePinAttempts += (packedStatistics >> 23) & 0x0f;
            singlePinSpares += (packedStatistics >> 27) & 0x0f;
        }
        return {
            BOWLING_STAT_GAME_COUNT => validGames,
            BOWLING_STAT_TOTAL_SCORE => totalScore,
            BOWLING_STAT_HIGH_SCORE => highScore,
            BOWLING_STAT_LOW_SCORE => lowScore,
            BOWLING_STAT_FIRST_BALL_PINS => firstBallPins,
            BOWLING_STAT_FIRST_BALL_ATTEMPTS => validGames * 10,
            BOWLING_STAT_STRIKES => strikes,
            BOWLING_STAT_STRIKE_ATTEMPTS => validGames * 10,
            BOWLING_STAT_SPARE_ATTEMPTS => spareAttempts,
            BOWLING_STAT_SPARES => spares,
            BOWLING_STAT_OPEN_FRAMES => openFrames,
            BOWLING_STAT_SINGLE_PIN_ATTEMPTS => singlePinAttempts,
            BOWLING_STAT_SINGLE_PIN_SPARES => singlePinSpares,
            BOWLING_STAT_MULTI_PIN_ATTEMPTS => spareAttempts - singlePinAttempts,
            BOWLING_STAT_MULTI_PIN_SPARES => spares - singlePinSpares,
            BOWLING_STAT_CLEAN_FRAMES => (validGames * 10) - openFrames
        };
    }

    static function clearSavedGames() as Void {
        try {
            var stored = Application.Storage.getValue(BOWLING_SAVED_GAMES_META_KEY);
            if (stored instanceof Lang.Array && hasValidMetadata(stored as Lang.Array)) {
                var metadata = stored as Lang.Array;
                var firstPage = (metadata[BOWLING_SAVED_GAMES_OLDEST_SEQUENCE_INDEX] as Number) /
                    BOWLING_SAVED_GAMES_PAGE_SIZE;
                var lastPage = (metadata[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] as Number) /
                    BOWLING_SAVED_GAMES_PAGE_SIZE;
                for (var pageId = firstPage; pageId <= lastPage; pageId++) {
                    Application.Storage.deleteValue(pageKey(pageId));
                }
            } else {
                Application.Storage.deleteValue(pageKey(0));
            }
        } catch (ex) {
        }
        Application.Storage.deleteValue(BOWLING_SAVED_GAMES_META_KEY);
        Application.Storage.deleteValue(BOWLING_SAVED_GAMES_STORAGE_KEY);
    }

    // The legacy representation remains available for migration validation.
    static function buildRecord(game as BowlingGame, savedAtSeconds as Number) as Lang.Array {
        var record = [savedAtSeconds, game.getScore(), game.getRecordedRollCount()] as Lang.Array;
        for (var group = 0; group < BOWLING_SAVED_GAME_PIN_GROUP_COUNT; group++) {
            record.add(packPinGroup(game, game.getRecordedRollCount(), group * BOWLING_SAVED_GAME_PIN_GROUP_SIZE));
        }
        return record;
    }

    static function decodeRecord(values as Lang.Array, offset as Number) as Lang.Dictionary or Null {
        try {
            if (offset < 0 || offset + BOWLING_SAVED_GAME_RECORD_SIZE > values.size()) {
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

    private static function getMetadata() as Lang.Array {
        try {
            var stored = Application.Storage.getValue(BOWLING_SAVED_GAMES_META_KEY);
            if (stored instanceof Lang.Array && hasValidMetadata(stored as Lang.Array)) {
                return stored as Lang.Array;
            }
        } catch (ex) {
        }
        return migrateLegacyStore();
    }

    private static function migrateLegacyStore() as Lang.Array {
        var legacy;
        try {
            legacy = Application.Storage.getValue(BOWLING_SAVED_GAMES_STORAGE_KEY);
        } catch (ex) {
            return emptyMetadata();
        }
        if (!(legacy instanceof Lang.Array) || legacy.size() < 2 || !(legacy[0] instanceof Number)) {
            return emptyMetadata();
        }

        var version = legacy[0] as Number;
        var sourceHeaderSize = legacyHeaderSize(version);
        if (sourceHeaderSize == 0 || legacy.size() < sourceHeaderSize || !(legacy[1] instanceof Number)) {
            return emptyMetadata();
        }
        var declaredCount = legacy[1] as Number;
        var availableCount = (legacy.size() - sourceHeaderSize) / BOWLING_SAVED_GAME_RECORD_SIZE;
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

        var metadata = emptyMetadata();
        var page = []b;
        var sequence = 0;
        var previousSavedAt = 0;
        try {
            // Legacy records are newest-first. Write them oldest-first so sequence
            // numbers can grow by appending after migration.
            for (var index = count - 1; index >= 0; index--) {
                var offset = sourceHeaderSize + (index * BOWLING_SAVED_GAME_RECORD_SIZE);
                var decoded = decodeRecord(legacy as Lang.Array, offset);
                if (decoded == null) {
                    continue;
                }
                var game = decoded[BOWLING_SAVED_GAME_MODEL] as BowlingGame;
                var savedAt = decoded[BOWLING_SAVED_GAME_SAVED_AT] as Number;
                if (!canEncodeTimestamp(savedAt)) {
                    continue;
                }
                if ((sequence % BOWLING_SAVED_GAMES_PAGE_SIZE) == 0) {
                    page = []b;
                }
                page.addAll(encodeByteRecord(game, savedAt));
                sequence += 1;
                addGameStatisticsToMetadata(metadata, game);
                addGameToSeriesMetadata(metadata, game.getScore(), savedAt, previousSavedAt);
                previousSavedAt = savedAt;
                if ((sequence % BOWLING_SAVED_GAMES_PAGE_SIZE) == 0) {
                    Application.Storage.setValue(pageKey((sequence - 1) / BOWLING_SAVED_GAMES_PAGE_SIZE), page);
                }
            }
            if ((sequence % BOWLING_SAVED_GAMES_PAGE_SIZE) != 0) {
                Application.Storage.setValue(pageKey((sequence - 1) / BOWLING_SAVED_GAMES_PAGE_SIZE), page);
            }

            metadata[BOWLING_SAVED_GAMES_COUNT_INDEX] = sequence;
            metadata[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] = sequence;
            metadata[BOWLING_SAVED_GAMES_LAST_SAVED_AT_INDEX] = previousSavedAt;
            if (version == BOWLING_SAVED_GAMES_VERSION_FIVE &&
                canPreserveVersionFiveHeader(legacy as Lang.Array, declaredCount)) {
                copyVersionFiveLifetimeHeader(legacy as Lang.Array, metadata);
            }
            Application.Storage.setValue(BOWLING_SAVED_GAMES_META_KEY, metadata);
            Application.Storage.deleteValue(BOWLING_SAVED_GAMES_STORAGE_KEY);
            return metadata;
        } catch (ex) {
            for (var pageId = 0; pageId <= sequence / BOWLING_SAVED_GAMES_PAGE_SIZE; pageId++) {
                Application.Storage.deleteValue(pageKey(pageId));
            }
            return emptyMetadata();
        }
    }

    private static function legacyHeaderSize(version as Number) as Number {
        if (version == BOWLING_SAVED_GAMES_LEGACY_FORMAT_VERSION) {
            return BOWLING_SAVED_GAMES_LEGACY_HEADER_SIZE;
        }
        if (version == BOWLING_SAVED_GAMES_OLDER_FORMAT_VERSION) {
            return BOWLING_SAVED_GAMES_OLDER_HEADER_SIZE;
        }
        if (version == BOWLING_SAVED_GAMES_PREVIOUS_FORMAT_VERSION) {
            return BOWLING_SAVED_GAMES_PREVIOUS_HEADER_SIZE;
        }
        return version == BOWLING_SAVED_GAMES_VERSION_FIVE
            ? BOWLING_SAVED_GAMES_VERSION_FIVE_HEADER_SIZE : 0;
    }

    private static function canPreserveVersionFiveHeader(values as Lang.Array, retainedCount as Number) as Boolean {
        if (values.size() < BOWLING_SAVED_GAMES_VERSION_FIVE_HEADER_SIZE || retainedCount < 0) {
            return false;
        }
        for (var index = 1; index < BOWLING_SAVED_GAMES_VERSION_FIVE_HEADER_SIZE; index++) {
            if (!(values[index] instanceof Number) || values[index] < 0) {
                return false;
            }
        }
        return values[2] >= retainedCount && values[4] <= 300 && values[14] <= values[4];
    }

    private static function copyVersionFiveLifetimeHeader(source as Lang.Array, target as Lang.Array) as Void {
        for (var oldIndex = 2; oldIndex < BOWLING_SAVED_GAMES_VERSION_FIVE_HEADER_SIZE; oldIndex++) {
            target[oldIndex + 2] = source[oldIndex];
        }
    }

    private static function emptyMetadata() as Lang.Array {
        return [BOWLING_SAVED_GAMES_FORMAT_VERSION, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    }

    private static function hasValidMetadata(values as Lang.Array) as Boolean {
        if (values.size() < BOWLING_SAVED_GAMES_HEADER_SIZE || values[0] != BOWLING_SAVED_GAMES_FORMAT_VERSION) {
            return false;
        }
        for (var index = 1; index < BOWLING_SAVED_GAMES_HEADER_SIZE; index++) {
            if (!(values[index] instanceof Number) || values[index] < 0) {
                return false;
            }
        }
        var savedCount = values[BOWLING_SAVED_GAMES_COUNT_INDEX] as Number;
        var oldest = values[BOWLING_SAVED_GAMES_OLDEST_SEQUENCE_INDEX] as Number;
        var next = values[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] as Number;
        var gameCount = values[BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX] as Number;
        var totalScore = values[BOWLING_SAVED_GAMES_TOTAL_SCORE_INDEX] as Number;
        var highScore = values[BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX] as Number;
        var lowScore = values[BOWLING_SAVED_GAMES_LOW_SCORE_INDEX] as Number;
        var firstBallPins = values[BOWLING_SAVED_GAMES_FIRST_BALL_PINS_INDEX] as Number;
        var strikes = values[BOWLING_SAVED_GAMES_STRIKES_INDEX] as Number;
        var spareAttempts = values[BOWLING_SAVED_GAMES_SPARE_ATTEMPTS_INDEX] as Number;
        var spares = values[BOWLING_SAVED_GAMES_SPARES_INDEX] as Number;
        var openFrames = values[BOWLING_SAVED_GAMES_OPEN_FRAMES_INDEX] as Number;
        var singlePinAttempts = values[BOWLING_SAVED_GAMES_SINGLE_PIN_ATTEMPTS_INDEX] as Number;
        var singlePinSpares = values[BOWLING_SAVED_GAMES_SINGLE_PIN_SPARES_INDEX] as Number;
        var multiPinAttempts = values[BOWLING_SAVED_GAMES_MULTI_PIN_ATTEMPTS_INDEX] as Number;
        var multiPinSpares = values[BOWLING_SAVED_GAMES_MULTI_PIN_SPARES_INDEX] as Number;
        var cleanFrames = values[BOWLING_SAVED_GAMES_CLEAN_FRAMES_INDEX] as Number;
        return savedCount <= BOWLING_SAVED_GAMES_MAX_COUNT && next >= oldest && next - oldest == savedCount &&
            gameCount >= savedCount && totalScore <= gameCount * 300 && highScore <= 300 && lowScore <= highScore &&
            firstBallPins <= gameCount * 100 && strikes <= gameCount * 10 && spareAttempts <= gameCount * 10 &&
            spares <= spareAttempts && openFrames <= spareAttempts && strikes + spareAttempts == gameCount * 10 &&
            spares + openFrames == spareAttempts && singlePinAttempts + multiPinAttempts == spareAttempts &&
            singlePinSpares <= singlePinAttempts && multiPinSpares <= multiPinAttempts &&
            singlePinSpares + multiPinSpares == spares && cleanFrames + openFrames == gameCount * 10;
    }

    private static function getMetadataCount(metadata as Lang.Array) as Number {
        return hasValidMetadata(metadata) ? metadata[BOWLING_SAVED_GAMES_COUNT_INDEX] as Number : 0;
    }

    private static function pageKey(pageId as Number) as String {
        return BOWLING_SAVED_GAMES_PAGE_KEY_PREFIX + pageId.toString();
    }

    private static function getPage(pageId as Number) as Lang.ByteArray or Null {
        try {
            var stored = Application.Storage.getValue(pageKey(pageId));
            if (stored instanceof Lang.ByteArray &&
                stored.size() <= BOWLING_SAVED_GAMES_PAGE_SIZE * BOWLING_SAVED_GAME_BYTE_RECORD_SIZE &&
                (stored.size() % BOWLING_SAVED_GAME_BYTE_RECORD_SIZE) == 0) {
                return stored as Lang.ByteArray;
            }
        } catch (ex) {
        }
        return null;
    }

    private static function writeRecordAtSequence(sequence as Number, record as Lang.ByteArray) as Boolean {
        if (record.size() != BOWLING_SAVED_GAME_BYTE_RECORD_SIZE) {
            return false;
        }
        var pageId = sequence / BOWLING_SAVED_GAMES_PAGE_SIZE;
        var offset = (sequence % BOWLING_SAVED_GAMES_PAGE_SIZE) * BOWLING_SAVED_GAME_BYTE_RECORD_SIZE;
        var page = getPage(pageId);
        if (page == null) {
            if (offset != 0) {
                return false;
            }
            page = []b;
        }
        if (page.size() < offset ||
            (page.size() > offset && page.size() < offset + BOWLING_SAVED_GAME_BYTE_RECORD_SIZE)) {
            return false;
        }
        if (page.size() == offset) {
            page.addAll(record);
        } else {
            for (var index = 0; index < record.size(); index++) {
                page[offset + index] = record[index];
            }
        }
        Application.Storage.setValue(pageKey(pageId), page);
        return true;
    }

    private static function sequenceForIndex(metadata as Lang.Array, index as Number) as Number {
        return (metadata[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] as Number) - 1 - index;
    }

    private static function getRecordAtIndex(metadata as Lang.Array, index as Number) as Lang.ByteArray or Null {
        return index < 0 || index >= getMetadataCount(metadata)
            ? null : getRecordAtSequence(sequenceForIndex(metadata, index));
    }

    private static function getRecordAtSequence(sequence as Number) as Lang.ByteArray or Null {
        var page = getPage(sequence / BOWLING_SAVED_GAMES_PAGE_SIZE);
        if (page == null) {
            return null;
        }
        var offset = (sequence % BOWLING_SAVED_GAMES_PAGE_SIZE) * BOWLING_SAVED_GAME_BYTE_RECORD_SIZE;
        return offset + BOWLING_SAVED_GAME_BYTE_RECORD_SIZE > page.size()
            ? null : page.slice(offset, offset + BOWLING_SAVED_GAME_BYTE_RECORD_SIZE) as Lang.ByteArray;
    }

    private static function decodeSummaryFromPage(page as Lang.ByteArray, slot as Number) as Lang.Dictionary or Null {
        var offset = slot * BOWLING_SAVED_GAME_BYTE_RECORD_SIZE;
        return offset + BOWLING_SAVED_GAME_BYTE_RECORD_SIZE > page.size() ? null :
            decodeByteSummary(page.slice(offset, offset + BOWLING_SAVED_GAME_BYTE_RECORD_SIZE) as Lang.ByteArray);
    }

    private static function removeCorruptRecord(metadata as Lang.Array, index as Number) as Boolean {
        try {
            var targetSequence = sequenceForIndex(metadata, index);
            var oldNext = metadata[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] as Number;
            for (var sequence = targetSequence; sequence < oldNext - 1; sequence++) {
                var replacement = getRecordAtSequence(sequence + 1);
                if (replacement == null || !writeRecordAtSequence(sequence, replacement as Lang.ByteArray)) {
                    return false;
                }
            }
            var updated = metadata.slice(0, metadata.size()) as Lang.Array;
            updated[BOWLING_SAVED_GAMES_COUNT_INDEX] -= 1;
            updated[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] -= 1;
            if (updated[BOWLING_SAVED_GAMES_COUNT_INDEX] == 0) {
                updated[BOWLING_SAVED_GAMES_OLDEST_SEQUENCE_INDEX] =
                    updated[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX];
            }
            Application.Storage.setValue(BOWLING_SAVED_GAMES_META_KEY, updated);
            var oldLastPage = (oldNext - 1) / BOWLING_SAVED_GAMES_PAGE_SIZE;
            var newNext = updated[BOWLING_SAVED_GAMES_NEXT_SEQUENCE_INDEX] as Number;
            if (newNext == 0 || oldLastPage > ((newNext - 1) / BOWLING_SAVED_GAMES_PAGE_SIZE)) {
                Application.Storage.deleteValue(pageKey(oldLastPage));
            }
            return true;
        } catch (ex) {
            return false;
        }
    }

    private static function encodeByteRecord(game as BowlingGame, savedAtSeconds as Number) as Lang.ByteArray {
        var record = []b;
        writeUInt32(record, savedAtSeconds - BOWLING_SAVED_GAME_TIMESTAMP_EPOCH);
        writeUInt16(record, game.getScore());
        record.add(game.getRecordedRollCount());
        record.add(0);
        for (var group = 0; group < BOWLING_SAVED_GAME_PIN_GROUP_COUNT; group++) {
            writeUInt32(record, packPinGroup(game, game.getRecordedRollCount(),
                group * BOWLING_SAVED_GAME_PIN_GROUP_SIZE));
        }
        return record;
    }

    private static function decodeByteSummary(record as Lang.ByteArray) as Lang.Dictionary or Null {
        if (!hasValidByteRecordMetadata(record)) {
            return null;
        }
        return {
            BOWLING_SAVED_GAME_SAVED_AT => readUInt32(record, 0) + BOWLING_SAVED_GAME_TIMESTAMP_EPOCH,
            BOWLING_SAVED_GAME_SCORE => readUInt16(record, 4)
        };
    }

    private static function decodeByteRecord(record as Lang.ByteArray) as Lang.Dictionary or Null {
        if (!hasValidByteRecordMetadata(record)) {
            return null;
        }
        var savedAt = readUInt32(record, 0) + BOWLING_SAVED_GAME_TIMESTAMP_EPOCH;
        var score = readUInt16(record, 4);
        var rollCount = record[6];
        var pins = unpackBytePins(record, rollCount);
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
    }

    private static function hasValidByteRecordMetadata(record as Lang.ByteArray) as Boolean {
        if (record.size() != BOWLING_SAVED_GAME_BYTE_RECORD_SIZE || record[7] != 0) {
            return false;
        }
        var score = readUInt16(record, 4);
        var rollCount = record[6];
        if (score > 300 || rollCount < 11 || rollCount > 21) {
            return false;
        }
        for (var group = 0; group < BOWLING_SAVED_GAME_PIN_GROUP_COUNT; group++) {
            if (readUInt32(record, 8 + (group * 4)) > 0x0fffffff) {
                return false;
            }
        }
        for (var index = rollCount;
            index < BOWLING_SAVED_GAME_PIN_GROUP_SIZE * BOWLING_SAVED_GAME_PIN_GROUP_COUNT;
            index++) {
            if (getBytePackedPinsAt(record, index) != 0) {
                return false;
            }
        }
        return true;
    }

    private static function getByteRecordStatistics(record as Lang.ByteArray) as Number or Null {
        if (!hasValidByteRecordMetadata(record)) {
            return null;
        }
        var rollCount = record[6];
        var rollIndex = 0;
        var firstBallPins = 0;
        var strikes = 0;
        var spareAttempts = 0;
        var spares = 0;
        var openFrames = 0;
        var singlePinAttempts = 0;
        var singlePinSpares = 0;
        for (var frameIndex = 0; frameIndex < 10; frameIndex++) {
            if (rollIndex >= rollCount) {
                return null;
            }
            var firstBall = getBytePackedPinsAt(record, rollIndex);
            if (firstBall > 10) {
                return null;
            }
            firstBallPins += firstBall;
            if (firstBall == 10) {
                strikes += 1;
                rollIndex += 1;
            } else {
                if (rollIndex + 1 >= rollCount) {
                    return null;
                }
                var secondBall = getBytePackedPinsAt(record, rollIndex + 1);
                if (secondBall > 10 - firstBall) {
                    return null;
                }
                spareAttempts += 1;
                var isSinglePin = firstBall == 9;
                if (isSinglePin) {
                    singlePinAttempts += 1;
                }
                if (firstBall + secondBall == 10) {
                    spares += 1;
                    if (isSinglePin) {
                        singlePinSpares += 1;
                    }
                } else {
                    openFrames += 1;
                }
                rollIndex += 2;
            }
        }
        return firstBallPins | (strikes << 7) | (spareAttempts << 11) | (spares << 15) |
            (openFrames << 19) | (singlePinAttempts << 23) | (singlePinSpares << 27);
    }

    private static function getBytePackedPinsAt(record as Lang.ByteArray, rollIndex as Number) as Number {
        var packed = readUInt32(record,
            8 + ((rollIndex / BOWLING_SAVED_GAME_PIN_GROUP_SIZE) * 4));
        return (packed >> ((rollIndex % BOWLING_SAVED_GAME_PIN_GROUP_SIZE) * 4)) & 0x0f;
    }

    private static function unpackBytePins(record as Lang.ByteArray, rollCount as Number) as Array<Number> {
        var pins = [] as Array<Number>;
        for (var index = 0; index < rollCount; index++) {
            pins.add(getBytePackedPinsAt(record, index));
        }
        return pins;
    }

    private static function writeUInt16(bytes as Lang.ByteArray, value as Number) as Void {
        bytes.add(value & 0xff);
        bytes.add((value >> 8) & 0xff);
    }

    private static function writeUInt32(bytes as Lang.ByteArray, value as Number) as Void {
        bytes.add(value & 0xff);
        bytes.add((value >> 8) & 0xff);
        bytes.add((value >> 16) & 0xff);
        bytes.add((value >> 24) & 0xff);
    }

    private static function readUInt16(bytes as Lang.ByteArray, offset as Number) as Number {
        return bytes[offset] | (bytes[offset + 1] << 8);
    }

    private static function readUInt32(bytes as Lang.ByteArray, offset as Number) as Number {
        return bytes[offset] | (bytes[offset + 1] << 8) |
            (bytes[offset + 2] << 16) | (bytes[offset + 3] << 24);
    }

    private static function canEncodeTimestamp(savedAtSeconds) as Boolean {
        return savedAtSeconds instanceof Number && savedAtSeconds >= BOWLING_SAVED_GAME_TIMESTAMP_EPOCH &&
            savedAtSeconds - BOWLING_SAVED_GAME_TIMESTAMP_EPOCH <= 0x7fffffff;
    }

    private static function addGameStatisticsToMetadata(values as Lang.Array, game as BowlingGame) as Void {
        var score = game.getScore();
        values[BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX] += 1;
        values[BOWLING_SAVED_GAMES_TOTAL_SCORE_INDEX] += score;
        if (score > values[BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX]) {
            values[BOWLING_SAVED_GAMES_HIGH_SCORE_INDEX] = score;
        }
        if (values[BOWLING_SAVED_GAMES_LIFETIME_COUNT_INDEX] == 1 ||
            score < values[BOWLING_SAVED_GAMES_LOW_SCORE_INDEX]) {
            values[BOWLING_SAVED_GAMES_LOW_SCORE_INDEX] = score;
        }
        for (var frameIndex = 0; frameIndex < 10; frameIndex++) {
            var frame = game.getFrame(frameIndex);
            var firstBall = frame.getPinsAt(0) as Number;
            values[BOWLING_SAVED_GAMES_FIRST_BALL_PINS_INDEX] += firstBall;
            if (frame.isStrike()) {
                values[BOWLING_SAVED_GAMES_STRIKES_INDEX] += 1;
                values[BOWLING_SAVED_GAMES_CLEAN_FRAMES_INDEX] += 1;
                continue;
            }
            values[BOWLING_SAVED_GAMES_SPARE_ATTEMPTS_INDEX] += 1;
            var isSinglePin = firstBall == 9;
            if (isSinglePin) {
                values[BOWLING_SAVED_GAMES_SINGLE_PIN_ATTEMPTS_INDEX] += 1;
            } else {
                values[BOWLING_SAVED_GAMES_MULTI_PIN_ATTEMPTS_INDEX] += 1;
            }
            if (frame.isSpare()) {
                values[BOWLING_SAVED_GAMES_SPARES_INDEX] += 1;
                values[BOWLING_SAVED_GAMES_CLEAN_FRAMES_INDEX] += 1;
                if (isSinglePin) {
                    values[BOWLING_SAVED_GAMES_SINGLE_PIN_SPARES_INDEX] += 1;
                } else {
                    values[BOWLING_SAVED_GAMES_MULTI_PIN_SPARES_INDEX] += 1;
                }
            } else {
                values[BOWLING_SAVED_GAMES_OPEN_FRAMES_INDEX] += 1;
            }
        }
    }

    private static function addGameToSeriesMetadata(values as Lang.Array, score as Number,
        savedAt as Number, previousSavedAt as Number) as Void {
        var sameSeries = previousSavedAt > 0 && areGamesInSameSeries(savedAt, previousSavedAt);
        if (sameSeries) {
            values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX] += score;
            values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_GAMES_INDEX] += 1;
        } else {
            values[BOWLING_SAVED_GAMES_SERIES_COUNT_INDEX] += 1;
            values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX] = score;
            values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_GAMES_INDEX] = 1;
        }
        if (values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX] >
            values[BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX]) {
            values[BOWLING_SAVED_GAMES_HIGH_SERIES_INDEX] =
                values[BOWLING_SAVED_GAMES_ACTIVE_SERIES_SCORE_INDEX];
        }
    }

    private static function areGamesInSameSeries(newerSavedAt as Number, olderSavedAt as Number) as Boolean {
        return newerSavedAt >= olderSavedAt &&
            newerSavedAt - olderSavedAt <= BOWLING_SAVED_GAME_SERIES_GAP_SECONDS;
    }

    private static function buildSeriesSummary(startIndex as Number, gameCount as Number,
        startedAt as Number, totalScore as Number) as Lang.Dictionary {
        return {
            BOWLING_SAVED_SERIES_START_INDEX => startIndex,
            BOWLING_SAVED_SERIES_GAME_COUNT => gameCount,
            BOWLING_SAVED_SERIES_STARTED_AT => startedAt,
            BOWLING_SAVED_SERIES_TOTAL_SCORE => totalScore
        };
    }

    private static function isValidTimestamp(savedAtSeconds) as Boolean {
        return savedAtSeconds instanceof Number && savedAtSeconds > 0;
    }

    private static function hasValidPackedPinGroups(values as Lang.Array, offset as Number,
        rollCount as Number) as Boolean {
        for (var group = 0; group < BOWLING_SAVED_GAME_PIN_GROUP_COUNT; group++) {
            var packed = values[offset + group];
            if (!(packed instanceof Number) || packed < 0 || packed > 0x0fffffff) {
                return false;
            }
        }
        for (var index = rollCount;
            index < BOWLING_SAVED_GAME_PIN_GROUP_SIZE * BOWLING_SAVED_GAME_PIN_GROUP_COUNT;
            index++) {
            var packedGroup = values[offset + (index / BOWLING_SAVED_GAME_PIN_GROUP_SIZE)];
            var shift = (index % BOWLING_SAVED_GAME_PIN_GROUP_SIZE) * 4;
            if (((packedGroup >> shift) & 0x0f) != 0) {
                return false;
            }
        }
        return true;
    }

    private static function buildValidatedGame(pins as Array<Number>,
        expectedScore as Number) as BowlingGame or Null {
        var game = new BowlingGame();
        for (var index = 0; index < pins.size(); index++) {
            if (pins[index] > 10 || !game.recordThrow(pins[index])) {
                return null;
            }
        }
        return game.isGameComplete() && game.getScore() == expectedScore ? game : null;
    }

    private static function packPinGroup(game as BowlingGame, rollCount as Number,
        startRollIndex as Number) as Number {
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

    private static function unpackPins(values as Lang.Array, offset as Number,
        rollCount as Number) as Array<Number> {
        var pins = [] as Array<Number>;
        for (var index = 0; index < rollCount; index++) {
            var packed = values[offset + (index / BOWLING_SAVED_GAME_PIN_GROUP_SIZE)];
            var shift = (index % BOWLING_SAVED_GAME_PIN_GROUP_SIZE) * 4;
            pins.add((packed >> shift) & 0x0f);
        }
        return pins;
    }
}
