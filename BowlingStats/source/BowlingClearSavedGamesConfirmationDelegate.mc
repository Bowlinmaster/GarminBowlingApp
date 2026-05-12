import Toybox.WatchUi;

class BowlingClearSavedGamesConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            BowlingSavedGameStore.clearSavedGames();
        }

        return true;
    }
}
