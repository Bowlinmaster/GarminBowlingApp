import Toybox.WatchUi;

class SavedGamesDelegate extends WatchUi.BehaviorDelegate {
    var _view;

    function initialize(view) {
        WatchUi.BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() {
        _view.nextGame();
        return true;
    }

    function onPreviousPage() {
        _view.previousGame();
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
