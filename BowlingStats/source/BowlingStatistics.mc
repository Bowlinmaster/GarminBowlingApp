import Toybox.Lang;

const BOWLING_STAT_GAME_COUNT = "games";
const BOWLING_STAT_TOTAL_SCORE = "totalScore";
const BOWLING_STAT_HIGH_SCORE = "highScore";
const BOWLING_STAT_FIRST_BALL_PINS = "firstPins";
const BOWLING_STAT_FIRST_BALL_ATTEMPTS = "firstAttempts";
const BOWLING_STAT_STRIKES = "strikes";
const BOWLING_STAT_STRIKE_ATTEMPTS = "strikeAttempts";
const BOWLING_STAT_SPARES = "spares";
const BOWLING_STAT_SPARE_ATTEMPTS = "spareAttempts";
const BOWLING_STAT_OPEN_FRAMES = "opens";
const BOWLING_STAT_SERIES_COUNT = "series";
const BOWLING_STAT_HIGH_SERIES = "highSeries";

class BowlingStatistics {
    static function forGame(game as BowlingGame) as Lang.Dictionary {
        var firstBallPins = 0;
        var strikes = 0;
        var spares = 0;
        var spareAttempts = 0;
        var openFrames = 0;

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
                if (frame.isSpare()) {
                    spares += 1;
                } else {
                    openFrames += 1;
                }
            }
        }

        return {
            BOWLING_STAT_GAME_COUNT => 1,
            BOWLING_STAT_TOTAL_SCORE => game.getScore(),
            BOWLING_STAT_HIGH_SCORE => game.getScore(),
            BOWLING_STAT_FIRST_BALL_PINS => firstBallPins,
            BOWLING_STAT_FIRST_BALL_ATTEMPTS => 10,
            BOWLING_STAT_STRIKES => strikes,
            BOWLING_STAT_STRIKE_ATTEMPTS => 10,
            BOWLING_STAT_SPARES => spares,
            BOWLING_STAT_SPARE_ATTEMPTS => spareAttempts,
            BOWLING_STAT_OPEN_FRAMES => openFrames
        };
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
}
