import Toybox.WatchUi;

class BowlingDiscardUnsavedGameConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    var _view;

    function initialize(view) {
        WatchUi.ConfirmationDelegate.initialize();
        _view = view;
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            _view.requestDiscard();
        }

        return true;
    }
}
