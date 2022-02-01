# BII Multi-Camera Phenotype Capture for iOS

Iceland snackwave narwhal glossier lomo vexillologist +1 butcher offal hell of. Literally lomo 3 wolf moon chicharrones, vegan enamel pin +1 aesthetic biodiesel organic wayfarers four loko. Gochujang keffiyeh lumbersexual bitters, twee semiotics you probably haven't heard of them intelligentsia. Truffaut put a bird on it chambray mixtape narwhal YOLO cold-pressed post-ironic neutra knausgaard church-key chartreuse.

## Contents
- [Using the App](https://github.com/SLUVisLab/bii_multi_pheno_cam#using-the-app)
  - [Taking Photos](https://github.com/SLUVisLab/bii_multi_pheno_cam#taking-photos)
  - [Uploading & Deleting Photo Sessions](https://github.com/SLUVisLab/bii_multi_pheno_cam#uploading--deleting-photo-sessions)
  - [Configuration and Troubleshooting](https://github.com/SLUVisLab/bii_multi_pheno_cam#configuration-and-troubleshooting)
- [Backend Setup](https://github.com/SLUVisLab/bii_multi_pheno_cam#backend-setup)
  - [Authentication](https://github.com/SLUVisLab/bii_multi_pheno_cam#authentication)
  - [Accessing Data](https://github.com/SLUVisLab/bii_multi_pheno_cam#accessing-data)
- [Tech Stack and Codebase](https://github.com/SLUVisLab/bii_multi_pheno_cam#tech-stack-and-codebase)
- [Resources](https://github.com/SLUVisLab/bii_multi_pheno_cam#resources)

## Using the App

The main screen of the app contains three options: 1) **Capture** for opening the camera view and taking photos, 2) **Gallery** for viewing previous sessions as well as uploading or deleting them, and 3) The settings page indicated by the gear icon in the top right corner. Let's take a look at what's available in each view!

### Taking Photos

In order to start the camera you will first need to use the text inputs to enter the field site and block/plot id what you are about to take photos of. Once you've input a field site ID the app should remember it for next time. 

Once you've filled out the text fields, the record button at the bottom of the screen should be white to incdicate it is enabled. After pressing the record button the app will start taking photos continuously at a set framerate using multiple device cameras. The screen should show an animation indicating that photo capture is in progress.

To stop recording, hit the record button again. Voila! You've taken a bunch of photos! 


### Uploading & Deleting Photo Sessions

After navigating to the **Gallery** view, you can view and manage collections of photos that have been recorded.

To see the individual photos included in a recording session, just click on the session in the gallery.

To upload or delete recording sessions, enter gallery selection mode by clicking the **Select** button in the top right corner. You can now select individual or multiple recording sessions and use the **Delete** or **Upload** buttons at the botton of the view to perform those actions.

**NOTE:** Recording sessions are automatically deleted after they are uploaded!

**On Deleting Recording Sessions:** The photos taken using this app are stored the natiuve iOS Photos Library. If you delete photos using the standard Photos app, it can corrupt the references used internally by this app. We reccomend only using this app to delete photos associated with it. If you do run into issues with this, see the next section: [Configuration and Troubleshooting](https://github.com/SLUVisLab/bii_multi_pheno_cam#configuration-and-troubleshooting)

### Configuration and Troubleshooting

#### App Configuration

The app is packaged with a default configuration for things like camera framerate and size of uploaded images. It also checks the cloud database for an updated configuration file on startup and saves it locally for future use. You can see the configuration values from the **Settings** view and also manually check for a new configuration file using the provided button.

#### Troubleshooting

Sometimes the apps local database can become corrupted and get out of sync with the native iOS Photos library. If you run into issues with crashing or freezing, go to the **Settings** view and click the "Clear Database Cache" button. This will delete any current recording sessions you have made with the app and clear the local database.

## Backend Setup

### Authentication
### Accessing Data

## Tech Stack and Codebase

## Resources

Camera capture code inspired by:
[Better Programming effortless-swiftui-camera](https://betterprogramming.pub/effortless-swiftui-camera-d7a74abde37e)

[MongoDB Realm Swift SDK Docs](https://docs.mongodb.com/realm/sdk/swift/)

[Firebase Storage SDK](https://firebase.google.com/docs/storage/ios/start)

[Firebase Firestore SDK](https://firebase.google.com/docs/firestore/quickstart#swift_1)

[Apple PhotoKit Docs](https://developer.apple.com/documentation/photokit)

[AVFoundation Docs](https://developer.apple.com/documentation/avfoundation)

[Remote Configuration Loader](https://www.donnywals.com/building-a-simple-remote-configuration-for-your-apps/)

