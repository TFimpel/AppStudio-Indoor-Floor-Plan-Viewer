# appstudio_floorplan_app
## Summary
A configurable [ArcGIS AppStudio](https://appstudio.arcgis.com/) App Template to be used for viewing interior building floor plans.
+ useable offline
+ building search
+ can leverage ArcGIS Online authentication
+ zoom-in not limited to basemap scale levels
+ minimal requirements for data in terms of required fields etc.
+ intuitive user interface
+ (note: no feature pop-up's available at this point)

![alt text](https://cloud.githubusercontent.com/assets/7443922/11705829/d3bf5326-9eb8-11e5-9e6b-b3acbf5e0933.PNG "Screen shots of Flor Plan Viewer App on Google Nexus5")


## What you need to use this
+ ArcGIS Online Organizational or Developer account
+ AppStudio for ArcGIS Desktop ("Standard" license, "Basic" is not sufficient) 
+ AppStudio Player app
+ GIS data (Feature Service & Tile Package)

## How to use this
1. Install AppStudio for ArcGIS and sing in to your ArcGIS Online account (you need a "Standard" license allocated to your account to sign in)
2. Download the code in this repo, put the folder "arcgis-online-app-item-id-here" (incl. all its contents) into the appropriate directory on your computer. The directory path probably depends on your installation. On Windows by default it is C:\Users\<username>\ArcGIS\AppStudio\Apps\
3. Open AppStudio for Desktop. The new app item will appear now and you can configure the properties (see below) and then upload the app item to your ArcGIS Online account. 
4. Following that initial upload the id value in your local copy of file itminfo.json will not be null anymore. Instead it will be a long string of characters, something like "1234567890ABC123XYZ".
5. Rename the app's folder name in the ...\ArcGIS\AppStudio\Apps\... directory from "arcgis-online-app-item-id-here" to this id value that your upload generated.
6. Now "Update" the app item via the AppStudio Upload process. (The reason for doing this is so that the app stores the local .geodatabase file in the correct place upon download to device)
7. Use the app on most any device/OS with the AppStudio Player app available in iOS/Android/Windows stores.

## Configurable Properties
+ App Description 
  *(example: "Sign in, download the basemap tile package, then download the secured floor plan feature layers and off you go. On the map you can view interior building layouts. Sync it now and again to get the latest updates downloaded to your device.")*
+ App Title
  *(example: "Floor Plan Viewer")*
+ Basemap Tile Package Item ID
  *(example: "504e5db503d7432b89042c196d8cbf57")*
+ Floor Plans and Buildings Feature Service URL
  *(example:  "http://services.arcgis.com/[...]/FeatureServer")*
+ Building Polygons LayerID
  *(example: "2")*
+ Floorplan Lines LayerID
  *(example: "0")*
+ Floorplan Polygons LayerID
  *(example: "1")*
+ Buildings layer building name field
  *(example: "BUILDING_NAME")*
+ Buildings layer building ID field
  *(example: "BUILDING_NUMBER")*
+ Floor plan lines layer building ID field"
  *(example: "BUILDING_NUMBER")*
+ Floor plan lines layer floor field
  *(example: "FLOOR")*
+ Floor plan lines layer sort field
  *(example: "ELEVATION")*
+ Floor plan polygon layer building ID field
  *(example: "BUILDING_NUMBER")*
+ Floor plan polygon layer floor field
  *(example: "FLOOR")*

Note that the Basemap Tile Package Item needs to be publicly accessible. The Floor Plans and Buildings Feature Service can be secured via ArcGIS Online Groups or publicly accessible. It needs to be sync enabled, and the app will download a copy of all features that intersect the tile package's extent (test with small data first).

The configurable fields are used to determine which floors are display-able for each building. The requirements for these fields are intentionally kept at a minimum, but it is critical to have these attribute data clean and thus relate-able.
