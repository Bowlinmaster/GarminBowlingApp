using Toybox.WatchUi;
using Toybox.System;
using Toybox.Activity;

class BowlingStats extends WatchUi.Application {
    function initialize() {
        WatchUi.Application.initialize();
        WatchUi.pushView(new MainActivityView());
    }
}

class MainActivityView extends WatchUi.View {
    function onCreate() {
        View.loadViewFromResource("MainView.xml");
    }

    function onShow() {
        View.findDrawableById("startButton").onTap = method(:onStartGame);
        View.findDrawableById("viewScoresButton").onTap = method(:onViewScores);
    }

    function onStartGame() {
        WatchUi.pushView(new GameActivityView());
    }

    function onViewScores() {
        WatchUi.pushView(new ScoreActivityView());
    }
}

class GameActivityView extends WatchUi.View {
    var currentFrame = 1;
    var ball = 1;
    var frameScores = []; // Each frame is [ball1, ball2, optionalBall3]
    var activity; // Activity instance for metrics

    function onCreate() {
        View.loadViewFromResource("GameView.xml");
        activity = new Activity.ActivityRecording(); //Use ActivityRecording
        //activity = new Activity.Activity(); //Initialize the activity
        //activity = new Activity.Activity({ type: "BowlingGame", name: "Bowling Game"});
    }

    function onShow() {
        //Create the handlers for pin input and ending the game.
        View.findDrawableById("pinInputButton").onTap = method(:onPinInput);
        View.findDrawableById("endGameButton").onTap = method(:onEndGame);

        //Set the info on the activity
        //activity.setInfo({"type":"Bowling", "name":"Bowling Game"})

        updateScoreView();
        activity.start();
    }

    function onHide() {
        activity.stop();
    }

    function onPinInput() {
        getPinsKnocked();
    }

    function onEndGame() {
        saveGame();
        //activity.stop();
        WatchUi.pushView(new GameSummaryView(calculateScore(), countOpenFrames()));
    }

    function updateScoreView() {
        var scoreLabel = View.findDrawableById("scoreLabel");
        scoreLabel.setText("Score: " + calculateScore());
        var frameLabel = View.findDrawableById("frameLabel");
        frameLabel.setText("Frame: " + currentFrame);
    }

    function calculateScore() {
        var totalScore = 0;
        for (var i = 0; i < frameScores.size(); i++) {
            var frame = frameScores[i];
            if (frame[0] == 10) { // Strike
                totalScore += 10;
                if (i + 1 < frameScores.size()) {
                    totalScore += frameScores[i + 1].sum();
                    if (frameScores[i + 1][0] == 10 && i + 2 < frameScores.size()) {
                        totalScore += frameScores[i + 2][0];
                    }
                }
            } else if (frame.size() > 1 && frame[0] + frame[1] == 10) { // Spare
                totalScore += 10;
                if (i + 1 < frameScores.size()) {
                    totalScore += frameScores[i + 1][0];
                }
            } else { // Open frame
                totalScore += frame.sum();
            }
        }
        activity.setMetric("Score", totalScore);
        return totalScore;
    }

    function countOpenFrames() {
        var openFrames = 0;
        for (var i = 0; i < frameScores.size(); i++) {
            var frame = frameScores[i];
            if (frame[0] + (frame.size() > 1 ? frame[1] : 0) < 10) {
                openFrames++;
            }
        }
        activity.setMetric("OpenFrames", openFrames);
        return openFrames;
    }

    function saveGame() {
        var metrics = { 
            "Score" => calculateScore(), 
            "OpenFrames" => countOpenFrames(), 
            "FrameDetails" => frameScores
        };
        //var metrics = { "Score": calculateScore(), "OpenFrames": countOpenFrames(), "FrameDetails": frameScores };
        for(var key in metrics){
            activity.setMetric(key, metrics[key]);
        }
        //activity.saveMetrics(metrics);
        activity.stop();
    }

    function getPinsKnocked() {
        var maxPins;
        if (currentFrame == 10) {
            if (ball == 1) {
                maxPins = 10;
            } else if (ball == 2 && frameScores[currentFrame - 1][0] == 10) { // Strike on ball 1
                maxPins = 10;
            } else {
                maxPins = 10 - frameScores[currentFrame - 1][0];
            }
        } else {
            maxPins = ball == 1 ? 10 : (10 - frameScores[currentFrame - 1][0]);
        }

        var displayValues = [];

        for (var i = 0; i <= maxPins; i++) {
            if (ball == 1 && i == 10) {
                displayValues.add("X"); // Strike
            } else if (ball == 2 && i == maxPins) {
                displayValues.add("/"); // Spare
            } else {
                displayValues.add(i.toString());
            }
        }

        var picker = new WatchUi.TextPicker({
            values: displayValues,
            selectedIndex: displayValues.size() - 1 // Start at the highest index
        });

        picker.show(method(:onTextSelected));
    }

    function onTextSelected(selectedText) {
        var pinsKnocked;

        if (selectedText == "X") {
            pinsKnocked = 10;
        } else if (selectedText == "/") {
            pinsKnocked = 10 - frameScores[currentFrame - 1][0];
        } else {
            pinsKnocked = selectedText.toNumber();
        }

        if (frameScores.size() < currentFrame) {
            frameScores.add([]);
        }

        frameScores[currentFrame - 1].add(pinsKnocked);

        if (currentFrame == 10) {
            if (ball == 1 || (ball == 2 && frameScores[currentFrame - 1].sum() >= 10)) {
                ball++;
            } else if (ball == 3 || (ball == 2 && frameScores[currentFrame - 1].sum() < 10)) {
                onEndGame();
                return;
            }
        } else {
            if (pinsKnocked == 10 || ball == 2) { // Strike or end of frame
                currentFrame++;
                ball = 1;
            } else {
                ball++;
            }

            if (currentFrame > 10) { // Game over
                onEndGame();
                return;
            }
        }

        updateScoreView();
    }
}

class ScoreActivityView extends WatchUi.View {
    function onCreate() {
        View.loadViewFromResource("ScoreView.xml");
    }

    function onShow() {
        updateScoreList();
    }

    function updateScoreList() {
        var list = View.findDrawableById("scoreList");
        list.addItem("View metrics in activity history.");
    }
}

class GameSummaryView extends WatchUi.View {
    var finalScore;
    var openFrames;

    function initialize(finalScore, openFrames) {
        this.finalScore = finalScore;
        this.openFrames = openFrames;
    }

    function onCreate() {
        View.loadViewFromResource("GameSummaryView.xml");
    }

    function onShow() {
        View.findDrawableById("finalScoreLabel").setText("Final Score: " + finalScore);
        View.findDrawableById("openFramesLabel").setText("Open Frames: " + openFrames);
        View.findDrawableById("backToMainButton").onTap = method(:onBackToMain);
    }

    function onBackToMain() {
        WatchUi.popView();
    }
}



/*
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
*/