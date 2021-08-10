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
        text: " 0%"
        font.pixelSize: dispPixelSize 
    }

    TextMetrics {
        id: ramMetrics
        text: " 00.0 MB / 00.0 MB"
        font.pixelSize: dispPixelSize 
    }

    TextMetrics {
        id: swapMetrics
        text: " 00.0 MB / 00.0 MB"
        font.pixelSize: dispPixelSize 
    }

    TextMetrics {
        id: netMetrics
        text: " ↓ 00.00 MiB/s  ↑ 00.00 MiB/s "
        font.pixelSize: dispPixelSize
    }

    // Set Layout 
    Layout.minimumWidth: cpuMetrics.width + ramMetrics.width + swapMetrics.width + netMetrics.width + (cpuMetrics.height * 4) + 55
    Layout.preferredWidth: Layout.minimumWidth

    // Data Source
    PlasmaCore.DataSource {
        // Id for Resources
        id: res
        engine: "systemmonitor"
        interval: 800

        // Set Properties for Sources
        property string cpuLoad : "cpu/system/TotalLoad"
        property string ramApp : "mem/physical/application"
        property string ramUsed : "mem/physical/used"
        property string ramFree : "mem/physical/free"
        property string swapFree : "mem/swap/free"
        property string swapUsed : "mem/swap/used"

        // Property for Network Speed
        property var netSpeeds : [];

        property int totalWidth: 0

        // Usages
        property var usage: []

        // Connect all Data sources
        connectedSources: [cpuLoad, ramApp, ramUsed, ramFree, swapUsed, swapFree]

        // Connect Network Sources
        onSourceAdded: {
            var match = source.match(/^network\/interfaces\/(\w+)\/(receiver|transmitter)\/data$/)

            if(match) {
                connectSource(source)
            }
        }

        // Disconnect Network Source
        onSourceRemoved: {
            var match = source.match(/^network\/interfaces\/(\w+)\/(receiver|transmitter)\/data$/)

            if(match) {
                disconnectSource(source)
            }
        }

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
                cpuData.text = ' ' + Math.round(data.value) + '%';
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
                    ramData.text = ' ' + ramMem + ' / ' + totalRamMem;
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
                    swapData.text = ' ' + swapMem + ' / ' + totalSwapMem;
                } else {
                    swapData.text = swapMetrics.text;
                }
            }

            // Network Data
            else {
                var matched = sourceName.match(/^network\/interfaces\/(\w+)\/(receiver|transmitter)\/data$/)
                var dataChanged = false

                var interfaceName = matched[1]

                // Only WLP and ETH interfaces
                if (interfaceName.substr(0, 3) === 'wlp' || interfaceName.substr(0, 3)[0] === 'eth') {

                    // If interface does not exist, then add empty data
                    if (netSpeeds[ interfaceName ] === undefined) {
                        netSpeeds[ interfaceName ] = {up: 0, down: 0}
                    }

                    // Save speed date in temp variable
                    var tempSpeeds = netSpeeds
                    var speedValue = parseFloat(data.value)

                    if (matched[2] === 'receiver') {
                        tempSpeeds[interfaceName].down = speedValue
                        dataChanged = true

                    } else if (matched[2] === 'transmitter') {
                        tempSpeeds[interfaceName].up = speedValue
                        dataChanged = true
                    }
                }

                // Update Data if we have any new data
                if (dataChanged) {
                    // Set Network speed form Temp Speed
                    netSpeeds = tempSpeeds

                    var down = parseFloat(0)
                    var up = parseFloat(0)

                    // Loop over each interface and sum the speed
                    for (var inf in netSpeeds) {
                        down += netSpeeds[inf].down
                        up += netSpeeds[inf].up
                    }

                    // Update widget text
                    var output = ' ↓ ' + convertNetworkSpeed(down) + ' ' + convertNetworkUnit(down) + '  ↑ ' + convertNetworkSpeed(up) + ' ' + convertNetworkUnit(up)
                    netData.text = output
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

    Image {
        id: cpuImg
        source: 'cpu.svg'
        height: parent.height * 0.8
        width: parent.height * 0.8
        anchors.left: leftPad.right
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        verticalAlignment: Image.AlignVCenter
        horizontalAlignment: Image.AlignLeft
    }

    Text {
        id: cpuData
        text: ''
        height: parent.height
        width: cpuMetrics.width
        color: theme.textColor
        horizontalAlignment: Text.AlignLeft
        anchors.left: cpuImg.right
        anchors.leftMargin: 5
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: dispPixelSize 
    }

    Image {
        id: ramImg
        source: 'ram.svg'
        height: parent.height * 0.8
        width: parent.height * 0.8
        anchors.left: cpuData.right
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        verticalAlignment: Image.AlignVCenter
        horizontalAlignment: Image.AlignLeft
    }

    Text {
        id: ramData
        text: ''
        height: parent.height
        width: ramMetrics.width
        color: theme.textColor
        horizontalAlignment: Text.AlignLeft
        anchors.left: ramImg.right
        anchors.leftMargin: 5
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: dispPixelSize 
    }

    Image {
        id: swapImg
        source: 'swap.svg'
        height: parent.height * 0.8
        width: parent.height * 0.8
        anchors.left: ramData.right
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        verticalAlignment: Image.AlignVCenter
        horizontalAlignment: Image.AlignLeft
    }

    Text {
        id: swapData
        text: ''
        height: parent.height
        width: swapMetrics.width
        color: theme.textColor
        horizontalAlignment: Text.AlignLeft
        anchors.left: swapImg.right
        anchors.leftMargin: 5
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: dispPixelSize 
    }

    Image {
        id: netImg
        source: 'net.svg'
        height: parent.height * 0.8
        width: parent.height * 0.8
        anchors.left: swapData.right
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        verticalAlignment: Image.AlignVCenter
        horizontalAlignment: Image.AlignLeft
    }

    Text {
        id: netData
        text: ''
        height: parent.height
        width: netwMetrics.width
        color: theme.textColor
        horizontalAlignment: Text.AlignLeft
        anchors.left: netImg.right
        anchors.leftMargin: 5
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: dispPixelSize
    }

    // Supportive Functions
    function convertNetworkSpeed(val) {
        if (val >= 1048576) {
            val /= 1048576
        }
        else if (val >= 1024) {
            val /= 1024
        }
        else if (val < 1) {
            val *= 1024
        }

        return val.toFixed(1)
    }

    function convertNetworkUnit(val) {
        if (val >= 1048576) {
            return 'GB/s'
        }
        else if (val >= 1024) {
            return 'MB/s'
        }
        else if (val >= 1) {
            return 'KB/s'
        }
        else {
            return 'B/s'
        }
    }
}
