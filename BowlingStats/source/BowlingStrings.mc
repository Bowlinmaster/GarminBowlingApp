import Toybox.Application;
import Toybox.Lang;

function bowlingString(resourceId as ResourceId) as String {
    return Application.loadResource(resourceId) as String;
}
