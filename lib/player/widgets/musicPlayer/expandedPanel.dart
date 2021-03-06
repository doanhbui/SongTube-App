// Dart
import 'dart:io';
import 'dart:math';
import 'dart:ui';

// Flutter
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// Internal
import 'package:songtube/internal/services/playerService.dart';

// Packages
import 'package:audio_service/audio_service.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:rxdart/rxdart.dart';

// UI
import 'package:songtube/ui/animations/fadeIn.dart';

class ExpandedPlayer extends StatelessWidget {
  final PanelController controller;
  final AsyncSnapshot<ScreenState> snapshot;
  final List<dynamic> uiElements;
  ExpandedPlayer({
    this.controller,
    this.snapshot,
    this.uiElements
  });
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);
  @override
  Widget build(BuildContext context) {
    final screenState = snapshot.data;
    final mediaItem = screenState?.mediaItem;
    final state = screenState?.playbackState;
    final playing = state?.playing ?? false;
    File image = uiElements[0];
    Color dominantColor = uiElements[1] == null ? Colors.white : uiElements[1];
    Color textColor = dominantColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              child: FadeInImage(
                image: FileImage(image),
                placeholder: MemoryImage(kTransparentImage),
                fadeInDuration: Duration(milliseconds: 200),  
                fit: BoxFit.cover,
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.2),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 25.0,
                  sigmaY: 25.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                      leading: IconButton(
                        icon: Icon(Icons.expand_more, color: textColor),
                        onPressed: () {
                          controller.close();
                        },
                      ),
                      title: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Playing From\n",
                              style: TextStyle(
                                letterSpacing: 2,
                                color: textColor,
                                fontFamily: 'YTSans'
                              )
                            ),
                            TextSpan(
                              text: "${mediaItem.album}",
                              style: TextStyle(
                                color: textColor.withOpacity(0.6),
                                fontSize: 12,
                                fontFamily: 'YTSans'
                              )
                            )
                          ]
                        ),
                      ),
                    ),
                    Expanded(
                      child: FadeInTransition(
                        delay: Duration(milliseconds: 100),
                        duration: Duration(milliseconds: 200),
                        child: Container(
                          height: 320,
                          width: 320,
                          margin: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black87.withOpacity(0.2),
                                offset: Offset(0,0), //(x,y)
                                blurRadius: 10.0,
                                spreadRadius: 2.0 
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: FadeInImage(
                              fadeOutDuration: Duration(milliseconds: 300),
                              fadeInDuration: Duration(milliseconds: 300),
                              placeholder: MemoryImage(kTransparentImage),
                              image: snapshot.hasData
                                ? FileImage(image)
                                : MemoryImage(kTransparentImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 16, right: 16, bottom: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Title
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: Text(
                              mediaItem.title,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                                fontFamily: "YTSans",
                                color: textColor
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                          // Artist
                          Container(
                            margin: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 8),
                            child: Text(
                              mediaItem.artist,
                              style: TextStyle(
                                color: textColor,
                                fontFamily: "YTSans",
                                fontSize: 16
                              ),
                            ),
                          ),
                          // Progress Indicator
                          Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child: positionIndicator(mediaItem, state, dominantColor)
                          ),
                          // MediaControls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              // Random Button
                              Container(
                                margin: EdgeInsets.only(right: 8),
                                child: IconButton(
                                  icon: Icon(
                                    EvaIcons.shuffle2Outline,
                                    size: 16,
                                    color: textColor.withOpacity(0.7)
                                  ),
                                  onPressed: () => AudioService.customAction("enableRandom")
                                ),
                              ),
                              // Previous button
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 18,
                                  color: textColor.withOpacity(0.7)
                                ),
                                onPressed: () => AudioService.skipToPrevious(),
                              ),
                              // Padding
                              SizedBox(width: 20),
                              // Play/Pause button
                              GestureDetector(
                                onTap: playing
                                  ? () => AudioService.pause()
                                  : () => AudioService.play(),
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: dominantColor,
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        offset: Offset(0,3),
                                        blurRadius: 8,
                                        spreadRadius: 1 
                                      )
                                    ]
                                  ),
                                  child: playing
                                    ? Icon(Icons.pause, size: 25, 
                                        color: textColor)
                                    : Icon(Icons.play_arrow, size: 25,
                                        color: textColor),
                                ),
                              ),
                              // Padding
                              SizedBox(width: 20),
                              // Next button
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                  color: textColor.withOpacity(0.7)
                                ),
                                onPressed: () => AudioService.skipToNext(),
                              ),
                              // Repeat Button
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                child: IconButton(
                                  icon: Icon(
                                    EvaIcons.repeatOutline,
                                    size: 16,
                                    color: textColor.withOpacity(0.7)
                                  ),
                                  onPressed: () => AudioService.customAction("enableRepeat")
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(left: 20),
                                  child: IconButton(
                                    icon: Icon(EvaIcons.settingsOutline, color: textColor),
                                    onPressed: () {
                                      // TODO: Show Player Settings
                                    },
                                  ),
                                ),
                                Spacer(),
                                // Add Song to Favorites Playlist
                                Container(
                                  margin: EdgeInsets.only(right: 20),
                                  child: IconButton(
                                    icon: Icon(EvaIcons.heartOutline, color: textColor),
                                    onPressed: () {
                                      // TODO: Add to Favorites Playlist
                                    },
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget positionIndicator(MediaItem mediaItem, PlaybackState state, Color dominantColor) {
    Color textColor = dominantColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    double seekPos;
    return StreamBuilder(
      stream: Rx.combineLatest2<double, double, double>(
          _dragPositionSubject.stream,
          Stream.periodic(Duration(milliseconds: 1000)),
          (dragPosition, _) => dragPosition),
      builder: (context, snapshot) {
        Duration position = state.currentPosition;
        Duration duration = mediaItem?.duration;
        return duration != null
          ? Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
                    valueIndicatorTextStyle: TextStyle(
                      color: dominantColor,
                    ),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    activeColor: dominantColor.withOpacity(0.7),
                    inactiveColor: Colors.black12.withOpacity(0.2),
                    min: 0.0,
                    max: duration.inMilliseconds?.toDouble(),
                    value: seekPos ?? max(0.0, min(
                      position.inMilliseconds.toDouble(),
                      duration.inMilliseconds?.toDouble()
                    )),
                    onChanged: (value) {
                      _dragPositionSubject.add(value);
                    },
                    onChangeEnd: (value) {
                      AudioService.seekTo(Duration(milliseconds: value.toInt()));
                      seekPos = value;
                      _dragPositionSubject.add(null);
                    },
                  )
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  children: <Widget>[
                    Text(
                      "${position.inMinutes}:${(position.inSeconds.remainder(60).toString().padLeft(2, '0'))}",
                      style: TextStyle(
                        fontFamily: "YTSans",
                        fontSize: 12,
                        color: textColor.withOpacity(0.6)
                      ),
                    ),
                    Spacer(),
                    Text(
                      "${duration.inMinutes}:${(duration.inSeconds.remainder(60).toString().padLeft(2, '0'))}",
                      style: TextStyle(
                        fontFamily: "YTSans",
                        fontSize: 12,
                        color: textColor.withOpacity(0.6)
                      ),
                    )
                  ],
                ),
              )
            ],
          )
          : Container();
      },
    );
  }
}