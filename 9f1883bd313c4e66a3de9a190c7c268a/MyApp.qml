//------------------------------------------------------------------------------

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtPositioning 5.3
import QtQuick.Controls.Styles 1.4 //styling the search box per http://doc.qt.io/qt-5/qml-qtquick-controls-styles-textfieldstyle.html

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import ArcGIS.AppFramework.Runtime 1.0
import ArcGIS.AppFramework.Runtime.Controls 1.0
import ArcGIS.AppFramework.Runtime.Dialogs 1.0



import "Helper.js" as Helper

App {
    id: app
    width: 300
    height: 500

    UserCredentials {
        id: userCredentials
        userName: myUsername
        password: myPassword

        onError: console.log("ERROR")
        onTokenChanged: console.log("token changed")
        //onAuthenticatingHostChanged: consolelog("AuthenticatingHostChanged")
        onPasswordChanged: console.log("PasswordChanged")
        //onTypeChanged: console.log("TypeChanged")
    }

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//BEGIN INITIALIZING SOME GLOBAL VARIABLES USED FOR VARIOUS ODDS AND ENDS

    //define variables to hold the username and password
    property string myUsername: ""
    property string myPassword: ""

    //define global variable to hold last update date of tpk. Tried but did not manage to avoid this.
    property string tpkfilepath: ""

    //define global variable to hold the currently selected building, by ObjectID
    property var currentBuildingObjectID: ""
    //define global variable to hold the currently selected building id. used for communication between Helper functions
    property var currentBuildingID: ""

    //define global variable to hold list of buildings for search menu
    property var allBlgdList: []

    //define relevant field names. Ultimately these should all be configurable.
    property string bldgLyr_nameField: "NAME"
    property string bldgLyr_bldgIdField: "BUILDING_NUMBER"

    property string lineLyr_bldgIdField: "BUILDING"
    property string lineLyr_floorIdField: "FLOOR"
    property string lineLyr_sortField: "OBJECTID"

    property string roomLyr_bldgIdField: "BUILDING"
    property string roomLyr_floorIdField: "FLOOR"
    property string roomLyr_roomIdField: "ROOM"

//END INITIALIZING SOME GLOBAL VARIABLES USED FOR VARIOUS ODDS AND ENDS
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//BEGIN DOWNOAD AND SYNC MECHANISM SETUP

    //Define place to store local geodatabase
    //Set up components for generate, sync, and remove functionality
    property string appItemId: app.info.itemId
    property string gdbPath: "~/ArcGIS/AppStudio/Apps/" + appItemId + "/Data/gdb.geodatabase"
    property string syncLogFolderPath: "~/ArcGIS/AppStudio/Apps/" + appItemId + "/Data"
    property string updatesCheckfilePath: "~/ArcGIS/AppStudio/Apps/" + appItemId + "/Data/syncLog.txt"
    property string nextTimeDeleteGDBfilePath: "~/ArcGIS/AppStudio/Apps/" + appItemId + "/Data/nextTimeDeleteGDB.txt"
    property string featuresUrl: "http://services.arcgis.com/8df8p0NlLFEShl0r/arcgis/rest/services/UMNTCCampusMini4/FeatureServer"

    FileInfo {
        id: nextTimeDeleteGDBfile
        filePath: nextTimeDeleteGDBfilePath
    }

    FileInfo {
        id: gdbfile
        //filePath: gdbPath
        filePath: if (nextTimeDeleteGDBfile.exists == true){"null"} else {gdbPath}


        function generategdb(){
            generateGeodatabaseParameters.initialize(serviceInfoTask.featureServiceInfo);
            generateGeodatabaseParameters.extent = map.extent;
            generateGeodatabaseParameters.returnAttachments = false;
            geodatabaseSyncTask.generateGeodatabase(generateGeodatabaseParameters, gdbPath);
            proceedbuttoncontainer.color = "red"
            proceedbuttoncontainermousearea.enabled = false
            proceedtomapimagebutton.enabled = false
        }
        function syncgdb(){
            gdb.path = gdbPath //if this is not set then function fails with "QFileInfo::absolutePath: Constructed with empty filename" message.
            gdbinfobuttontext.text = " Downloading updates now...this may take some time. "
            geodatabaseSyncTask.syncGeodatabase(gdb.syncGeodatabaseParameters, gdb);
            proceedbuttoncontainer.color = "red"
            proceedbuttoncontainermousearea.enabled = false
            proceedtomapimagebutton.enabled = false
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

        credentials: userCredentials

        onFeatureServiceInfoStatusChanged: {
            if (featureServiceInfoStatus === Enums.FeatureServiceInfoStatusCompleted) {
                Helper.doorkeeper()
                userNameField.visible = false
                passwordField.visible = false
                signInButton.visible = false
                signedInButton.visible = true
                gdbinfocontainer.border.color = "white"
                gdbinfocontainer.border.width = 1
                gdbinfocontainer.update()
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
                gdbfile.syncgdb();//a workaround. can only get layers to shown up in map after sync. not after initial generate.
            } else if (generateStatus === GeodatabaseSyncTask.GenerateError) {
                gdbinfobuttontext.text = "Error: " + generateGeodatabaseError.message + " Code= "  + generateGeodatabaseError.code.toString() + " "  + generateGeodatabaseError.details + "  Make sure you have internet connectivity and are signed in. ";
            }
        }

        onSyncStatusChanged: {
            if (syncStatus === Enums.SyncStatusCompleted) {
                Helper.writeSyncLog()
                Helper.doorkeeper()
            }
            if (syncStatus === Enums.SyncStatusErrored)
                gdbinfobuttontext.text = "Error: " + syncGeodatabaseError.message + " Code= "  + syncGeodatabaseError.code.toString() + " "  + syncGeodatabaseError.details + "  Make sure you have internet connectivity and are signed in. " ;
                proceedbuttoncontainer.color = "green"
                proceedbuttoncontainermousearea.enabled = true
                proceedtomapimagebutton.enabled = true
        }
    }

    //set up components for operational map layers: buildings, room-polygons, lines
    Geodatabase{
        id: gdb
        path: if (nextTimeDeleteGDBfile.exists == true){"null"} else {gdbPath}
    }

    GeodatabaseFeatureTable {
        id: localLinesTable
        geodatabase: gdb.valid ? gdb : null
        featureServiceLayerId: 0
        onQueryFeaturesStatusChanged: {
            console.log("onQueryFeaturesStatusChanged localLinesTable")
            if (queryFeaturesStatus === Enums.QueryFeaturesStatusCompleted) {
                Helper.populateFloorListView(queryFeaturesResult.iterator, currentBuildingID , lineLyr_sortField)
            }
        }
    }

    GeodatabaseFeatureTable {
        id: localRoomsTable
        geodatabase: gdb.valid ? gdb : null
        featureServiceLayerId: 1
    }

    GeodatabaseFeatureTable {
        id: localBuildingsTable
        geodatabase: gdb.valid ? gdb : null
        featureServiceLayerId: 2
        onQueryFeaturesStatusChanged: {
            if (queryFeaturesStatus === Enums.QueryFeaturesStatusCompleted) {
                Helper.buildAllBlgdList(queryFeaturesResult.iterator)
                console.log("Helper.buildAllBlgdList(queryFeaturesResult.iterator)")
                }
        }
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
            proceedbuttoncontainermousearea.enabled = false
            proceedtomapimagebutton.enabled = false
            proceedbuttoncontainer.color = "red"
        }
        onDownloadComplete: {
            tpkFolder.addLayer();
            console.log(tpkFolder.path)
            Helper.doorkeeper();
        }
        onDownloadError: {
            tpkinfobuttontext.text = "Download failed"
            Helper.doorkeeper();
        }
    }

//END DOWNLOAD AND SYNC MECHANISM SETUP
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
            visible: if(welcomemenucontainer.visible == true || searchmenucontainer.visible ==true){false} else {true}
            iconSource: "images/actions.png"
            onClicked: {
                console.log("click")
                if (searchmenucontainer.visible != true){
                    proceedtomaptext.text  = "Back to Map"
                    welcomemenucontainer.visible = true
                    Helper.doorkeeper()
                }
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
            visible: if (welcomemenucontainer.visible == true){false} else {true}
            iconSource: if (searchmenucontainer.visible === true){"images/close.png"} else{"images/search.png"}
            onClicked: {
                console.log("click searchmenu")
                if (welcomemenucontainer.visible != true){
                    if (searchmenucontainer.visible === true){
                        searchmenucontainer.visible = false
                    } else{
                        Helper.reloadFullBldgListModel()
                        searchmenucontainer.visible = true
                    }
                }
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
                    infotext.text = "Select a building via the map or the search menu."
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
                height: ((floorListView.count * width) > (mapcontainer.height - zoomButtons.width*1.5)) ? (mapcontainer.height - zoomButtons.width*1.5)  :  (floorListView.count * width)
                color: zoomButtons.borderColor
                border.color: zoomButtons.borderColor
                border.width: zoomButtons.borderWidth
                visible: false

                ListView{
                    id:floorListView
                    anchors.fill: parent
                    model:floorListModel
                    delegate:floorListDelegate
                    verticalLayoutDirection : ListView.BottomToTop
                    highlight:
                        Rectangle {
                                color: "transparent";
                                radius: 4;
                               border.color: "blue";
                                border.width: 5;
                                z : 98;}
                    focus: true
                    clip:true
                    visible: parent
                }

                ListModel {
                    id:floorListModel
                    ListElement {
                        Floor: ""
                    }
                }
                Component {
                    id: floorListDelegate
                    Item {
                        width: zoomButtons.width
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle{
                            anchors.fill:parent
                            border.color: zoomButtons.borderColor
                            color:zoomButtons.backgroundColor
                            anchors.margins: 1
                        }

                        Column {
                            Text { text: Floor}
                            anchors.centerIn:parent

                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                floorListView.currentIndex = index;
                                Helper.setFloorFilters(index);
                                    }
                        }
                    }
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
               clip: true


               Row{
                   id:inforow
                   height: parent.height - 2
                   width: parent.width - 2
                   anchors.horizontalCenter: parent.horizontalCenter
                   anchors.verticalCenter: parent.verticalCenter
                   spacing: 2

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
                           floorcontainer.visible = false
                           currentBuildingObjectID = ""
                           currentBuildingID = ""
                           localBuildingsLayer.clearSelection();
                           Helper.hideAllFloors();
                       }
                   }
                   Text{
                       id:infotext
                       text: "Some text messages displayed here."
                       color: "black"
                       wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                       fontSizeMode: Text.Fit
                       minimumPointSize: 12
                       font.pointSize: 16
                       clip:true
                       width:infocontainer.width - closeinfobutton.width - zoomtoinfobutton.width - 4
                       anchors.verticalCenter: parent.verticalCenter
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
                id: localBuildingsLayer
                featureTable: localBuildingsTable
                selectionColor: "white"
                enableLabels: true
            }
                onMouseClicked:{
                Helper.selectBuildingOnMap(mouse.x, mouse.y);
                }
            FeatureLayer {
                id: localRoomsLayer
                featureTable: localRoomsTable
                definitionExpression: "OBJECTID < 0"
                enableLabels: true
            }
            FeatureLayer {
                id: localLinesLayer
                featureTable: localLinesTable
                definitionExpression: "OBJECTID < 0"
                enableLabels: true
            }
        }

    }


//END MAP AND ON-MAP COMPONENTS
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//BEGIN WELCOMEMENU
    Rectangle{
        id: welcomemenucontainer
        anchors.top: mapcontainer.top
        anchors.bottom: app.bottom
        anchors.right: app.right
        anchors.left: app.left
        color:"lightgrey"

        Rectangle{
            id:titlecontainer
            height: welcomemenucontainer.height / 5
            width: welcomemenucontainer.width
            anchors.left:parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            color:"white"
            anchors.margins: 6
            border.width: 1
            border.color: "grey"
            Text{
                id:appdescription
                anchors.top: apptitle.bottom
                height: parent.height
                width:parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                clip:true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment:Text.AlignHCenter
                color: "black"
                fontSizeMode: Text.Fit
                minimumPointSize: 4
                font.pointSize: 10
                text: "App Description Goes Here. App Description Goes Here. App Description Goes Here. App Description Goes Here."
            }
        }
        Rectangle{
            id: signInDialogContainer
            height: welcomemenucontainer.height / 5
            width: welcomemenucontainer.width
            anchors.left:parent.left
            anchors.right: parent.right
            anchors.top: titlecontainer.bottom
            color:"white"
            anchors.margins: 6
            visible:true
            border.width: 1
            border.color: "grey"
            TextField{
                    id: userNameField
                    width: parent.width
                    height:parent.height * 0.25
                    focus: true
                    visible: true
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5
                    placeholderText :"ArcGIS Online Username"
                    style: TextFieldStyle {
                        textColor: "black"
                        background: Rectangle {
                            radius: 2
                            border.color: "#333"
                            border.width: 1
                        }
                    }
            }
            TextField{
                    id: passwordField
                    width: parent.width
                    height:parent.height * 0.25
                    focus: true
                    visible: true
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: userNameField.bottom
                    anchors.margins: 5
                    placeholderText :"ArcGIS Online Password"
                    echoMode: TextInput.Password
                    style: TextFieldStyle {
                        textColor: "black"
                        background: Rectangle {
                            radius: 2
                            border.color: "#333"
                            border.width: 1
                        }
                    }
                    }
            Button{
                id: signInButton
                visible: true
                height: parent.height / 3
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: passwordField.bottom
                anchors.margins: 1
                style: ButtonStyle {
                    label: Text {
                       renderType: Text.NativeRendering
                       verticalAlignment: Text.AlignVCenter
                       horizontalAlignment: Text.AlignHCenter
                       color: "white"
                       text: "  Sign In  "
                       font.weight: Font.DemiBold
                     }
                        background: Rectangle {
                            border.width: control.activeFocus ? 2 : 1
                            border.color: "#888"
                            radius: 2
                            color: "darkblue"
                        }
                }
                enabled: if (userNameField.length > 0 && passwordField.length > 0){true} else {false}
                onClicked: {console.log(userNameField.text);
                            console.log(passwordField.text);
                            myUsername = userNameField.text
                            myPassword = passwordField.text
                            userCredentials.userName = myUsername
                            userCredentials.password = myPassword
                            serviceInfoTask.fetchFeatureServiceInfo()
                            }
            }

            Button{
                id: signedInButton
                visible: false
                height: parent.height / 3
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                anchors.margins: 1
                style: ButtonStyle {
                    label: Text {
                       renderType: Text.NativeRendering
                       verticalAlignment: Text.AlignVCenter
                       horizontalAlignment: Text.AlignHCenter
                       color: "white"
                       text: "Signed in as " + myUsername
                       font.weight: Font.DemiBold
                     }
                        background: Rectangle {
                            border.width: control.activeFocus ? 2 : 1
                            border.color: "#888"
                            radius: 2
                            color: "darkblue"
                        }
                }
            }
        }

        Rectangle{
            id:gdbinfocontainer
            height: welcomemenucontainer.height / 5
            width: welcomemenucontainer.width
            anchors.right:parent.right
            anchors.left: parent.left
            anchors.top: signInDialogContainer.bottom
            color:"white"
            anchors.margins: 6
            border.width: 1
            border.color: "grey"

            Text{
                id: gdbinfobuttontext
                anchors.bottom:parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                color:"black"
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width:parent.width
                height: parent.height / 2
                clip:true
                horizontalAlignment:Text.AlignHCenter
                fontSizeMode: Text.Fit
                minimumPointSize: 4
                font.pointSize: 10
                verticalAlignment: Text.AlignVCenter

            }
            Button{
                id: gdbinfoimagebutton
                height: parent.height / 3
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.margins: 1
                style: ButtonStyle {
                    label: Text {
                       renderType: Text.NativeRendering
                       verticalAlignment: Text.AlignVCenter
                       horizontalAlignment: Text.AlignHCenter
                       color: "white"
                       text: "  Download Now  "
                       font.weight: Font.DemiBold
                     }
                        background: Rectangle {
                            border.width: control.activeFocus ? 2 : 1
                            border.color: "#888"
                            radius: 2
                            color: "darkblue"
                        }
                }
                onClicked: {
                    if (gdbfile.exists){
                            gdbfile.syncgdb();
                            }
                    else {
                        gdbfile.generategdb();
                    }
                }
            }
            Button{
                id: gdbDeleteButton
                anchors.top: gdbinfoimagebutton.top
                anchors.bottom: gdbinfoimagebutton.bottom
                anchors.right: parent.right
                width: height
                anchors.rightMargin: 10
                Image {
                    anchors.fill: parent
                    source: "images/replace.png"
                    fillMode: Image.Stretch
                }
                Rectangle{
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "black"
                    border.width: 1
                    radius: 2
                }
                onClicked: {
                    console.log("CLICKED gdbDeleteButton --> createNextTimeDeleteFile()")
                    Helper.createOrRemoveNextTimeDeleteFile()
                    /*
                    gdbPath = "~/ArcGIS/AppStudio/Data"
                    console.log("CLICKED gdbDeleteButton")
                    map.removeAll()
                    localBuildingsTable.geodatabase = null
                    localRoomsTable.geodatabase = null
                    localLinesTable.geodatabase = null
                    geodatabaseSyncTask.unregisterGeodatabase(gdb)
                    gdb.destroy()
                    gdb.dump()
                    gdb.path = "null"
                    gdbfile.filePath = "null"
                    gdbfile.refresh()
                    updatesCheckfile.filePath = "null"
                    console.log(map.layerCount)
                    gdb.destroy()
                    syncLogFolder.removeFile("gdb.geodatabase")
                    syncLogFolder.removeFolder(syncLogFolder.path, true)
                    syncLogFolder.renameFile("gdb.geodatabase","renamed.geodatabase")
                    Helper.doorkeeper()
                    */
                }
            }
        }

        Rectangle{
            id:tpkinfocontainer
            height: welcomemenucontainer.height / 5
            width: welcomemenucontainer.width
            anchors.right:parent.right
            anchors.left: parent.left
            anchors.top: gdbinfocontainer.bottom
            color:"white"
            anchors.margins: 6
            border.width: 1
            border.color: "grey"

            Text{
                id: tpkinfobuttontext
                anchors.bottom:parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                color:"black"
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width:parent.width
                height: parent.height / 2
                clip:true
                horizontalAlignment:Text.AlignHCenter
                fontSizeMode: Text.Fit
                minimumPointSize: 4
                font.pointSize: 10
                verticalAlignment: Text.AlignVCenter
            }
            Button{
                id: tpkinfoimagebutton
                height: parent.height / 3
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.margins: 1
                style: ButtonStyle {
                    label: Text {
                       renderType: Text.NativeRendering
                       verticalAlignment: Text.AlignVCenter
                       horizontalAlignment: Text.AlignHCenter
                       color: "white"
                       text: "  Download Now  "
                       font.weight: Font.DemiBold
                     }
                        background: Rectangle {
                            border.width: control.activeFocus ? 2 : 1
                            border.color: "#888"
                            radius: 2
                            color: "darkblue"
                        }
                }
                onClicked: {
                    console.log("click middlebutton")
                    tpkFolder.removeFolder(tpkItemId, 1) //delete the tpk from local storage
                    tpkFolder.downloadThenAddLayer() //download and add the tpk layer
                }
            }
            Button{
                id: tpkDeleteButton
                anchors.top: tpkinfoimagebutton.top
                anchors.bottom: tpkinfoimagebutton.bottom
                anchors.right: parent.right
                width: height
                anchors.rightMargin: 10

                Image {
                    anchors.fill: parent
                    source: "images/DeleteWinIcon.png"
                    fillMode: Image.Stretch
                }
                Rectangle{
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "black"
                    border.width: 1
                    radius: 2
                }
                onClicked:{
                    console.log("CLICKED tpkDeleteButton")
                    map.removeLayerByIndex(0)
                    tpkFolder.removeFolder(tpkFolder.path, true) //delete the tpk from local storage
                    Helper.doorkeeper()
                }
            }
        }


        Rectangle{
            id:proceedbuttoncontainer
            width: welcomemenucontainer.width
            anchors.right:parent.right
            anchors.left: parent.left
            anchors.bottom: welcomemenucontainer.bottom
            anchors.top:tpkinfocontainer.bottom
            color:"green"
            anchors.margins: 6
            border.color: "grey"
            border.width: 1

            function proceedToMap(){
                console.log("proceedToMap")
                Helper.addAllLayers()
                welcomemenucontainer.visible = false
                Helper.getAllBldgs()//builds the list used for building search
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
//END WELCOMENU
//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------
//BEGIN SEARCHMENU
    Rectangle{
        id: searchmenucontainer
        anchors.top: mapcontainer.top
        anchors.bottom: mapcontainer.bottom
        anchors.right: mapcontainer.right
        anchors.left: mapcontainer.left
        color: "white"
        visible:false

        TextField{
                id: searchField
                width: parent.width
                height:zoomButtons.width
                focus: true
                visible: true
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                placeholderText :"Building Name"
                font.pointSize: 16
                textColor: "black"
                style: TextFieldStyle {
                    textColor: "black"
                    background: Rectangle {
                        radius: 2
                        border.color: "#333"
                        border.width: 1
                    }
                }
                inputMethodHints: Qt.ImhNoPredictiveText //necessary for onTextChanged signal on Android
                onTextChanged: {
                    if(text.length > 0 ) {
                                Helper.reloadFilteredBldgListModel(text);
                            } else {
                                Helper.reloadFullBldgListModel();
                            }
                        }
        }
        ListView{
            id:bldglistview
            clip: true
            width: parent.width
            height: parent.height
            anchors.top: searchField.bottom
            model: bldglistmodel
            delegate: bldgdelegate
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }

        Component {
            id: bldgdelegate
            Item {
                width: parent.width
                height: searchField.height
                anchors.margins: 5
                anchors.left: parent.left
                Column {
                    Text { text: bldgname + ' (#' + bldgid + ')'; font.pointSize: 16}
                    Text { text: objectid ; visible: true}
                    anchors.left:parent.left
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var foo = objectid //assign to js variable. Seems to only work that way.
                        //this should be enhanced to auto-select the feature and zoom to envelope
                        map.zoomTo(localBuildingsLayer.featureTable.feature(foo).geometry)
                        searchField.text = ""
                        searchmenucontainer.visible = false
                        Helper.updateBuildingDisplay(foo);
                        }
                }
            }
        }
        ListModel{
            id:bldglistmodel
            ListElement {
                objectid : "objectid"
                bldgname: "bldgname"
                bldgid: "bldgid"
            }
        }
    }
//END SEARCHMENU
//---------------------------------------------------------------------------------------------

    Component.onCompleted: {
        if (nextTimeDeleteGDBfile.exists == true){
            console.log(gdb.path)
            console.log(gdbfile.filePath)
            Helper.deleteGDB()
            console.log("Helper.deleteGDB()")
        }
        else{
            Helper.getAllBldgs()
            Helper.addAllLayers()
            serviceInfoTask.fetchFeatureServiceInfo();
        }
        tpkFolder.addLayer()
        Helper.doorkeeper()

    }
}

