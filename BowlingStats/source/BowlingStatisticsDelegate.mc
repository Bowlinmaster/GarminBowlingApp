import Toybox.Lang;
import Toybox.WatchUi;

class BowlingStatisticsDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BowlingStatisticsView;

    function initialize(view as BowlingStatisticsView) {
        WatchUi.BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.nextPage();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.previousPage();
        return true;
    }

    function onKey(event as WatchUi.KeyEvent) as Boolean {
        var key = event.getKey();
        if (key == WatchUi.KEY_UP) {
            _view.previousPage();
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            _view.nextPage();
            return true;
        }

        return false;
    }

    function onSelect() as Boolean {
        _view.nextPage();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
