//------------------------------------------------------------------------------

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtPositioning 5.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import ArcGIS.AppFramework.Runtime 1.0
import ArcGIS.AppFramework.Runtime.Controls 1.0



import "Helper.js" as Helper

App {
    id: app
    width: 300
    height: 500

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//BEGIN INITIALIZING SOME GLOBAL VARIABLES USED FOR VARIOUS ODDS AND ENDS

    //define global variable to hold last update date of tpk. Tried but did not manage to avoid this.
    property string tpkfilepath: ""

    //define global variable to hold the currently selected building, by ObjectID
    property var currentBuildingObjectID: ""

    //define relevant field names. Ultimately these should all be configurable.
    property string bldgLyr_nameField: "NAME"
    property string bldgLyr_bldgIdField: "BUILDING_NUMBER"

    property string lineLyr_bldgIdField: "BUILDING"
    property string lineLyr_floorIdField: "FLOOR"

    property string roomLyr_bldgIdField: "BUILDING"
    property string roomLyr_floorIdField: "FLOOR"
    property string roomLyr_roomIdField: "ROOM"

//END INITIALIZING SOME GLOBAL VARIABLES USED FOR VARIOUS ODDS AND ENDS
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//BEGIN DOWNOAD AND SYNC MECHANISM SETUP

    //Define place to store local geodatabase and declare FileInfo object.
    //Set up components for generate and sync functionality
    property string appItemId: app.info.itemId
    property string gdbPath: "~/ArcGIS/AppStudio/Data/" + appItemId + "/gdb.geodatabase"
    property string syncLogFolderPath: "~/ArcGIS/AppStudio/Data/" + appItemId
    property string updatesCheckfilePath: "~/ArcGIS/AppStudio/Data/" + appItemId + "/syncLog.txt"
    property string featuresUrl: "http://services.arcgis.com/8df8p0NlLFEShl0r/arcgis/rest/services/UMNTCCampusMini4/FeatureServer"
    FileInfo {
        id: gdbfile
        filePath: gdbPath

        function generategdb(){
            generateGeodatabaseParameters.initialize(serviceInfoTask.featureServiceInfo);
            generateGeodatabaseParameters.extent = map.extent;
            generateGeodatabaseParameters.returnAttachments = false;
            geodatabaseSyncTask.generateGeodatabase(generateGeodatabaseParameters, gdbPath);
        }
        function syncgdb(){
            gdb.path = gdbPath //if this is not set then function fails with "QFileInfo::absolutePath: Constructed with empty filename" message.
            gdbinfobuttontext.text = " Downloading updates now...this may take some time. "
            geodatabaseSyncTask.syncGeodatabase(gdb.syncGeodatabaseParameters, gdb);
        }
    }

    //use this file to keep track of when the app has synced last
    FileInfo {
        id: updatesCheckfile
        filePath: updatesCheckfilePath
    }
    FileFolder{
        id:syncLogFolder
        path: syncLogFolderPath
    }

    ServiceInfoTask{
        id: serviceInfoTask
        url: featuresUrl
        onFeatureServiceInfoStatusChanged: {
            if (featureServiceInfoStatus === Enums.FeatureServiceInfoStatusCompleted) {
                Helper.doorkeeper()
            } else if (featureServiceInfoStatus === Enums.FeatureServiceInfoStatusErrored) {
                Helper.preventGDBSync()
            }
        }
    }

    GenerateGeodatabaseParameters {
        id: generateGeodatabaseParameters
    }

    GeodatabaseSyncStatusInfo {
        id: syncStatusInfo
    }

    GeodatabaseSyncTask {
        id: geodatabaseSyncTask
        url: featuresUrl


        onGenerateStatusChanged: {
            if (generateStatus === Enums.GenerateStatusInProgress) {
                gdbinfobuttontext.text = " Downloading updates in progress...this may take some time. "
            } else if (generateStatus === Enums.GenerateStatusCompleted) {
                Helper.writeSyncLog()
                Helper.doorkeeper()
            } else if (generateStatus === GeodatabaseSyncTask.GenerateError) {
                gdbinfobuttontext.text = "Error: " + generateGeodatabaseError.message + " Code= "  + generateGeodatabaseError.code.toString() + " "  + generateGeodatabaseError.details;
            }
        }

        onSyncStatusChanged: {
            if (syncStatus === Enums.SyncStatusCompleted) {
                Helper.writeSyncLog()
                Helper.doorkeeper()
            }
            if (syncStatus === Enums.SyncStatusErrored)
                gdbinfobuttontext.text = "Error: " + syncGeodatabaseError.message + " Code= "  + syncGeodatabaseError.code.toString() + " "  + syncGeodatabaseError.details;
        }
    }

    //set up components for operational map layers: buildings, room-polygons, lines
    Geodatabase{
        id: gdb
        path: geodatabaseSyncTask.geodatabasePath
    }

    GeodatabaseFeatureTable {
        id: localLinesTable
        geodatabase: gdb.valid ? gdb : null
        featureServiceLayerId: 0
        onQueryFeaturesStatusChanged: {
            console.log("onQueryFeaturesStatusChanged localLinesTable")
        }
    }

    GeodatabaseFeatureTable {
        id: localRoomsTable
        geodatabase: gdb.valid ? gdb : null
        featureServiceLayerId: 1
        onQueryFeaturesStatusChanged: {
            console.log("onQueryFeaturesStatusChanged localRoomsTable")
        }
    }

    GeodatabaseFeatureTable {
        id: localBuildingsTable
        geodatabase: gdb.valid ? gdb : null
        featureServiceLayerId: 2
    }

    //define place to store local tile package and define FileFolder object
    property string tpkItemId : "0ae5d71749504e9784ac0d69ea27110f"
    FileFolder {
        id: tpkFolder
        path: "~/ArcGIS/AppStudio/Data/" + tpkItemId

        function addLayer(){
            var filesList = tpkFolder.fileNames("*.tpk");
            var newLayer = ArcGISRuntime.createObject("ArcGISLocalTiledLayer");
            var newFilePath = tpkFolder.path + "/" + filesList[0];
            newLayer.path = newFilePath;
            tpkfilepath = newFilePath;
            map.insertLayer(newLayer,0);//insert it at the bottom of the layer stack
            map.addLayer(newLayer)
            map.extent = newLayer.extent
        }

        function downloadThenAddLayer(){
            map.removeLayerByIndex(0)
            downloadTpk.download(tpkItemId);
        }
    }
    //instantiate FileInfo to read last modified date of tpk.
    FileInfo{
        id:tpkfile
        filePath: tpkfilepath
    }



    //Declare ItemPackage for downloading tile package
    ItemPackage {
        id: downloadTpk
        onDownloadStarted: {
            console.log("Download started")
            tpkinfobuttontext.text = "Download starting... 0%"
        }
        onDownloadProgress: {
            tpkinfobuttontext.text = "Download in progress... " + percentage +"%"
        }
        onDownloadComplete: {
            tpkFolder.addLayer();
            Helper.doorkeeper();
        }
        onDownloadError: {
            tpkinfobuttontext.text = "Download failed"
        }
    }

//END DOWNOAD AND SYNC MECHANISM SETUP
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//BEGIN MAP AND ON-MAP COMPONENTS

    Rectangle{
        id:topbar
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:parent.width
        height: zoomButtons.width * 1.4
        color: "darkblue"

        StyleButton{
            id: welcomemenu
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height:parent.height * 0.9
            anchors.leftMargin: 2
            width:height
            iconSource: "images/actions.png"
            onClicked: {
                console.log("click")
                //destory and re-fetch this info to ensure device connectiviy and feature service avaiability before allowing user to kick-off sync opeation
                //serviceInfoTask.featureServiceInfo.destroy()//test whetehr ths idea works
                //serviceInfoTask.fetchFeatureServiceInfo()//this is a bit buggy in that it takes a while to fail. Maybe re-design rocess to by default prevent sync until readiness is verified
                proceedtomaptext.text  = "Back to Map"
                welcomemenucontainer.visible = true
                Helper.doorkeeper()
            }
        }
        Text{
            id:titletext
            text:"Floor Plan Viewer"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height:parent.height
            width: parent.width - height * 2
            fontSizeMode: Text.Fit
            minimumPixelSize: 10
            font.pixelSize: 72
            clip:true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment:  Text.AlignHCenter
            color:"white"
            font.weight: Font.DemiBold
        }

        StyleButton{
            id: searchmenu
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height:parent.height * 0.9
            anchors.rightMargin: 2
            width:height
            iconSource: "images/search.png"
            onClicked: {
                console.log("click searchmenu")
                tpkFolder.writeTextFile("test.txt","good evening")
            }
        }
    }

    Rectangle{
        id:mapcontainer
        height: parent.height - topbar.height
        width: parent.width
        anchors.top: topbar.bottom


        Map{
            id: map
            anchors.top: parent.top
            anchors.bottom: mapcontainer.bottom
            anchors.left: mapcontainer.left
            anchors.right: mapcontainer.right
            focus: true
            rotationByPinchingEnabled: true
            positionDisplay {
                positionSource: PositionSource {
                }
            }

            StyleButton {
                id: infobutton
                iconSource: "images/info1.png"
                width: zoomButtons.width
                height: width
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: app.height * 0.01
                anchors.bottomMargin: 2
                onClicked: {
                    fader.start();
                    console.log("infobutton")
                    infocontainer.visible = true
                    //infobuttoncontainer.visible = false
                }
            }
            ZoomButtons {
                id:zoomButtons
                anchors.left: parent.left
                anchors.bottom: infobutton.top
                anchors.margins: app.height * 0.01
            }
            StyleButton {
                id: buttonRotateCounterClockwise
                iconSource: "images/rotate_clockwise.png"
                width: zoomButtons.width
                height: width
                anchors.bottom: zoomButtons.top
                anchors.left: zoomButtons.left
                anchors.bottomMargin: 2
                onClicked: {
                    fader.start();
                    map.mapRotation -= 22.5;
                }
            }
            StyleButton{
                id: northarrowbackgroundbutton
                anchors {
                    right: buttonRotateCounterClockwise.right
                    bottom: buttonRotateCounterClockwise.top
                }
                visible: map.mapRotation != 0
            }
            NorthArrow{
                width: northarrowbackgroundbutton.width - 4
                height: northarrowbackgroundbutton.height - 4

                anchors {
                    horizontalCenter: northarrowbackgroundbutton.horizontalCenter
                    verticalCenter: northarrowbackgroundbutton.verticalCenter
                }
                visible: map.mapRotation != 0
            }

            Rectangle{
                id:floorcontainer
                width: zoomButtons.width
                anchors.bottom: zoomButtons.bottom
                anchors.right: map.right
                anchors.margins: app.height * 0.01
                height: 300
                color:"pink"
                ListView{
                    id:floorlistview
                }
            }

            Rectangle{
               id:infocontainer
               height: infobutton.height
               anchors.left: infobutton.left
               anchors.right: parent.right
               anchors.top: infobutton.top
               anchors.rightMargin: app.height * 0.01
               color: infobutton.backgroundColor
               border.color: infobutton.borderColor
               radius: 4


               Row{
                   id:inforow
                   height: parent.height - 2
                   width: parent.width - 2
                   anchors.horizontalCenter: parent.horizontalCenter
                   anchors.verticalCenter: parent.verticalCenter
                   spacing: app.height * 0.01

                   StyleButton{
                       id:closeinfobutton
                       height:parent.height
                       width: height
                       iconSource: "images/close.png"
                       borderColor: infobutton.backgroundColor
                       focusBorderColor: infobutton.backgroundColor
                       hoveredColor: infobutton.backgroundColor
                       anchors.verticalCenter: parent.verticalCenter
                       onClicked: {
                           console.log("click")
                           infocontainer.visible = false
                           //infobuttoncontainer.visible = true
                       }
                   }
                   Flickable{
                       id: infoflickable
                       height:infocontainer.height - app.height * 0.01
                       width:infocontainer.width - 10 - closeinfobutton.width * 2
                       contentWidth: infotext.width
                       contentHeight: infotext.height
                       flickableDirection: Flickable.VerticalFlick
                       anchors.verticalCenter: closeinfobutton.verticalCenter
                       clip: true

                       Text{
                           id:infotext
                           text: "Some text messages displayed here."
                           color: "black"
                           wrapMode: Text.Wrap
                           width:infocontainer.width - closeinfobutton.width
                           font.pointSize: 14
                           elide: Text.ElideLeft
                           anchors.verticalCenter: parent.verticalCenter
                       }
                   }
                   StyleButton{
                       id:zoomtoinfobutton
                       height:parent.height
                       width: height
                       iconSource: "images/signIn.png"
                       borderColor: infobutton.backgroundColor
                       focusBorderColor: infobutton.backgroundColor
                       hoveredColor: infobutton.backgroundColor
                       anchors.verticalCenter: parent.verticalCenter
                       onClicked: {
                           console.log("click")
                           console.log(currentBuildingObjectID)
                           map.zoomTo(localBuildingsLayer.featureTable.feature(currentBuildingObjectID).geometry)
                       }
                   }

               }

            }


            FeatureLayer {
                id: localLinesLayer
                featureTable: localLinesTable
            }
            FeatureLayer {
                id: localRoomsLayer
                featureTable: localRoomsTable
            }
            FeatureLayer {
                id: localBuildingsLayer
                featureTable: localBuildingsTable
            }
            onMouseClicked:{
                Helper.selectBuildingOnMap(mouse.x, mouse.y);
            }

        }

    }


//END MAP AND ON-MAP COMPONENTS
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//BEGIN WELCOMEMENU
    Rectangle{
        id:welcomemenucontainer
        anchors.top: app.top
        anchors.bottom: app.bottom
        anchors.right: app.right
        anchors.left: app.left

        Rectangle{
            id:titlecontainer
            height: welcomemenucontainer.height / 4
            width: welcomemenucontainer.width
            anchors.horizontalCenter:parent.horizontalCenter
            anchors.top: parent.top
            color:"darkblue"
            border.width:1
            border.color:"white"

            Text{
                id:apptitle
                anchors.top: parent.top
                width:parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                clip:true
                horizontalAlignment:Text.AlignHCenter
                color: "white"
                font.bold: Font.Bold
                font.underline: true
                text: "\n" + "App Title Goes Here"
            }

            Text{
                id:appdescription
                anchors.top: apptitle.bottom
                width:parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                clip:true
                horizontalAlignment:Text.AlignHCenter
                color: "white"
                text: "\n"+"App Description Goes Here. App Description Goes Here. App Description Goes Here. App Description Goes Here."
            }
        }

        Rectangle{
            id:gdbinfocontainer
            height: welcomemenucontainer.height / 4
            width: welcomemenucontainer.width
            anchors.horizontalCenter:parent.horizontalCenter
            anchors.top: titlecontainer.bottom
            color:"darkblue"
            border.width:1
            border.color:"white"

            ImageButton{
                id: gdbinfoimagebutton
                source:"images/gallery-white.png"
                height: gdbinfocontainer.height / 1.5
                width: height
                anchors.top:gdbinfocontainer.top
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    console.log("click")
                    console.log("gdbfile.generategdb()")
                    if (gdbfile.exists){
                            gdbfile.syncgdb();
                            }
                    else {
                        gdbfile.generategdb();
                    }
                }
            }
            Text{
                id: gdbinfobuttontext
                anchors.top:gdbinfoimagebutton.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color:"white"
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width:parent.width
                clip:true
                horizontalAlignment:Text.AlignHCenter
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    console.log("click")
                    console.log("gdbfile.generategdb()")
                    if (gdbfile.exists){
                            gdbfile.syncgdb();
                            }
                    else {
                        gdbfile.generategdb();
                    }
                }
            }
        }

        Rectangle{
            id:tpkinfocontainer
            height: welcomemenucontainer.height / 4
            width: welcomemenucontainer.width
            anchors.horizontalCenter:parent.horizontalCenter
            anchors.top: gdbinfocontainer.bottom
            color:"darkblue"
            border.width:1
            border.color:"white"

            ImageButton{
                id: tpkinfoimagebutton
                source:"images/gallery-white.png"
                height: tpkinfocontainer.height / 1.5
                width: height
                anchors.top:tpkinfocontainer.top
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    console.log("click")
                    tpkFolder.downloadThenAddLayer()

                }
            }
            Text{
                id: tpkinfobuttontext
                anchors.top:tpkinfoimagebutton.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color:"white"
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width:parent.width
                clip:true
                horizontalAlignment:Text.AlignHCenter
            }
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    console.log("click middlebutton")
                    tpkFolder.removeFolder(tpkItemId, 1) //delete the tpk from local storage
                    tpkFolder.downloadThenAddLayer() //download and add the tpk layer
                }
            }

        }


        Rectangle{
            id:proceedbuttoncontainer
            height: welcomemenucontainer.height / 4
            width: welcomemenucontainer.width
            anchors.right:parent.right
            anchors.top: tpkinfocontainer.bottom
            color:"green"
            border.width:1
            border.color:"white"

            function proceedToMap(){
                console.log("proceedToMap")
                Helper.addAllLayers()
                welcomemenucontainer.visible = false
            }

            ImageButton{
                id: proceedtomapimagebutton
                source:"images/gallery-white.png"
                height: proceedbuttoncontainer.height / 1.5
                width: height
                anchors.top:proceedbuttoncontainer.top
                anchors.horizontalCenter: proceedbuttoncontainer.horizontalCenter
                onClicked: {
                    proceedbuttoncontainer.proceedToMap();
                }
            }

            Text{
                id:proceedtomaptext
                anchors.top:proceedtomapimagebutton.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                color:"white"
                text: "Go to Map"
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width:parent.width
                clip:true
                horizontalAlignment:Text.AlignHCenter
            }

            MouseArea{
                id:proceedbuttoncontainermousearea
                anchors.fill: proceedbuttoncontainer
                onClicked: {
                    proceedbuttoncontainer.proceedToMap();
                }
            }
        }
    }

    Component.onCompleted: {
        tpkFolder.addLayer()
        Helper.doorkeeper()
        serviceInfoTask.fetchFeatureServiceInfo();
        console.log("app load complete")

    }

}

