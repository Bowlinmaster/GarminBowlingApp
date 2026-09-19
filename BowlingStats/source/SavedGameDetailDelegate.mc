import Toybox.WatchUi;

class SavedGameDetailDelegate extends WatchUi.BehaviorDelegate {
    private var _view;

    function initialize(view) {
        WatchUi.BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() {
        _view.nextPage();
        return true;
    }

    function onPreviousPage() {
        _view.previousPage();
        return true;
    }

    function onKey(event) {
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

    function onSelect() {
        _view.nextPage();
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
