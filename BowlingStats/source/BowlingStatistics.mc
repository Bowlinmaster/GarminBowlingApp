import Toybox.Lang;

const BOWLING_STAT_GAME_COUNT = "games";
const BOWLING_STAT_TOTAL_SCORE = "totalScore";
const BOWLING_STAT_HIGH_SCORE = "highScore";
const BOWLING_STAT_LOW_SCORE = "lowScore";
const BOWLING_STAT_FIRST_BALL_PINS = "firstPins";
const BOWLING_STAT_FIRST_BALL_ATTEMPTS = "firstAttempts";
const BOWLING_STAT_STRIKES = "strikes";
const BOWLING_STAT_STRIKE_ATTEMPTS = "strikeAttempts";
const BOWLING_STAT_SPARES = "spares";
const BOWLING_STAT_SPARE_ATTEMPTS = "spareAttempts";
const BOWLING_STAT_OPEN_FRAMES = "opens";
const BOWLING_STAT_SINGLE_PIN_ATTEMPTS = "singleAttempts";
const BOWLING_STAT_SINGLE_PIN_SPARES = "singleSpares";
const BOWLING_STAT_MULTI_PIN_ATTEMPTS = "multiAttempts";
const BOWLING_STAT_MULTI_PIN_SPARES = "multiSpares";
const BOWLING_STAT_CLEAN_FRAMES = "cleanFrames";
const BOWLING_STAT_SERIES_COUNT = "series";
const BOWLING_STAT_HIGH_SERIES = "highSeries";

class BowlingStatistics {
    static function empty() as Lang.Dictionary {
        return {
            BOWLING_STAT_GAME_COUNT => 0,
            BOWLING_STAT_TOTAL_SCORE => 0,
            BOWLING_STAT_HIGH_SCORE => 0,
            BOWLING_STAT_LOW_SCORE => 0,
            BOWLING_STAT_FIRST_BALL_PINS => 0,
            BOWLING_STAT_FIRST_BALL_ATTEMPTS => 0,
            BOWLING_STAT_STRIKES => 0,
            BOWLING_STAT_STRIKE_ATTEMPTS => 0,
            BOWLING_STAT_SPARES => 0,
            BOWLING_STAT_SPARE_ATTEMPTS => 0,
            BOWLING_STAT_OPEN_FRAMES => 0,
            BOWLING_STAT_SINGLE_PIN_ATTEMPTS => 0,
            BOWLING_STAT_SINGLE_PIN_SPARES => 0,
            BOWLING_STAT_MULTI_PIN_ATTEMPTS => 0,
            BOWLING_STAT_MULTI_PIN_SPARES => 0,
            BOWLING_STAT_CLEAN_FRAMES => 0
        };
    }

    static function forGame(game as BowlingGame) as Lang.Dictionary {
        var statistics = empty();
        addGame(statistics, game);
        return statistics;
    }

    static function addGame(statistics as Lang.Dictionary, game as BowlingGame) as Void {
        var firstBallPins = 0;
        var strikes = 0;
        var spares = 0;
        var spareAttempts = 0;
        var openFrames = 0;
        var singlePinAttempts = 0;
        var singlePinSpares = 0;
        var multiPinAttempts = 0;
        var multiPinSpares = 0;

        for (var frameIndex = 0; frameIndex < 10; frameIndex++) {
            var frame = game.getFrame(frameIndex);
            var firstBall = frame.getPinsAt(0);
            if (firstBall == null) {
                continue;
            }

            firstBallPins += firstBall;
            if (frame.isStrike()) {
                strikes += 1;
            } else {
                spareAttempts += 1;
                var isSinglePin = firstBall == 9;
                if (isSinglePin) {
                    singlePinAttempts += 1;
                } else {
                    multiPinAttempts += 1;
                }
                if (frame.isSpare()) {
                    spares += 1;
                    if (isSinglePin) {
                        singlePinSpares += 1;
                    } else {
                        multiPinSpares += 1;
                    }
                } else {
                    openFrames += 1;
                }
            }
        }

        var isFirstGame = statistics[BOWLING_STAT_GAME_COUNT] == 0;
        statistics[BOWLING_STAT_GAME_COUNT] += 1;
        statistics[BOWLING_STAT_TOTAL_SCORE] += game.getScore();
        if (game.getScore() > statistics[BOWLING_STAT_HIGH_SCORE]) {
            statistics[BOWLING_STAT_HIGH_SCORE] = game.getScore();
        }
        if (isFirstGame || game.getScore() < statistics[BOWLING_STAT_LOW_SCORE]) {
            statistics[BOWLING_STAT_LOW_SCORE] = game.getScore();
        }
        statistics[BOWLING_STAT_FIRST_BALL_PINS] += firstBallPins;
        statistics[BOWLING_STAT_FIRST_BALL_ATTEMPTS] += 10;
        statistics[BOWLING_STAT_STRIKES] += strikes;
        statistics[BOWLING_STAT_STRIKE_ATTEMPTS] += 10;
        statistics[BOWLING_STAT_SPARES] += spares;
        statistics[BOWLING_STAT_SPARE_ATTEMPTS] += spareAttempts;
        statistics[BOWLING_STAT_OPEN_FRAMES] += openFrames;
        statistics[BOWLING_STAT_SINGLE_PIN_ATTEMPTS] += singlePinAttempts;
        statistics[BOWLING_STAT_SINGLE_PIN_SPARES] += singlePinSpares;
        statistics[BOWLING_STAT_MULTI_PIN_ATTEMPTS] += multiPinAttempts;
        statistics[BOWLING_STAT_MULTI_PIN_SPARES] += multiPinSpares;
        statistics[BOWLING_STAT_CLEAN_FRAMES] += 10 - openFrames;
    }

    static function formatAverage(numerator as Number, denominator as Number) as String {
        if (denominator <= 0) {
            return "--";
        }

        var tenths = ((numerator * 10) + (denominator / 2)) / denominator;
        return (tenths / 10).toString() + "." + (tenths % 10).toString();
    }

    static function formatPercent(numerator as Number, denominator as Number) as String {
        if (denominator <= 0) {
            return "--";
        }

        return (((numerator * 100) + (denominator / 2)) / denominator).toString() + "%";
    }

    static function formatRatio(numerator as Number, denominator as Number) as String {
        return numerator.toString() + "/" + denominator.toString();
    }

    static function add(target as Lang.Dictionary, additional as Lang.Dictionary) as Void {
        var targetWasEmpty = target[BOWLING_STAT_GAME_COUNT] == 0;
        target[BOWLING_STAT_GAME_COUNT] += additional[BOWLING_STAT_GAME_COUNT] as Number;
        target[BOWLING_STAT_TOTAL_SCORE] += additional[BOWLING_STAT_TOTAL_SCORE] as Number;
        var highScore = additional[BOWLING_STAT_HIGH_SCORE] as Number;
        if (highScore > target[BOWLING_STAT_HIGH_SCORE]) {
            target[BOWLING_STAT_HIGH_SCORE] = highScore;
        }
        var lowScore = additional[BOWLING_STAT_LOW_SCORE] as Number;
        if (targetWasEmpty || lowScore < target[BOWLING_STAT_LOW_SCORE]) {
            target[BOWLING_STAT_LOW_SCORE] = lowScore;
        }
        target[BOWLING_STAT_FIRST_BALL_PINS] += additional[BOWLING_STAT_FIRST_BALL_PINS] as Number;
        target[BOWLING_STAT_FIRST_BALL_ATTEMPTS] += additional[BOWLING_STAT_FIRST_BALL_ATTEMPTS] as Number;
        target[BOWLING_STAT_STRIKES] += additional[BOWLING_STAT_STRIKES] as Number;
        target[BOWLING_STAT_STRIKE_ATTEMPTS] += additional[BOWLING_STAT_STRIKE_ATTEMPTS] as Number;
        target[BOWLING_STAT_SPARES] += additional[BOWLING_STAT_SPARES] as Number;
        target[BOWLING_STAT_SPARE_ATTEMPTS] += additional[BOWLING_STAT_SPARE_ATTEMPTS] as Number;
        target[BOWLING_STAT_OPEN_FRAMES] += additional[BOWLING_STAT_OPEN_FRAMES] as Number;
        target[BOWLING_STAT_SINGLE_PIN_ATTEMPTS] += additional[BOWLING_STAT_SINGLE_PIN_ATTEMPTS] as Number;
        target[BOWLING_STAT_SINGLE_PIN_SPARES] += additional[BOWLING_STAT_SINGLE_PIN_SPARES] as Number;
        target[BOWLING_STAT_MULTI_PIN_ATTEMPTS] += additional[BOWLING_STAT_MULTI_PIN_ATTEMPTS] as Number;
        target[BOWLING_STAT_MULTI_PIN_SPARES] += additional[BOWLING_STAT_MULTI_PIN_SPARES] as Number;
        target[BOWLING_STAT_CLEAN_FRAMES] += additional[BOWLING_STAT_CLEAN_FRAMES] as Number;
    }
}
