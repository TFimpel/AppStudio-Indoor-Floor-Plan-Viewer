//------------------------------------------------------------------------------
//SOME TESTNG STUUF HERE.
function helperSayHi(){
    console.log("Helper says Hi.")
}

function hideAllFloors(){
    localRoomsLayer.definitionExpression = "OBJECTID < 0"
    localLinesLayer.definitionExpression = "OBJECTID < 0"
}

//----------------------------------------------------------------------
//populate the floor list slider
function populateFloorListView(iterator,bldg){
                floorListModel.clear();
                var floorlist = [];
                while (iterator.hasNext()) {
                     var feature = iterator.next();
                     if (feature.attributeValue(lineLyr_bldgIdField) === bldg){
                     floorlist.push(feature.attributeValue(lineLyr_floorIdField));
                    }
            }
                floorlist.sort();
                console.log(floorlist);
                for( var i=0; i < floorlist.length ; ++i ) {
                    floorListModel.append({"Floor" : floorlist[i]})
                };
                if (floorlist.length > 0){
                    floorcontainer.visible = true;
                }
                else{
                    floorcontainer.visible = false;
                }
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
    map.insertLayer(localBuildingsLayer,1);
    map.insertLayer(localRoomsLayer,2);
    map.insertLayer(localLinesLayer, 3);
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
        if (currentBuildingObjectID != selectedFeatureId){
            hideAllFloors()
            currentBuildingObjectID = selectedFeatureId
            var bldgName = localBuildingsLayer.featureTable.feature(selectedFeatureId).attributeValue(bldgLyr_nameField)
            var bldgNumber = localBuildingsLayer.featureTable.feature(selectedFeatureId).attributeValue(bldgLyr_bldgIdField)
            infotext.text = bldgName + " (#" + bldgNumber + ")"
            currentBuildingID = bldgNumber
            localLinesTable.queryFeatures("OBJECTID > 0")//this will trigger the populate floor slider functionailty
            }
    }
}
//----------------------------------------------------------------------
//


//----------------------------------------------------------------------
//for keeping track when the offline geodatabase has been synced last
function writeSyncLog(){
    syncLogFolder.writeFile("syncLog.txt","Offline Geodatabase last synced with server when this file was last modified. Very basic, I now. But hey, no annoying file locking issues...it just works :)")
}
