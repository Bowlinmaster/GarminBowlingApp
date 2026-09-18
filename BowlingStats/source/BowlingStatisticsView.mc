import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BowlingStatisticsView extends WatchUi.View {
    private var _statistics as Lang.Dictionary;
    private var _page as Number;

    function initialize(statistics as Lang.Dictionary) {
        WatchUi.View.initialize();
        _statistics = statistics;
        _page = 0;
    }

    function nextPage() as Void {
        _page = (_page + 1) % 3;
        WatchUi.requestUpdate();
    }

    function previousPage() as Void {
        _page = (_page + 2) % 3;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        BowlingStatisticsRenderer.draw(dc, _statistics, true, _page, _page + 1, 3);
    }
}

class BowlingStatisticsRenderer {
    static function draw(dc as Dc, statistics as Lang.Dictionary, aggregate as Boolean, statisticsPage as Number, displayPage as Number, displayPageCount as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var safeInset = BowlingScreenGeometry.getSafeInset(width, height);
        var title = aggregate ? bowlingString(Rez.Strings.AllStatistics) : bowlingString(Rez.Strings.GameStatistics);
        var titleY = BowlingScreenGeometry.fitTopCenteredTextY(
            dc,
            width,
            height,
            Graphics.FONT_SMALL,
            title,
            height < 260 ? 20 : 28,
            safeInset
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, titleY, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (statisticsPage == 0) {
            drawSummaryPage(dc, statistics, aggregate, titleY);
        } else if (statisticsPage == 1) {
            drawAccuracyPage(dc, statistics, aggregate, titleY);
        } else {
            drawSeriesPage(dc, statistics, titleY);
        }

        drawPagePosition(dc, displayPage, displayPageCount);
    }

    private static function drawSummaryPage(dc as Dc, statistics as Lang.Dictionary, aggregate as Boolean, titleY as Number) as Void {
        var games = statistics[BOWLING_STAT_GAME_COUNT] as Number;
        var labels = [] as Array<String>;
        var values = [] as Array<String>;

        if (aggregate) {
            labels = [
                bowlingString(Rez.Strings.GamesPlayed),
                bowlingString(Rez.Strings.AverageScore),
                bowlingString(Rez.Strings.HighGame)
            ];
            values = [
                games.toString(),
                BowlingStatistics.formatAverage(statistics[BOWLING_STAT_TOTAL_SCORE] as Number, games),
                (statistics[BOWLING_STAT_HIGH_SCORE] as Number).toString()
            ];
        } else {
            labels = [
                bowlingString(Rez.Strings.Score),
                bowlingString(Rez.Strings.FirstBallAverage),
                bowlingString(Rez.Strings.Strikes)
            ];
            values = [
                (statistics[BOWLING_STAT_TOTAL_SCORE] as Number).toString(),
                BowlingStatistics.formatAverage(
                    statistics[BOWLING_STAT_FIRST_BALL_PINS] as Number,
                    statistics[BOWLING_STAT_FIRST_BALL_ATTEMPTS] as Number
                ),
                BowlingStatistics.formatRatio(
                    statistics[BOWLING_STAT_STRIKES] as Number,
                    statistics[BOWLING_STAT_STRIKE_ATTEMPTS] as Number
                )
            ];
        }

        drawRows(dc, labels, values, titleY, 3);
    }

    private static function drawAccuracyPage(dc as Dc, statistics as Lang.Dictionary, aggregate as Boolean, titleY as Number) as Void {
        var firstBallAverage = BowlingStatistics.formatAverage(
            statistics[BOWLING_STAT_FIRST_BALL_PINS] as Number,
            statistics[BOWLING_STAT_FIRST_BALL_ATTEMPTS] as Number
        );
        var strikeRate = BowlingStatistics.formatPercent(
            statistics[BOWLING_STAT_STRIKES] as Number,
            statistics[BOWLING_STAT_STRIKE_ATTEMPTS] as Number
        );
        var spareRate = BowlingStatistics.formatPercent(
            statistics[BOWLING_STAT_SPARES] as Number,
            statistics[BOWLING_STAT_SPARE_ATTEMPTS] as Number
        );
        var openFrames = statistics[BOWLING_STAT_OPEN_FRAMES] as Number;
        var totalFrames = (statistics[BOWLING_STAT_GAME_COUNT] as Number) * 10;
        var cleanRate = BowlingStatistics.formatPercent(totalFrames - openFrames, totalFrames);

        if (aggregate) {
            drawRows(
                dc,
                [
                    bowlingString(Rez.Strings.FirstBallAverage),
                    bowlingString(Rez.Strings.StrikeRate),
                    bowlingString(Rez.Strings.SpareConversion),
                    bowlingString(Rez.Strings.OpenFrames),
                    bowlingString(Rez.Strings.CleanFrameRate)
                ],
                [firstBallAverage, strikeRate, spareRate, openFrames.toString(), cleanRate],
                titleY,
                5
            );
        } else {
            drawRows(
                dc,
                [
                    bowlingString(Rez.Strings.Spares),
                    bowlingString(Rez.Strings.OpenFrames),
                    bowlingString(Rez.Strings.CleanFrames)
                ],
                [
                    BowlingStatistics.formatRatio(
                        statistics[BOWLING_STAT_SPARES] as Number,
                        statistics[BOWLING_STAT_SPARE_ATTEMPTS] as Number
                    ),
                    openFrames.toString(),
                    (10 - openFrames).toString()
                ],
                titleY,
                3
            );
        }
    }

    private static function drawSeriesPage(dc as Dc, statistics as Lang.Dictionary, titleY as Number) as Void {
        var games = statistics[BOWLING_STAT_GAME_COUNT] as Number;
        var series = statistics[BOWLING_STAT_SERIES_COUNT] as Number;
        drawRows(
            dc,
            [
                bowlingString(Rez.Strings.SeriesPlayed),
                bowlingString(Rez.Strings.AverageSeries),
                bowlingString(Rez.Strings.HighSeries),
                bowlingString(Rez.Strings.GamesPerSeries)
            ],
            [
                series.toString(),
                BowlingStatistics.formatAverage(statistics[BOWLING_STAT_TOTAL_SCORE] as Number, series),
                (statistics[BOWLING_STAT_HIGH_SERIES] as Number).toString(),
                BowlingStatistics.formatAverage(games, series)
            ],
            titleY,
            4
        );
    }

    private static function drawRows(dc as Dc, labels as Array<String>, values as Array<String>, titleY as Number, rowCount as Number) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var valueFont = width < height ? Graphics.FONT_XTINY : Graphics.FONT_SMALL;
        var safeInset = BowlingScreenGeometry.getSafeInset(width, height);
        var footerHeight = dc.getFontHeight(Graphics.FONT_XTINY) + (height < 260 ? 10 : 18);
        var top = titleY + (dc.getFontHeight(Graphics.FONT_SMALL) / 2) + 6;
        var bottom = height - footerHeight;
        var rowHeight = (bottom - top) / rowCount;

        for (var index = 0; index < rowCount; index++) {
            var centerY = top + (rowHeight * index) + (rowHeight / 2);
            var bandTop = centerY - (rowHeight / 2);
            var bandBottom = centerY + (rowHeight / 2);
            var safeWidth = BowlingScreenGeometry.getSafeWidthForBand(width, height, bandTop, bandBottom, safeInset);
            var maximumWidth = width - (safeInset * 2) - 12;
            if (safeWidth <= 0 || safeWidth > maximumWidth) {
                safeWidth = maximumWidth;
            }

            var left = (width - safeWidth) / 2;
            var right = left + safeWidth;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left, centerY, Graphics.FONT_XTINY, labels[index], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var valueX = right - dc.getTextWidthInPixels(values[index], valueFont);
            dc.drawText(valueX, centerY, valueFont, values[index], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private static function drawPagePosition(dc as Dc, page as Number, pageCount as Number) as Void {
        var text = page.toString() + "/" + pageCount.toString();
        var height = dc.getHeight();
        var y = BowlingScreenGeometry.fitBottomCenteredTextY(
            dc,
            dc.getWidth(),
            height,
            Graphics.FONT_XTINY,
            text,
            height - (height < 260 ? 18 : 24),
            BowlingScreenGeometry.getSafeInset(dc.getWidth(), height)
        );

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
