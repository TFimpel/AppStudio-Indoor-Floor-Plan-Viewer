//------------------------------------------------------------------------------
//SOME TESTNG STUUF HERE.
function helperSayHi(){
    console.log("Helper says Hi.")
}


//--------------------------------------------------------------------------
//build a list of all buldings, stored as a global variable used for the search menu.
function getAllBldgs(){
    localBuildingsTable.queryFeatures("OBJECTID > 0");
}
function buildAllBlgdList(iterator){
    while (iterator.hasNext()) {
         var feature = iterator.next();
         var objectID = (feature.attributeValue("OBJECTID").toString())
         var bldgID = (feature.attributeValue(bldgLyr_bldgIdField))
         var bldgName = (feature.attributeValue(bldgLyr_nameField))
         allBlgdList.push([objectID, bldgID, bldgName]);
   }
}

//----------------------------------------------------------------------
//load all buildings into the litview shown in the search menu
function reloadFullBldgListModel(){
    bldglistmodel.clear();
    for( var i=0; i < allBlgdList.length ; ++i ) {
    bldglistmodel.append({"bldgname" : allBlgdList[i][2],
                          "objectid" : allBlgdList[i][0],
                          "bldgid" : allBlgdList[i][1]
                         })
    }
}

//----------------------------------------------------------------------
//load a filtered buildings into the litview shown in the search menu
function reloadFilteredBldgListModel(bldgname) {
    bldglistmodel.clear();
    for( var i=0; i < allBlgdList.length ; ++i ) {
        if (allBlgdList[i][2].toLowerCase().indexOf(bldgname.toLowerCase()) >= 0){
        bldglistmodel.append({"bldgname" : allBlgdList[i][2],
                             "objectid" : allBlgdList[i][0],
                             "bldgid" : allBlgdList[i][1]})
        };
    }
}

//--------------------------------------------------------------------------------
//hide all floors from map display
function hideAllFloors(){
    localRoomsLayer.definitionExpression = "OBJECTID < 0"
    localLinesLayer.definitionExpression = "OBJECTID < 0"
}

//----------------------------------------------------------------------
//populate the floor list slider
function compareBySecondArrayElement(a, b) {
    if (a[1] === b[1]) {
        return 0;
    }
    else {
        return (a[1] > b[1]) ? -1 : 1;
    }
}

function setFloorFilters(index){
    localLinesLayer.definitionExpression = lineLyr_floorIdField  + " = '"+(floorListModel.get(floorListView.currentIndex).Floor)+"'" + " AND " + lineLyr_bldgIdField + "= '" + currentBuildingID +"'"
    localRoomsLayer.definitionExpression = roomLyr_floorIdField  + " = '"+(floorListModel.get(floorListView.currentIndex).Floor)+"'" + " AND " + roomLyr_bldgIdField + "= '" + currentBuildingID +"'"
}

function populateFloorListView(iterator,bldg, sortField){
                floorListModel.clear();
                var floorlist = [];
                while (iterator.hasNext()) {
                     var feature = iterator.next();
                     if (feature.attributeValue(lineLyr_bldgIdField) === bldg){
                     var floorValue = feature.attributeValue(lineLyr_floorIdField);
                     var sortValue = feature.attributeValue(sortField);
                     floorlist.push([floorValue, sortValue]);
                    }
            }
                floorlist.sort(compareBySecondArrayElement);
                console.log(floorlist);
                for( var i=0; i < floorlist.length ; ++i ) {
                    floorListModel.append({"Floor" : floorlist[i][0]})
                };
                if (floorlist.length > 0){
                    floorcontainer.visible = true;
                }
                else{
                    floorcontainer.visible = false;
                }
                floorListView.currentIndex = 0
                setFloorFilters(0);
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
        updateBuildingDisplay(featureIds[0])
    }
}

//----------------------------------------------------------------------
//
function updateBuildingDisplay(selectedFeatureId){
    infocontainer.visible = true;
    if (currentBuildingObjectID != selectedFeatureId){
        localBuildingsLayer.clearSelection();
        localBuildingsLayer.selectFeature(selectedFeatureId);
        hideAllFloors();
        currentBuildingObjectID = selectedFeatureId
        var bldgName = localBuildingsLayer.featureTable.feature(selectedFeatureId).attributeValue(bldgLyr_nameField)
        var bldgNumber = localBuildingsLayer.featureTable.feature(selectedFeatureId).attributeValue(bldgLyr_bldgIdField)
        infotext.text = bldgName + " (#" + bldgNumber + ")"
        currentBuildingID = bldgNumber
        localLinesTable.queryFeatures("OBJECTID > 0")//this will trigger the populate floor slider functionailty
        }

}


//----------------------------------------------------------------------
//for keeping track when the offline geodatabase has been synced last
function writeSyncLog(){
    syncLogFolder.writeFile("syncLog.txt","Offline Geodatabase last synced with server when this file was last modified. Very basic, I now. But hey, no annoying file locking issues...it just works :)")
}
