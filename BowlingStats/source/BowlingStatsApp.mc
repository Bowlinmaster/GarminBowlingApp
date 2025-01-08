import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BowlingStatsApp extends WatchUi.Application{
    function onStart() {
        WatchUi.Application.onStart();
    }

    function onUpdate(dc as Graphics.Dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Clear the screen
        dc.clear();

        // Draw the text "Hello, World!" centered on the screen
        var text = "Hello, World!";
        dc.drawText(width / 2, height / 2, Graphics.FONT_XLARGE, text, Graphics.TEXT_JUSTIFY_CENTER);
    }
}