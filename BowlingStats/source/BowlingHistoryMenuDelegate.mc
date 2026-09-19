import Toybox.Lang;
import Toybox.WatchUi;

class BowlingHistoryMenuDelegate extends WatchUi.BehaviorDelegate {
    private var _view as BowlingHistoryMenuView;

    function initialize(view as BowlingHistoryMenuView) {
        WatchUi.BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.nextItem();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.previousItem();
        return true;
    }

    function onSelect() as Boolean {
        _view.openSelectedItem();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
