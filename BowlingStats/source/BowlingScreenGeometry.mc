import Toybox.Graphics;
import Toybox.Math;
import Toybox.System;

class BowlingScreenGeometry {
    static function getSafeInset(width, height) {
        var shortestSide = width < height ? width : height;
        return shortestSide / 32;
    }

    static function fitTopCenteredTextY(dc, width, height, font, text, preferredY, inset) {
        if (!isRoundScreen()) {
            return preferredY;
        }

        var minimumY = getTopTextCenterY(dc, width, height, font, text, inset);
        return preferredY < minimumY ? minimumY : preferredY;
    }

    static function fitBottomCenteredTextY(dc, width, height, font, text, preferredY, inset) {
        if (!isRoundScreen()) {
            return preferredY;
        }

        var maximumY = getBottomTextCenterY(dc, width, height, font, text, inset);
        return preferredY > maximumY ? maximumY : preferredY;
    }

    static function getSafeWidthForBand(width, height, top, bottom, inset) {
        if (!isRoundScreen()) {
            return width - (inset * 2);
        }

        var radius = ((width < height ? width : height) / 2) - inset;
        var centerY = height / 2;
        var topDistance = top < centerY ? centerY - top : top - centerY;
        var bottomDistance = bottom < centerY ? centerY - bottom : bottom - centerY;
        var verticalDistance = topDistance > bottomDistance ? topDistance : bottomDistance;
        if (verticalDistance >= radius) {
            return 0;
        }

        return Math.floor(2 * Math.sqrt((radius * radius) - (verticalDistance * verticalDistance)));
    }

    private static function isRoundScreen() {
        return System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND;
    }

    private static function getTopTextCenterY(dc, width, height, font, text, inset) {
        var centerY = height / 2;
        var verticalExtent = getVerticalExtent(dc, width, height, font, text, inset);
        return Math.ceil(centerY - verticalExtent + (dc.getFontHeight(font) / 2));
    }

    private static function getBottomTextCenterY(dc, width, height, font, text, inset) {
        var centerY = height / 2;
        var verticalExtent = getVerticalExtent(dc, width, height, font, text, inset);
        return Math.floor(centerY + verticalExtent - (dc.getFontHeight(font) / 2));
    }

    private static function getVerticalExtent(dc, width, height, font, text, inset) {
        var radius = ((width < height ? width : height) / 2) - inset;
        var halfTextWidth = dc.getTextWidthInPixels(text, font) / 2;
        if (halfTextWidth >= radius) {
            return 0;
        }

        return Math.sqrt((radius * radius) - (halfTextWidth * halfTextWidth));
    }
}
