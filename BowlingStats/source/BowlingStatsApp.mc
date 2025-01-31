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

        var p1 = new Player("Player1");
        var game = p1.startNewGame();
        game.roll(10); //Frame 1
        game.roll(10); //Frame 2
        game.roll(10); //Frame 3
        game.roll(10); //Frame 4
        game.roll(9); //Frame 5
        game.roll(1);
        game.roll(10); //Frame 6
        game.roll(10); //Frame 7
        game.roll(10); //Frame 8
        game.roll(10); //Frame 9
        game.roll(10); //Frame 10
        game.roll(10);
        game.roll(10);
        System.println("Game complete? " + game.isComplete() + ", Game Score: " + game.getScore());
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        System.println("App - onStop()");
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        System.println("App - getInitialView()");

        //This should return an array with either the View and the Delegate or just the View
        return [ new BowlingStatsView(), new BowlingStatsDelegate() ];
    }

}

function getApp() as BowlingStatsApp {
    //System.println("App - getApp()");
    return Application.getApp() as BowlingStatsApp;
}

class Frame {
    var firstRoll;
    var secondRoll;
    var thirdRoll;
    var _tenthFrame; //boolean private

    function initialize(pins, tenthFrame){
        if(pins < 0 || pins > 10){
            //TODO: Argument out of range.  Pins must be between 0-10
        }

        self.firstRoll = pins;
        self.secondRoll = null;
        self.thirdRoll = null;
        self._tenthFrame = tenthFrame;
    }

    function setSecondRoll(pins) {
        if(pins < 0 || pins > 10){
            //TODO: Argument out of range.  Pins must be between 0-10
        }

        if(!self._tenthFrame && self.firstRoll + pins > 10){
            self.secondRoll = 10 - self.firstRoll;
        } else {
            self.secondRoll = pins;
        }
    }

    function setThirdRoll(pins){
        if(pins < 0 || pins > 10){
            //TODO: Argument out of range.  Pins must be between 0-10
        }
        if(self.firstRoll == 10 && self.secondRoll != 10 && self.secondRoll + pins > 10){
            self.thirdRoll = 10 - self.secondRoll;
        } else {
            self.thirdRoll = pins;
        }
    }

    function removeLastRoll(){
        if(self.thirdRoll != null){
            self.thirdRoll = null;
        } else if (self.secondRoll != null){
            self.secondRoll = null;
        } else{
            return true; //Frame should be removed
        }
        return false;
    }

    function isStrike(){
        return self.firstRoll == 10;
    }

    function isSpare(){
        return !self.isStrike() && ((self.firstRoll + (self.secondRoll == null ? 0 : self.secondRoll)) == 10);
    }

    function isComplete(){
        return (self.isStrike() && !self._tenthFrame) ||
        (self.isSpare() && !self._tenthFrame) ||
        (!self.isStrike() && self.secondRoll != null && !self._tenthFrame) ||
        (!self.isStrike() && !self.isSpare() && self.secondRoll != null && self.thirdRoll == null) ||
        ((self.isStrike() || self.isSpare()) && self.thirdRoll != null);
    }

    function isTenthFrame(){
        return self._tenthFrame;
    }

    function getTotalPins(){
        return self.firstRoll + (self.secondRoll == null ? 0 : self.secondRoll) + (self.thirdRoll == null ? 0 : self.thirdRoll);
    }
}

class BowlingGame {
    var frames;
    const MAX_FRAMES = 10;

    function initialize(){
        frames = [];
    }

    function roll(pins){
        if(self.isComplete()){
            //throw new Exception("Game is already complete"); //TODO
            System.println("Game is already complete");
            return;
        }

        if(self.frames.size() == 0 || self.frames[self.frames.size() -1].isComplete()){
            self.frames.add(new Frame(pins, self.frames.size() == MAX_FRAMES-1));
        }
        else{
            var lastFrame = self.frames[self.frames.size() - 1];
            if(self.frames.size() == MAX_FRAMES){
                if(lastFrame.secondRoll == null){
                    lastFrame.setSecondRoll(pins);
                } else if (lastFrame.thirdRoll == null){
                    lastFrame.setThirdRoll(pins);
                }
            } else{
                lastFrame.setSecondRoll(pins);
            }
        }
    }

    function unroll(){
        if(self.frames.size() == 0){
            //throw new Exception("No rolls to undo."); //TODO
            System.println("No rolls to undo.");
            return;
        }

        var lastFrame = self.frames[self.frames.size() - 1];

        if(lastFrame.removeLastRoll()){
            frames.remove(frames.size() - 1);
        }
    }

    function getScore(){
        var score = 0;
        for(var i = 0; i < frames.size(); i++){
            score += self.frames[i].getTotalPins();
            if(self.frames[i].isStrike() && i < self.frames.size() - 1){
                score += self.frames[i+1].firstRoll;
                if(self.frames[i+1].isStrike() && i < self.frames.size() - 2){
                    score += self.frames[i+2].firstRoll;
                } else if (self.frames[i+1].secondRoll != null){
                    score += self.frames[i+1].secondRoll;
                }
            } else if (self.frames[i].isSpare() && i < self.frames.size() - 1){
                score += self.frames[i+1].firstRoll;
            }
        }
        return score;
    }

    function isComplete() {
        return self.frames.size() == MAX_FRAMES && self.frames[MAX_FRAMES - 1].isComplete();
    }
}

class Player {
    var name;
    var games;

    function initialize(name){
        self.name = name;
        self.games = [];
    }

    function startNewGame(){
        var game = new BowlingGame();
        games.add(game);
        return game;
    }
}