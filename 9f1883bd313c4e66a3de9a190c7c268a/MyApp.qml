//------------------------------------------------------------------------------

import QtQuick 2.3
import QtQuick.Controls 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import ArcGIS.AppFramework.Runtime 1.0

import "Helper.js" as Helper

App {
    id: app
    width: 300
    height: 500

    //define global variable to hold last update date of tpk. Tried but did not manage to avoid this.
    property string tpkfilepath: ""

    //Define place to store local geodatabase and declare FileInfo object.
    //Set up components for generate and sync functionality
    property string appItemId: app.info.itemId
    property string gdbPath: "~/ArcGIS/AppStudio/Data/" + appItemId + "/gdb.geodatabase"
    property string updatesCheckfilePath: "~/ArcGIS/AppStudio/Data/" + appItemId + "/gdb.geodatabase-shm"
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

    //can keep track of when the app has synced last
    FileInfo {
        id: updatesCheckfile
        filePath: updatesCheckfilePath
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
                Helper.doorkeeper()
            } else if (generateStatus === GeodatabaseSyncTask.GenerateError) {
                gdbinfobuttontext.text = "Error: " + generateGeodatabaseError.message + " Code= "  + generateGeodatabaseError.code.toString() + " "  + generateGeodatabaseError.details;
            }
        }

        onSyncStatusChanged: {
            if (syncStatus === Enums.SyncStatusCompleted) {
                Helper.doorkeeper()
            }
            if (syncStatus === Enums.SyncStatusErrored)
                gdbinfobuttontext.text = "Error: " + syncGeodatabaseError.message + " Code= "  + syncGeodatabaseError.code.toString() + " "  + syncGeodatabaseError.details;
        }
    }

    //set up components for operational map layers: buildings, room-polygons, lines
    //per layer initialize a GeodatabaseFeatureTable, and then initialize a FeatureLayer
    //TODO: review how esri's example data is organized
    Geodatabase{
        id: gdb
        path: geodatabaseSyncTask.geodatabasePath
    }

    GeodatabaseFeatureTable {
        id: localLinesTable
        geodatabase: gdb.valid ? gdb : null
        featureServiceLayerId: 0
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

    Rectangle{
        id:mapcontainer
        height: parent.height * 0.88
        width: parent.width
        anchors.top: parent.top

        Map{
            id: map
            anchors.top: mapcontainer.top
            anchors.bottom: mapcontainer.bottom
            anchors.left: mapcontainer.left
            anchors.right: mapcontainer.right
            focus: true
            rotationByPinchingEnabled: true

            FeatureLayer {
                id: localLinesLayer
                featureTable: localLinesTable
            }
        }

        }

        Rectangle{
            id:compasscontainer
            height: app.height * 0.06
            width: height
            anchors.top: app.top
            anchors.left: app.left
            anchors.margins: app.height * 0.01
            color: "blue"
        }

        Rectangle{
            id: infobuttoncontainer
            height: app.height * 0.06
            width:height
            anchors.left: zoombuttoncontainer.left
            anchors.verticalCenter: infocontainer.verticalCenter
            anchors.topMargin: app.height * 0.01
            anchors.bottomMargin: app.height * 0.01
            color:"darkblue"
            border.color: "white"
            border.width: 1

            ImageButton{
                id: infobutton
                source:"images/info2-white.png"
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    console.log("click")
                    infocontainer.visible = true
                    infobuttoncontainer.visible = false
               }
             }
        }

        Rectangle{
           id:infocontainer
           height: app.height * 0.10
           anchors.left: zoombuttoncontainer.left
           anchors.right: floorcontainer.right
           anchors.bottom: mapcontainer.bottom
           anchors.topMargin: app.height * 0.01
           anchors.bottomMargin: app.height * 0.01
           color:"darkblue"
           border.color: "white"
           border.width: 1

           Row{
               id:inforow

               ImageButton{
                   id:closeinfobutton
                   height:infocontainer.height
                   source:"images/close-white.png"
                   onClicked: {
                       console.log("click")
                       infocontainer.visible = false
                       infobuttoncontainer.visible = true
                   }
               }
               Flickable{
                   id: infoflickable
                   height:infocontainer.height - app.height * 0.01
                   width:infocontainer.width - closeinfobutton.width
                   contentWidth: infotext.width
                   contentHeight: infotext.height
                   flickableDirection: Flickable.VerticalFlick
                   anchors.verticalCenter: closeinfobutton.verticalCenter
                   clip: true

                   Text{
                       id:infotext
                       text: "Some text messages displayed here."
                       color: "white"
                       wrapMode: Text.Wrap
                       width:infocontainer.width - closeinfobutton.width
                       font.pointSize: 14
                       elide: Text.ElideLeft
                       anchors.verticalCenter: closeinfobutton.verticalCenter
                   }
               }
           }

        }

        Rectangle{
            id:zoombuttoncontainer
            height: app.height * 0.13
            width: height/2
            anchors.bottom:infocontainer.top
            anchors.left:app.left
            anchors.margins: app.height * 0.01
            color:"yellow"
        }

        Rectangle{
            id:floorcontainer
            height: app.height * 0.50
            width: app.height * 0.06
            anchors.bottom:infocontainer.top
            anchors.right:app.right
            anchors.margins: app.height * 0.01
            color:"pink"
        }

    Rectangle{
        id:toolbarcontainer
        height: parent.height * 0.12
        width: parent.width
        color:"darkblue"
        anchors.bottom: parent.bottom

        Row{
            id:toolbarrow

            ImageButton{
                id: leftbutton
                source:"images/position-off-white.png"
                height: toolbarcontainer.height
                width: toolbarcontainer.width / 3
                onClicked: {
                    console.log("click")
                }
            }

            ImageButton{
                id: centerbutton
                source:"images/search-white.png"
                height: toolbarcontainer.height
                width: toolbarcontainer.width / 3
                onClicked: {
                    console.log("click")
                }
            }
            ImageButton{
                id: rightbutton
                source:"images/actions-white.png"
                anchors.margins: 10
                height: toolbarcontainer.height
                width: toolbarcontainer.width / 3
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
        }
    }

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

