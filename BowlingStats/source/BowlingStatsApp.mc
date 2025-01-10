import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BowlingStatsApp extends Application.AppBase {

    function initialize() {
        System.println("App - initialize()");
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        System.println("App - onStart()");
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        System.println("App - onStop()");
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        System.println("App - getInitialView()");
        return [ new BowlingStatsView(), new BowlingStatsDelegate() ];
    }

}

function getApp() as BowlingStatsApp {
    //System.println("App - getApp()");
    return Application.getApp() as BowlingStatsApp;
}