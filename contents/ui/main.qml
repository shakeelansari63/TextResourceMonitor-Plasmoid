import QtQuick 2.5
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts 1.1

// Item - the most basic plasmoid component, an empty container.
Item {
    id: main
    anchors.fill: parent

    // Full representation by default
    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    // Display Property
    property double dispPixelSize: 18

    // Text Metrics
    TextMetrics {
        id: cpuMetrics
        text: "CPU: 000%"
        font.pixelSize: dispPixelSize 
    }

    TextMetrics {
        id: ramMetrics
        text: "RAM: 00.00 MB / 00.00 MB"
        font.pixelSize: dispPixelSize 
    }

    TextMetrics {
        id: swapMetrics
        text: "SWAP: 00.00 MB / 00.00 MB"
        font.pixelSize: dispPixelSize 
    }

    // Set Layout 
    Layout.minimumWidth: cpuMetrics.width + ramMetrics.width + swapMetrics.width + 25
    Layout.preferredWidth: Layout.minimumWidth

    // Data Source
    PlasmaCore.DataSource {
        // Id for Resources
        id: res
        engine: "systemmonitor"
        interval: 500

        // Set Properties for Sources
        property string cpuLoad : "cpu/system/TotalLoad"
        property string ramApp : "mem/physical/application"
        property string ramUsed : "mem/physical/used"
        property string ramFree : "mem/physical/free"
        property string swapFree : "mem/swap/free"
        property string swapUsed : "mem/swap/used"

        property int totalWidth: 0

        // Usages
        property var usage: []

        // Connect all Data sources
        connectedSources: [cpuLoad, ramApp, ramUsed, ramFree, swapUsed, swapFree]

        // Getting Data
        onNewData: {

            // Collect Data
            if (data.value === undefined) {
                return
            }

            // CPU Load
            else if (sourceName === cpuLoad){
                // Update CPU Date
                cpuData.text = cpuMetrics.text;
                cpuData.text = 'CPU: ' + Math.round(data.value) + '%';
            }

            // Ram Used
            else if (sourceName === ramUsed){
                usage['RAMUSED'] = parseFloat(data.value);
            }

            // Ram Free
            else if (sourceName === ramFree){
                usage['RAMFREE'] = parseFloat(data.value);
            }

            // Ram Application
            else if (sourceName === ramApp) {
                var appMemory = parseInt(data.value);

                // Calculate Ram Percentage
                if (usage['RAMUSED'] && usage['RAMFREE']) {
                    var totalMemory = usage['RAMUSED'] + usage['RAMFREE'];

                    // Ram in Human readable Form
                    var ramMem = (appMemory / 1024) < 1024 ? Math.round(appMemory / 1024) + ' MB' : Math.round(appMemory * 100 / 1024 / 1024) / 100 + ' GB';

                    var totalRamMem = (totalMemory / 1024) < 1024 ? Math.round(totalMemory / 1024) + ' MB' : Math.round(totalMemory * 100 / 1024 / 1024) / 100 + ' GB';
                    // Ram Percentage
                    var ramPerc = Math.round(appMemory / totalMemory * 100) + '%';

                    // Update Data
                    ramData.text = 'RAM: ' + ramMem + ' / ' + totalRamMem;
                } else {

                    ramData.text = ramMetrics.text;
                }
            }

            // Swap Free
            else if (sourceName === swapFree){
                usage['SWAPFREE'] = parseFloat(data.value);
            }

            // Swap Used
            else if (sourceName === swapUsed){
                usage['SWAPUSED'] = parseFloat(data.value);

                if (usage['SWAPFREE']) {
                    // Calculate Total System Swap
                    var totalSwap = usage['SWAPUSED'] + usage['SWAPFREE'];

                    // Calculate Swap in Human Readable Form
                    var swapMem = (usage['SWAPUSED'] / 1024) < 1024 ? Math.round(usage['SWAPUSED'] / 1024) + ' MB' : Math.round(usage['SWAPUSED'] * 100 / 1024 / 1024) / 100 + ' GB';

                    // Total Swap in Human readable form
                    var totalSwapMem = (totalSwap / 1024) < 1024 ? Math.round(totalSwap / 1024) + ' MB' : Math.round(totalSwap * 100 / 1024 / 1024) / 100 + ' GB';

                    // Calculate Percentage of Swap
                    var swapPerc = Math.round(usage['SWAPUSED'] / totalSwap * 100) + '%';

                    // Swap Display
                    swapData.text = 'SWAP: ' + swapMem + ' / ' + totalSwapMem;
                } else {
                    swapData.text = swapMetrics.text;
                }
            }
        }
    }

    // Display Contenct

    Text {
        id: leftPad
        height: parent.height
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        id: cpuData
        text: ''
        height: parent.height
        width: cpuMetrics.width
        color: theme.textColor
        horizontalAlignment: Text.AlignLeft
        anchors.left: leftPad.right
        anchors.leftMargin: 5
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: dispPixelSize 
    }

    Text {
        id: ramData
        text: ''
        height: parent.height
        width: ramMetrics.width
        color: theme.textColor
        horizontalAlignment: Text.AlignLeft
        anchors.left: cpuData.right
        anchors.leftMargin: 10
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: dispPixelSize 
    }

    Text {
        id: swapData
        text: ''
        height: parent.height
        width: swapMetrics.width
        color: theme.textColor
        horizontalAlignment: Text.AlignLeft
        anchors.left: ramData.right
        anchors.leftMargin: 10
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: dispPixelSize 
    }
}
