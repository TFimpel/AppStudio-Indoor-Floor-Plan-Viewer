//------------------------------------------------------------------------------
//SOME TESTNG STUUF HERE.
function helperSayHi(){
    console.log("Helper says Hi.")
}

function writeSyncLog(){
    syncLogFolder.writeFile("syncLog.txt","Offline Geodatabase last synced with server when this file was last modified. Very basic, I now. But hey, no annoying file lockin issues...it just works :)")
}

//------------------------------------------------------------------------------
//take actions based on whetehr user already has local copies of tpk and gdb
function doorkeeper(){
    updatesCheckfile.refresh()
    gdbfile.refresh()
    tpkfile.refresh()

    if (!gdbfile.exists) {
        gdbinfobuttontext.text = " Download floor plan operational layers to be able to proceed. "
    }
    else if (updatesCheckfile.exists) {
        //TODO: if layer are added to the map lastmodified date doesn't chnage. Poible solution: a removAllLayers() function equivlent to addAllLayers()-->doesnt work. need to cange this date reporting thing (write to other json file)
        gdbinfobuttontext.text = " Download updates for floor plan operational layers. Last updates downloaded " + updatesCheckfile.lastModified.toLocaleString("MM.dd.yyyy hh:mm ap") + "."
    }
    else {gdbinfobuttontext.text = " Download updates for floor plan operational layers. Last updates downloaded " + gdbfile.lastModified.toLocaleString("MM.dd.yyyy hh:mm ap") + "."
    }

    if (!tpkFolder.exists){
        tpkinfobuttontext.text = " Download the basemap tile package to be able to proceed. "
    }
    else {tpkinfobuttontext.text = " Download updates for background map layer. Last updates downloaded " + tpkfile.lastModified.toLocaleString("MM.dd.yyyy hh:mm ap") + "."
    }

    if (!tpkFolder.exists || !gdbfile.exists){
        proceedbuttoncontainer.color = "red"
        proceedbuttoncontainermousearea.enabled = false
    }
    else{proceedbuttoncontainer.color = "green"
         proceedbuttoncontainermousearea.enabled = true
    }
}

//----------------------------------------------------------------------
//add all layers to the map
function addAllLayers(){
    map.addLayer(localBuildingsLayer);
    map.addLayer(localRoomsLayer);
    map.addLayer(localLinesLayer);
}

//----------------------------------------------------------------------
//take actions when app is not ready to download or sync .geodatabase
function preventGDBSync(){
    gdbinfobuttontext.text = "  At this time the app is unable to download updates for floor plan operational layers.  "
}

//----------------------------------------------------------------------
//if bldg. is not currenty select update the infotext and trigger a querychange on the lines and rooms tables
function selectBuildingOnMap(x,y) {
    var featureIds = localBuildingsLayer.findFeatures(x, y, 1, 1);
    if (featureIds.length > 0) {
        console.log(featureIds.length )
        console.log(featureIds[0])
        var selectedFeatureId = featureIds[0];
        infocontainer.visible = true;
        if (selectedFeatureId != currentBuildingObjectID){
            currentBuildingObjectID = selectedFeatureId
            var bldgName = localBuildingsLayer.featureTable.feature(selectedFeatureId).attributeValue(bldgLyr_bldgIdField)
            var bldgNumber = localBuildingsLayer.featureTable.feature(selectedFeatureId).attributeValue(bldgLyr_bldgIdField)
            infotext.text = bldgName + " (#" + bldgNumber + ")"
            localLinesTable.queryFeatures("OBJECTID > 0")//this will trigger the floor slider functionailty
            localRoomsTable.queryFeatures("OBJECTID > 0")//this will trigger the floor slider functionailty
            }
    }
}

//----------------------------------------------------------------------
//for keeping track when the offline geodatabase has been synced last
function writeSyncLog(){
    syncLogFolder.writeFile("syncLog.txt","Offline Geodatabase last synced with server when this file was last modified. Very basic, I now. But hey, no annoying file locking issues...it just works :)")
}
