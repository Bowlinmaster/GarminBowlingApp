import Toybox.Lang;
import Toybox.WatchUi;

class SavedSeriesListDelegate extends WatchUi.BehaviorDelegate {
    private var _view as SavedSeriesListView;

    function initialize(view as SavedSeriesListView) {
        WatchUi.BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.nextSeries();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.previousSeries();
        return true;
    }

    function onSelect() as Boolean {
        _view.openSelectedSeries();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
