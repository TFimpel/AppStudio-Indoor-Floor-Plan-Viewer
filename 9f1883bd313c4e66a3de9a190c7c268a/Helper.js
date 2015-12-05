//------------------------------------------------------------------------------
//used deleting the runtime geodatabase
function deleteGDB(){
    syncLogFolder.removeFolder(syncLogFolder.path, true);
}

//--------------------------------------------------------------------------
//used for building a list of all buldings.
//list is stored as a global variable queried via the search menu.
function getAllBldgs(){
    localBuildingsTable.queryFeatures("OBJECTID > 0");
}
function buildAllBlgdList(iterator){
    allBlgdList = [];
    while (iterator.hasNext()) {
         var feature = iterator.next();
         var objectID = (feature.attributeValue("OBJECTID").toString())
         var bldgID = (feature.attributeValue(bldgLyr_bldgIdField))
         var bldgName = (feature.attributeValue(bldgLyr_nameField))
         allBlgdList.push([objectID, bldgName, bldgID]);
   }
   //sort alphabetically by building name
   allBlgdList.sort(compareBySecondArrayElement)
}

//----------------------------------------------------------------------
//load all buildings into the litview shown in the search menu
function reloadFullBldgListModel(){
    bldglistmodel.clear();
    for( var i=0; i < allBlgdList.length ; ++i ) {
    bldglistmodel.append({"bldgname" : allBlgdList[i][1],
                          "objectid" : allBlgdList[i][0],
                          "bldgid" : allBlgdList[i][2]})
    }
}

//----------------------------------------------------------------------
//load a filtered buildings into the litview shown in the search menu
function reloadFilteredBldgListModel(bldgname) {
    bldglistmodel.clear();
    for( var i=0; i < allBlgdList.length ; ++i ) {
        if (allBlgdList[i][1].toLowerCase().indexOf(bldgname.toLowerCase()) >= 0){
        bldglistmodel.append({"bldgname" : allBlgdList[i][1],
                             "objectid" : allBlgdList[i][0],
                             "bldgid" : allBlgdList[i][2]})
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
//sorting used for floor list slider the buildings in the search menu
function compareBySecondArrayElement(a, b) {
    if (a[1] === b[1]) {
        return 0;
    }
    else {
        return (a[1] < b[1]) ? -1 : 1;
    }
}
//-----------------------------------------------------------------------
//used for populating the floor slider and displaying only one floor at a time
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
                //if there are no floors for seleted building hide the slider
                else{
                    floorcontainer.visible = false;
                }
                //initially display the "lowest" floor in a building
                floorListView.currentIndex = 0
                setFloorFilters(0);
    }

//------------------------------------------------------------------------------
//take actions based on whether user already has local copies of tpk and gdb on device
function doorkeeper(){
    if (updatesCheckfile.exists) {updatesCheckfile.refresh()};
    if (gdbfile.exists){gdbfile.refresh()};
    if (tpkfile.exists){tpkfile.refresh()};

    if (gdbfile.exists && updatesCheckfile.exists) {
        gdbinfobuttontext.text = " Sync updates for floor plan operational layers. Last updates downloaded " + updatesCheckfile.lastModified.toLocaleString("MM.dd.yyyy hh:mm ap") + "."
    }
    if (gdbfile.exists && !updatesCheckfile.exists) {
        gdbinfobuttontext.text = " Sync updates for floor plan operational layers. App is unable to determine when updates were last synced."
    }

    //check gdbDeleteButtonText.text === "Undo" becasue nextTimeDeleteGDBfile.exists always evaluates to false for some reason(?)
    if (gdbDeleteButtonText.text === "Undo"){
        gdbinfobuttontext.text = '<b><font color="red"> Device copy of operational layers set to be removed next time app is opened. </font><\b>'
    }

    //this text is better set with this js function instead of putting the property on watch because the tpk download also modifies it
    if (!tpkFolder.exists){
        tpkinfobuttontext.text = " Download the basemap tile package to be able to proceed. "
    }
    else {tpkinfobuttontext.text = " Last downloaded " + tpkfile.lastModified.toLocaleString("MM.dd.yyyy hh:mm ap") + ". "
    }
}

//----------------------------------------------------------------------
//takes action when app is not ready to download or sync .geodatabase
function preventGDBSync(){
    gdbinfobuttontext.text = "  Unable to download updates for floor plan operational layers. Make sure you have internet connectivity and are signed in. "
}

//----------------------------------------------------------------------
//if the building is not currenty selected then update the infotext and trigger a querychange on the lines and rooms tables
function selectBuildingOnMap(x,y) {
    var featureIds = localBuildingsLayer.findFeatures(x, y, 1, 1);
    if (featureIds.length > 0) {
        updateBuildingDisplay(featureIds[0])
    }
}

function updateBuildingDisplay(selectedFeatureId){
    infocontainer.visible = true;
    if (currentBuildingObjectID != selectedFeatureId){
        localBuildingsLayer.clearSelection();
        localBuildingsLayer.selectFeature(selectedFeatureId);
        hideAllFloors();
        console.log(selectedFeatureId)
        currentBuildingObjectID = selectedFeatureId
        console.log(selectedFeatureId)
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
    syncLogFolder.writeFile("syncLog.txt","Offline Geodatabase last synced with server when this file was last modified. Very basic but hey, no annoying file locking issues...it just works")
}
