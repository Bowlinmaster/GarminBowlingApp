import Toybox.WatchUi;

class BowlingDiscardGameConfirmationDelegate extends WatchUi.ConfirmationDelegate {
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
