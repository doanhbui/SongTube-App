import 'dart:io';
import 'package:flutter/material.dart';
import 'tabs/downloadtab.dart';
import 'tabs/hometab.dart';
import 'tabs/settingstab.dart';
import 'internal/songtube_classes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'internal/native.dart';

class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> with SingleTickerProviderStateMixin {

  TabController _tabController;
  static final List<String> _appBarTitleArr = [ "SongTube", "SongTube", "App Settings" ];
  String _appBarTitle = _appBarTitleArr[0];

  @override
  void initState() {
    checkPermissions();
    appdata = AppStreams();
    downloader = Downloader();
    method = NativeMethod();
    converter = Converter();
    _tabController = new TabController(vsync: this, length: 3);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  _onTabTapped(int index) {
    setState(() {
      _appBarTitle = _appBarTitleArr[index];
    });
  }

  Future<void> showAlertDialog(BuildContext context, bool permanent) async {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("SongTube"),
      content: permanent == false
          ? Text(
              "This application needs external storage permission to convert or download from YouTube or other sites")
          : Text(
              "External storage permission is permanently denied, please go to settings and enable it manually for this app to work..."),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  checkPermissions() async {
    final status = await Permission.storage.status;
    if (status.isUndetermined) {
      await showAlertDialog(context, false);
      final response = await Permission.storage.request();
      if (response.isDenied) exit(0);
      if (response.isPermanentlyDenied) exit(0);
    } else if (status.isGranted) {
      return;
    } else if (status.isDenied) {
      await showAlertDialog(context, false);
      final response = await Permission.storage.request();
      if (response.isDenied) exit(0);
      if (response.isPermanentlyDenied) exit(0);
    } else if (status.isPermanentlyDenied) {
      await showAlertDialog(context, true);
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            _appBarTitle,
            style: TextStyle(color: Theme.of(context).textTheme.body1.color),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).canvasColor,
          centerTitle: true,
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          controller: _tabController,
          children: [
            HomeTab(),
            DownloadTab(),
            SettingsTab(),
          ]
        ),
        backgroundColor: Theme.of(context).canvasColor,
        floatingActionButton: StreamBuilder<Object>(
            stream: appdata.linkReady.stream,
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 8),
                  child: FloatingActionButton(
                    onPressed: () async {
                      await downloader.download();
                      List<String> list = await converter.getArgumentsList(FFmpegArgs.argsToACC,
                        downloader.defaultMetaData);
                      int result = await converter.convertAudio(list);
                      if (result == 0) print("Library: Audio convertion done successful");
                      if (result == 1) print("Library: Audio convertion failed");
                    },
                    child: Icon(
                      Icons.file_download,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else {
                return Container();
              }
            }),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(
            left: 8,
            right: 8,
            bottom: 6
          ),
          child: Container(
            color: Theme.of(context).canvasColor,
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: Theme.of(context).tabBarTheme.labelColor,
              ),
              controller: _tabController,
                tabs: [
                  Tab(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.home),
                        if (_tabController.index == 0)
                        Text("  Home", style: TextStyle(color: Theme.of(context).textTheme.body1.color))
                      ], key: PageStorageKey("hometab")
                    )
                  ),
                  Tab(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.cloud_download),
                        if (_tabController.index == 1)
                        Text("  Downloads", style: TextStyle(color: Theme.of(context).textTheme.body1.color))
                      ]
                    )
                  ),
                  Tab(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.settings),
                        if (_tabController.index == 2)
                        Text("  Settings", style: TextStyle(color: Theme.of(context).textTheme.body1.color))
                      ]
                    )
                  ),
                ],
                labelPadding: EdgeInsets.symmetric(horizontal: 1.0),
                unselectedLabelColor: Theme.of(context).iconTheme.color,
                labelColor: Colors.redAccent,
                onTap: _onTabTapped,
              ),
          ),
        ),
    );
  }
}