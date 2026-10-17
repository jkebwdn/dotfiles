import QtQuick
import QtTest
import Quickshell
import "../../.config/quickshell/magi/plugins/bar/controlcentre" as Centre
import "../../.config/quickshell/magi/services" as Services
ShellRoot {
    FloatingWindow { visible:true; implicitWidth:500; implicitHeight:400
        Centre.ProfileHeader { id:profile; width:400; height:implicitHeight }
    }
    Timer { id:finish; interval:100; onTriggered:Qt.quit() }
    TestCase {
        name:"WeatherService"; when:Services.Settings.ready
        function test_weather() {
            try {
                Services.Settings.resetSection("weather");Services.Weather.activate();wait(50)
                compare(Services.Weather.summary,"");verify(!Services.Weather.refreshing)
                Services.Settings.setValue("weather","enabled",true);wait(50)
                compare(Services.Weather.diagnostic,"Set a weather location")
                Services.Settings.setValue("weather","location","Fixture town")
                tryCompare(Services.Weather,"summary","Rainy · 12°C",4000)
                compare(findChild(profile,"profileWeather").text,"Rainy · 12°C")
                verify(Services.Weather.resolvedLocation.indexOf("Fixture town")>=0)
                Services.Settings.setValue("weather","units","imperial")
                tryCompare(Services.Weather,"summary","Rainy · 54°F",4000)
                compare(findChild(profile,"profileWeather").text,"Rainy · 54°F")
                // Changed location during an active request: discard stale response and coalesce.
                Services.Settings.setValue("weather","location","First town")
                tryCompare(Services.Weather,"refreshing",true,2000)
                Services.Settings.setValue("weather","location","Final town")
                tryVerify(()=>Services.Weather.resolvedLocation.indexOf("Final town")>=0,4000)
                compare(Services.Weather.summary,"Rainy · 54°F")
                Services.Settings.setValue("weather","location","Timeout")
                tryCompare(Services.Weather,"diagnostic","Weather refresh unavailable",4000)
                compare(Services.Weather.summary,"")
                compare(findChild(profile,"profileWeather").text,"Weather unavailable")
                Services.Settings.setValue("weather","enabled",false);wait(50)
                compare(Services.Weather.summary,"");verify(!Services.Weather.refreshing)
                compare(Services.Weather.diagnostic,"Weather is disabled")
                const avatar=findChild(profile,"runtimeAvatar"),stack=findChild(profile,"profileTextStack")
                compare(profile.height,Math.max(avatar.height,stack.implicitHeight)+profile.contentPadding*2)
                console.log("Weather service PASS")
            } catch(error) { console.error("FAIL:",error,error.stack,Services.Weather.diagnostic,Services.Weather.response,Services.Weather.eligible,Services.Weather.pending) }
            finally { finish.start() }
        }
    }
}
