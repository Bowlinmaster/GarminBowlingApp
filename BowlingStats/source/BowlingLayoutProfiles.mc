using Toybox.Graphics;
import Toybox.Lang;
using Toybox.System;

class BowlingEntryLayoutProfile {
    var name;
    var cardWidth;
    var headerHeight;
    var bodyHeight;
    var top;
    var rollBoxWidth;
    var rollBoxHeight;
    var firstRollOffset;
    var selectorYOffset;
    var selectorValueOffset;
    var confirmIconRightInset;
    var confirmIconYOffset;
    var confirmIconSize;
    var confirmIconPenWidth;
    var discardIconBottomInset;
    var frameNumberFont;
    var rollFont;
    var scoreFont;
    var selectorLabelFont;
    var selectorValueFont;
    var finishFont;

    function initialize(options as Lang.Dictionary) {
        name = options[:name];
        cardWidth = options[:cardWidth];
        headerHeight = options[:headerHeight];
        bodyHeight = options[:bodyHeight];
        top = options[:top];
        rollBoxWidth = options[:rollBoxWidth];
        rollBoxHeight = options[:rollBoxHeight];
        firstRollOffset = options[:firstRollOffset];
        selectorYOffset = options[:selectorYOffset];
        selectorValueOffset = options[:selectorValueOffset];
        confirmIconRightInset = options[:confirmIconRightInset];
        confirmIconYOffset = options[:confirmIconYOffset];
        confirmIconSize = options[:confirmIconSize];
        confirmIconPenWidth = options[:confirmIconPenWidth];
        discardIconBottomInset = options[:discardIconBottomInset];
        frameNumberFont = options[:frameNumberFont];
        rollFont = options[:rollFont];
        scoreFont = options[:scoreFont];
        selectorLabelFont = options[:selectorLabelFont];
        selectorValueFont = options[:selectorValueFont];
        finishFont = options[:finishFont];
    }
}

class BowlingEntryLayoutProfiles {
    static function forDevice(width, height) {
        var settings = System.getDeviceSettings();
        var partNumber = settings.partNumber;
        var profile = forPartNumber(partNumber);
        if (profile != null) {
            return profile;
        }

        return fallbackForScreen(width, height);
    }

    static function forPartNumber(partNumber) {
        if (partNumber == null) {
            return null;
        }

        // DeviceSettings gives us the runtime part number, so each supported product can
        // have its own profile even when several products share the same screen size.
        if (matchesPart(partNumber, ["006-B4656-00"])) {
            return approachS50();
        }

        if (matchesPart(partNumber, ["006-B4233-00"])) {
            return approachS7042mm();
        }

        if (matchesPart(partNumber, ["006-B4234-00"])) {
            return approachS7047mm();
        }

        if (matchesPart(partNumber, ["006-B2187-00"])) {
            return d2Air();
        }

        if (matchesPart(partNumber, ["006-B4125-00"])) {
            return d2AirX10();
        }

        if (matchesPart(partNumber, ["006-B4079-00"])) {
            return d2Mach1();
        }

        if (matchesPart(partNumber, ["006-B4879-00"])) {
            return d2Mach2();
        }

        if (matchesPart(partNumber, ["006-B5056-00"])) {
            return d2Mach2Pro();
        }

        if (matchesPart(partNumber, ["006-B4588-00"])) {
            return descentG2();
        }

        if (matchesPart(partNumber, ["006-B4222-00"])) {
            return descentMk343mm();
        }

        if (matchesPart(partNumber, ["006-B4223-00"])) {
            return descentMk351mm();
        }

        if (matchesPart(partNumber, ["006-B3943-00", "006-B3944-00"])) {
            return epix2();
        }

        if (matchesPart(partNumber, ["006-B4312-00"])) {
            return epix2Pro42mm();
        }

        if (matchesPart(partNumber, ["006-B4313-00"])) {
            return epix2Pro47mm();
        }

        if (matchesPart(partNumber, ["006-B4314-00", "006-B4542-00", "006-B4556-00"])) {
            return epix2Pro51mm();
        }

        if (matchesPart(partNumber, ["006-B4631-00"])) {
            return fenix8Pro47mm();
        }

        if (matchesPart(partNumber, ["006-B4666-00"])) {
            return fenixE();
        }

        if (matchesPart(partNumber, ["006-B5133-00"])) {
            return fenix943mm();
        }

        if (matchesPart(partNumber, ["006-B5134-00"])) {
            return fenix947mm();
        }

        if (matchesPart(partNumber, ["006-B4952-00"])) {
            return fenix9Pro43mm();
        }

        if (matchesPart(partNumber, ["006-B4953-00"])) {
            return fenix9Pro47mm();
        }

        if (matchesPart(partNumber, ["006-B4815-00"])) {
            return fr170();
        }

        if (matchesPart(partNumber, ["006-B4814-00"])) {
            return fr170Music();
        }

        if (matchesPart(partNumber, ["006-B4916-00", "006-B5214-00"])) {
            return fr70();
        }

        if (matchesPart(partNumber, ["006-B4586-00"])) {
            return instinct3Amoled45mm();
        }

        if (matchesPart(partNumber, ["006-B4587-00"])) {
            return instinct3Amoled50mm();
        }

        if (matchesPart(partNumber, ["006-B4678-00"])) {
            return instinctCrossoverAmoled();
        }

        if (matchesPart(partNumber, ["006-B4105-00", "006-B4472-00"])) {
            return marq2();
        }

        if (matchesPart(partNumber, ["006-B4124-00"])) {
            return marq2Aviator();
        }

        if (matchesPart(partNumber, ["006-B3226-00", "006-B3389-00"])) {
            return venu();
        }

        if (matchesPart(partNumber, ["006-B3740-00", "006-B3737-00"])) {
            return venuMercedesBenz();
        }

        if (matchesPart(partNumber, ["006-B3907-00", "006-B3910-00", "006-B4135-00", "006-B4341-00"])) {
            return fenix7x();
        }

        if (matchesPart(partNumber, ["006-B4376-00"])) {
            return fenix7xPro();
        }

        if (matchesPart(partNumber, ["006-B4596-00"])) {
            return fenix7xProNoWifi();
        }

        if (matchesPart(partNumber, ["006-B4575-00"])) {
            return enduro3();
        }

        if (matchesPart(partNumber, ["006-B4533-00", "006-B4776-00"])) {
            return fenix8Solar51mm();
        }

        if (matchesPart(partNumber, ["006-B3906-00", "006-B3909-00"])) {
            return fenix7();
        }

        if (matchesPart(partNumber, ["006-B4375-00"])) {
            return fenix7Pro();
        }

        if (matchesPart(partNumber, ["006-B4595-00"])) {
            return fenix7ProNoWifi();
        }

        if (matchesPart(partNumber, ["006-B4532-00"])) {
            return fenix8Solar47mm();
        }

        if (matchesPart(partNumber, ["006-B3992-00"])) {
            return fr255();
        }

        if (matchesPart(partNumber, ["006-B3990-00"])) {
            return fr255Music();
        }

        if (matchesPart(partNumber, ["006-B4024-00"])) {
            return fr955();
        }

        if (matchesPart(partNumber, ["006-B3905-00", "006-B3908-00"])) {
            return fenix7s();
        }

        if (matchesPart(partNumber, ["006-B4374-00"])) {
            return fenix7sPro();
        }

        if (matchesPart(partNumber, ["006-B3993-00"])) {
            return fr255s();
        }

        if (matchesPart(partNumber, ["006-B3991-00"])) {
            return fr255sMusic();
        }

        if (matchesPart(partNumber, ["006-B4534-00"])) {
            return fenix843mm();
        }

        if (matchesPart(partNumber, ["006-B4257-00"])) {
            return fr265();
        }

        if (matchesPart(partNumber, ["006-B3703-00", "006-B3950-00", "006-B4171-00", "006-B4180-00"])) {
            return venu2();
        }

        if (matchesPart(partNumber, ["006-B3851-00", "006-B4017-00"])) {
            return venu2Plus();
        }

        if (matchesPart(partNumber, ["006-B4536-00", "006-B4775-00"])) {
            return fenix847mm();
        }

        if (matchesPart(partNumber, ["006-B4315-00"])) {
            return fr965();
        }

        if (matchesPart(partNumber, ["006-B4570-00"])) {
            return fr57047mm();
        }

        if (matchesPart(partNumber, ["006-B4565-00"])) {
            return fr970();
        }

        if (matchesPart(partNumber, ["006-B4260-00"])) {
            return venu3();
        }

        if (matchesPart(partNumber, ["006-B4643-00", "006-B4944-00"])) {
            return venu445mm();
        }

        if (matchesPart(partNumber, ["006-B4426-00"])) {
            return vivoactive5();
        }

        if (matchesPart(partNumber, ["006-B4625-00"])) {
            return vivoactive6();
        }

        if (matchesPart(partNumber, ["006-B4432-00"])) {
            return fr165();
        }

        if (matchesPart(partNumber, ["006-B4433-00"])) {
            return fr165Music();
        }

        if (matchesPart(partNumber, ["006-B4261-00"])) {
            return venu3s();
        }

        if (matchesPart(partNumber, ["006-B4574-00"])) {
            return fr57042mm();
        }

        if (matchesPart(partNumber, ["006-B4644-00"])) {
            return venu441mm();
        }

        if (matchesPart(partNumber, ["006-B4258-00"])) {
            return fr265s();
        }

        if (matchesPart(partNumber, ["006-B3704-00", "006-B3949-00", "006-B4175-00", "006-B4181-00"])) {
            return venu2s();
        }

        if (matchesPart(partNumber, ["006-B4115-00"])) {
            return venuSq2();
        }

        if (matchesPart(partNumber, ["006-B4116-00"])) {
            return venuSq2Music();
        }

        return null;
    }

    static function fallbackForScreen(width, height) {
        // Unknown devices still get a usable layout until a part-number profile is added.
        var safeSize = width < height ? width : height;

        if (safeSize <= 240) {
            return smallRound();
        }

        if (safeSize >= 360) {
            return largeRound();
        }

        return fenix7x();
    }

    static function matchesPart(partNumber as String, partNumbers as Array<String>) {
        for (var i = 0; i < partNumbers.size(); i++) {
            if (partNumber.equals(partNumbers[i])) {
                return true;
            }
        }

        return false;
    }

    static function fenix7x() {
        return new BowlingEntryLayoutProfile({
            :name => "fenix7x-280",
            :cardWidth => 118,
            :headerHeight => 22,
            :bodyHeight => 82,
            :top => 26,
            :rollBoxWidth => 34,
            :rollBoxHeight => 30,
            :firstRollOffset => 18,
            :selectorYOffset => 36,
            :selectorValueOffset => 20,
            :confirmIconRightInset => 42,
            :confirmIconYOffset => 58,
            :confirmIconSize => 18,
            :confirmIconPenWidth => 3,
            :discardIconBottomInset => 22,
            :frameNumberFont => Graphics.FONT_XTINY,
            :rollFont => Graphics.FONT_SMALL,
            :scoreFont => Graphics.FONT_LARGE,
            :selectorLabelFont => Graphics.FONT_XTINY,
            :selectorValueFont => Graphics.FONT_LARGE,
            :finishFont => Graphics.FONT_SMALL
        });
    }

    static function fenix7xPro() {
        return profile280("fenix7xpro");
    }

    static function fenix7xProNoWifi() {
        return profile280("fenix7xpronowifi");
    }

    static function enduro3() {
        return profile280("enduro3");
    }

    static function fenix8Solar51mm() {
        return profile280("fenix8solar51mm");
    }

    static function fenix7() {
        return profile260("fenix7");
    }

    static function fenix7Pro() {
        return profile260("fenix7pro");
    }

    static function fenix7ProNoWifi() {
        return profile260("fenix7pronowifi");
    }

    static function fenix8Solar47mm() {
        return profile260("fenix8solar47mm");
    }

    static function fr255() {
        return profile260("fr255");
    }

    static function fr255Music() {
        return profile260("fr255m");
    }

    static function fr955() {
        return profile260("fr955");
    }

    static function fenix7s() {
        return profile240("fenix7s");
    }

    static function fenix7sPro() {
        return profile240("fenix7spro");
    }

    static function fr255s() {
        return profile218("fr255s");
    }

    static function fr255sMusic() {
        return profile218("fr255sm");
    }

    static function fenix843mm() {
        return profile416("fenix843mm");
    }

    static function approachS50() { return profile390("approachs50"); }
    static function approachS7042mm() { return profile390("approachs7042mm"); }
    static function approachS7047mm() { return profile454("approachs7047mm"); }
    static function d2Air() { return profile390("d2air"); }
    static function d2AirX10() { return profile416("d2airx10"); }
    static function d2Mach1() { return profile416("d2mach1"); }
    static function d2Mach2() { return profile454("d2mach2"); }
    static function d2Mach2Pro() { return profile454("d2mach2pro"); }
    static function descentG2() { return profile390("descentg2"); }
    static function descentMk343mm() { return profile390("descentmk343mm"); }
    static function descentMk351mm() { return profile454("descentmk351mm"); }
    static function epix2() { return profile416("epix2"); }
    static function epix2Pro42mm() { return profile390("epix2pro42mm"); }
    static function epix2Pro47mm() { return profile416("epix2pro47mm"); }
    static function epix2Pro51mm() { return profile454("epix2pro51mm"); }
    static function fenix8Pro47mm() { return profile454("fenix8pro47mm"); }
    static function fenixE() { return profile416("fenixe"); }
    static function fenix943mm() { return profile416("fenix943mm"); }
    static function fenix947mm() { return profile454("fenix947mm"); }
    static function fenix9Pro43mm() { return profile416("fenix9pro43mm"); }
    static function fenix9Pro47mm() { return profile454("fenix9pro47mm"); }
    static function fr170() { return profile390("fr170"); }
    static function fr170Music() { return profile390("fr170m"); }
    static function fr70() { return profile390("fr70"); }
    static function instinct3Amoled45mm() { return profile390("instinct3amoled45mm"); }
    static function instinct3Amoled50mm() { return profile416("instinct3amoled50mm"); }
    static function instinctCrossoverAmoled() { return profile390("instinctcrossoveramoled"); }
    static function marq2() { return profile390("marq2"); }
    static function marq2Aviator() { return profile390("marq2aviator"); }
    static function venu() { return profile390("venu"); }
    static function venuMercedesBenz() { return profile390("venud"); }

    static function fr265() {
        return profile416("fr265");
    }

    static function venu2() {
        return profile416("venu2");
    }

    static function venu2Plus() {
        return profile416("venu2plus");
    }

    static function fenix847mm() {
        return profile454("fenix847mm");
    }

    static function fr965() {
        return profile454("fr965");
    }

    static function fr57047mm() {
        return profile454("fr57047mm");
    }

    static function fr970() {
        return profile454("fr970");
    }

    static function venu3() {
        return profile454("venu3");
    }

    static function venu445mm() {
        return profile454("venu445mm");
    }

    static function vivoactive5() {
        return profile390("vivoactive5");
    }

    static function vivoactive6() {
        return profile390("vivoactive6");
    }

    static function fr165() {
        return profile390("fr165");
    }

    static function fr165Music() {
        return profile390("fr165m");
    }

    static function venu3s() {
        return profile390("venu3s");
    }

    static function fr57042mm() {
        return profile390("fr57042mm");
    }

    static function venu441mm() {
        return profile390("venu441mm");
    }

    static function fr265s() {
        return profile360("fr265s");
    }

    static function venu2s() {
        return profile360("venu2s");
    }

    static function venuSq2() {
        return rectangle320x360("venusq2");
    }

    static function venuSq2Music() {
        return rectangle320x360("venusq2m");
    }

    static function profile280(name) {
        var profile = fenix7x();
        profile.name = name;
        return profile;
    }

    static function profile260(name) {
        var profile = fenix7x();
        profile.name = name;
        profile.cardWidth = 112;
        profile.bodyHeight = 78;
        profile.top = 24;
        profile.rollBoxWidth = 32;
        profile.rollBoxHeight = 28;
        profile.firstRollOffset = 17;
        profile.selectorYOffset = 32;
        profile.confirmIconRightInset = 38;
        profile.confirmIconYOffset = 54;
        profile.confirmIconSize = 16;
        return profile;
    }

    static function profile240(name) {
        var profile = smallRound();
        profile.name = name;
        return profile;
    }

    static function profile218(name) {
        var profile = smallRound();
        profile.name = name;
        profile.cardWidth = 96;
        profile.headerHeight = 18;
        profile.bodyHeight = 66;
        profile.top = 20;
        profile.rollBoxWidth = 26;
        profile.rollBoxHeight = 24;
        profile.firstRollOffset = 14;
        profile.selectorYOffset = 24;
        profile.confirmIconRightInset = 30;
        profile.confirmIconYOffset = 46;
        profile.confirmIconSize = 14;
        profile.discardIconBottomInset = 16;
        return profile;
    }

    static function profile360(name) {
        var profile = largeRound();
        profile.name = name;
        profile.cardWidth = 134;
        profile.headerHeight = 32;
        profile.bodyHeight = 92;
        profile.top = 32;
        profile.rollBoxWidth = 38;
        profile.rollBoxHeight = 34;
        profile.rollFont = Graphics.FONT_XTINY;
        profile.selectorYOffset = 44;
        profile.confirmIconRightInset = 50;
        profile.confirmIconYOffset = 76;
        profile.confirmIconSize = 20;
        profile.discardIconBottomInset = 24;
        return profile;
    }

    static function profile390(name) {
        var profile = largeRound();
        profile.name = name;
        profile.cardWidth = 138;
        profile.top = 34;
        profile.selectorYOffset = 46;
        profile.confirmIconRightInset = 54;
        profile.confirmIconYOffset = 82;
        profile.confirmIconSize = 20;
        profile.discardIconBottomInset = 26;
        return profile;
    }

    static function profile416(name) {
        var profile = largeRound();
        profile.name = name;
        profile.cardWidth = 140;
        profile.top = 35;
        profile.selectorYOffset = 48;
        profile.confirmIconRightInset = 58;
        profile.confirmIconYOffset = 86;
        profile.confirmIconSize = 22;
        profile.discardIconBottomInset = 28;
        return profile;
    }

    static function profile454(name) {
        var profile = largeRound();
        profile.name = name;
        return profile;
    }

    static function rectangle320x360(name) {
        var profile = largeRound();
        profile.name = name;
        profile.cardWidth = 136;
        profile.headerHeight = 34;
        profile.bodyHeight = 90;
        profile.top = 28;
        profile.rollBoxWidth = 38;
        profile.rollBoxHeight = 36;
        profile.rollFont = Graphics.FONT_XTINY;
        profile.selectorYOffset = 38;
        profile.confirmIconRightInset = 36;
        profile.confirmIconYOffset = 74;
        profile.confirmIconSize = 18;
        profile.discardIconBottomInset = 22;
        return profile;
    }

    static function smallRound() {
        return new BowlingEntryLayoutProfile({
            :name => "small-round",
            :cardWidth => 104,
            :headerHeight => 20,
            :bodyHeight => 72,
            :top => 22,
            :rollBoxWidth => 28,
            :rollBoxHeight => 26,
            :firstRollOffset => 15,
            :selectorYOffset => 30,
            :selectorValueOffset => 18,
            :confirmIconRightInset => 34,
            :confirmIconYOffset => 50,
            :confirmIconSize => 15,
            :confirmIconPenWidth => 3,
            :discardIconBottomInset => 18,
            :frameNumberFont => Graphics.FONT_XTINY,
            :rollFont => Graphics.FONT_XTINY,
            :scoreFont => Graphics.FONT_MEDIUM,
            :selectorLabelFont => Graphics.FONT_XTINY,
            :selectorValueFont => Graphics.FONT_MEDIUM,
            :finishFont => Graphics.FONT_XTINY
        });
    }

    static function largeRound() {
        return new BowlingEntryLayoutProfile({
            :name => "large-round",
            :cardWidth => 142,
            :headerHeight => 34,
            :bodyHeight => 98,
            :top => 36,
            :rollBoxWidth => 40,
            :rollBoxHeight => 36,
            :firstRollOffset => 22,
            :selectorYOffset => 50,
            :selectorValueOffset => 24,
            :confirmIconRightInset => 62,
            :confirmIconYOffset => 94,
            :confirmIconSize => 24,
            :confirmIconPenWidth => 4,
            :discardIconBottomInset => 30,
            :frameNumberFont => Graphics.FONT_XTINY,
            :rollFont => Graphics.FONT_XTINY,
            :scoreFont => Graphics.FONT_LARGE,
            :selectorLabelFont => Graphics.FONT_XTINY,
            :selectorValueFont => Graphics.FONT_LARGE,
            :finishFont => Graphics.FONT_SMALL
        });
    }
}
