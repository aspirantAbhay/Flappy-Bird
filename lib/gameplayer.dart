import 'dart:async';
import 'dart:io';

import 'package:control_pad/control_pad.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:flame/flame.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:mobilegameengine/gamecore/lib/compandactvariables.dart';

import 'admobads2.dart';
import 'compandactvariables.dart';
import 'gameview.dart';

import 'globalvars.dart';

import 'package:mic_stream/mic_stream.dart';
import 'dart:math' as math;

import 'package:sensors/sensors.dart';

import 'dart:ui' as ui;

BuildContext playercontext;
Offset listeneroffset = Offset(0, 0);

class Gameplayer extends StatefulWidget {
  final String currentscene;
  final bool isdebug;
  final bool isplayground;
  final bool isworkspace2;

  Gameplayer(this.currentscene,
      {this.isdebug = false,
      this.isplayground = false,
      this.isworkspace2 = false});
  @override
  _GameplayerState createState() => _GameplayerState();
}

class _GameplayerState extends State<Gameplayer> {
  StreamSubscription<List<int>> listener;

  void start() async {
    Stream<List<int>> stream = microphone(
        sampleRate: 16000, channelConfig: ChannelConfig.CHANNEL_IN_STEREO);
    listener = stream.listen((samples) {
      miclevel = samples.reduce(math.max).toDouble() - 130;
    });
  }

  void stop() async {
    if (listener != null) {
      listener.cancel();
    }
  }

  StreamSubscription accelerometerEvent;
  StreamSubscription gyroscopeEvent;
  int splashbackground = Color(0xFF2A2E49).value;
  String splashtext = "M A D E  W I T H";

  bool ismanaprojecsettingsloaded = false;

  Image splashimage = Image.asset("assets/logo.png");
  String splashimagepath = imagespath;

  void loadsplashimage() {
    if (getprojectsettingscore().splashimage == null) {
      return;
    }
    if (getprojectsettingscore().splashimage == "Max2D Logo") {
      return;
    }
    File imagepath = File(imagespath + getprojectsettingscore().splashimage);

    splashimage = Image.file(imagepath);

    // ImageStream _imageStream;
    // ImageProvider temp = Image.file(imagepath).image;

    // _imageStream = temp.resolve(createLocalImageConfiguration(context));
    // // loadedimages.addAll({path.basename(thepath): noimage});
    // _imageStream.addListener(
    //     new ImageStreamListener((ImageInfo info, bool synchronousCall) {
    //   splashimage = info.image;
    //   // loadedimages.update(path.basename(thepath), (value) => info.image);
    //   // print(info.image);
    // }));
  }

  @override
  void initState() {
    isprojectloaded = false;
    isworkspace = widget.isworkspace2;

    loadprojectsettings().then((onValue) async {
      loadsplashimage();
      ismanaprojecsettingsloaded = true;
      setState(() {});
      if (getprojectsettingscore().orientation == "portrait") {
        Flame.util.setPortrait();
      } else if (getprojectsettingscore().orientation == "landscape") {
        Flame.util.setLandscape();
      }
      if (getprojectsettingscore().splashbackground != null) {
        // print(splashbackground);
        splashbackground = getprojectsettingscore().splashbackground;
        splashtext = getprojectsettingscore().splashtext;
        // print(splashbackground);
      }
      await theads2.initialize(widget.isdebug);
      loadprojectcore(widget.isplayground
              ? getprojectsettingscore().startingscene
              : widget.currentscene)
          .then((onValue) async {
        await loadimagesfromfile(context);

        Future.delayed(
            Duration(milliseconds: widget.isplayground ? 2000 : 1000), () {
          isprojectloaded = true;
          setState(() {});
        });

        if (getprojectsettingscore().usingmicrophone) {
          start();
        }
      });
    });

    accelerometerEvent = accelerometerEvents.listen((AccelerometerEvent event) {
      accelerometervalue.x = event.x;
      accelerometervalue.y = event.y;
      accelerometervalue.z = event.z;
    });

    gyroscopeEvent = gyroscopeEvents.listen((GyroscopeEvent event) {
      gyroscopevalue.x = event.x;
      gyroscopevalue.y = event.y;
      gyroscopevalue.z = event.z;
    });

    super.initState();
  }

  @override
  void dispose() {
    Flame.util.setLandscape();
    for (int a = 0; a < soundslistscore.length; a++) {
      Clscompsound t = soundslistscore[a];
      t.stop();
    }
    if (getprojectsettingscore().usingmicrophone) {
      stop();
    }

    gameobjectitemscore.clear();
    cameracomponentscore.clear();
    globalvariablescore.clear();
    soundslistscore.clear();

    theads2.hideBannerAd();

    accelerometerEvent.cancel();
    gyroscopeEvent.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ismanaprojecsettingsloaded) {
      return Container();
    }
    playercontext = context;
    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isprojectloaded) {
      gv = Gameview(context, isdebug: widget.isdebug);
    }

    return Scaffold(
      backgroundColor: Color(splashbackground),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: isprojectloaded
                ? Stack(
                    children: [
                      Listener(
                          onPointerDown: (event) {
                            gv.onTouchDown(event);
                          },
                          onPointerUp: (event) {
                            // if (!checkbuttonlocations("up")) {
                            gv.onTouchUp(event);
                            //  }
                          },
                          onPointerMove: (event) {
                            // listeneroffset = event.position;
                            //  if (!checkbuttonlocations("move")) {
                            gv.onTouchMove(event);
                            //   }
                          },
                          onPointerCancel: (event) {},
                          child: gv.widget),
                      TheUIcomponents()
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Spacer(),
                        Text(
                          splashtext,
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        Container(width: 100, height: 100, child: splashimage),
                        Spacer(),
                        //
                        Text(
                          "Loading resources...",
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        Container(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.isplayground == false
          ? DraggableFab(
              child: FloatingActionButton(
                backgroundColor: Color.fromARGB(255, 70, 70, 70),
                onPressed: () {
                  for (int a1 = 0; a1 < soundslistscore.length; a1++) {
                    Clscompsound t = soundslistscore[a1];
                    t.stop();
                  }
                  Flame.util.setLandscape();
                  if (getprojectsettingscore().orientation == "portrait") {
                    Future.delayed(Duration(milliseconds: 100), () {
                      Navigator.of(context).pop();
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: FaIcon(
                  FontAwesomeIcons.stop,
                  size: 16,
                ),
              ),
            )
          : Container(),
    );
  }
}

class TheUIcomponents extends StatefulWidget {
  // final bool isdebug;
  TheUIcomponents();
  @override
  _TheUIcomponentsState createState() => _TheUIcomponentsState();
}

class _TheUIcomponentsState extends State<TheUIcomponents> {
  @override
  void initState() {
    // TODO: implement initState
    refreshuicomponents = () {
      setState(() {});
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(uicomponentscore.length);
    return Stack(
        children: List.generate(uicomponentscore.length, (index) {
      Clsuicomponent t = uicomponentscore[index];
      if (t is Clsuijoystickdirectional) {
        return Positioned(
          bottom: t.posbottom.isNaN ? null : t.posbottom,
          left: t.posleft.isNaN ? null : t.posleft,
          right: t.posright.isNaN ? null : t.posright,
          top: t.postop.isNaN ? null : t.postop,
          child: JoystickView(
            backgroundColor: Color(t.backgroundcolor),
            innerCircleColor: Color(t.knobcolor),
            size: t.size,
            showArrows: false,
            interval: Duration(milliseconds: 16),
            onDirectionChanged: (val, val2, x, y) {
              gv.onJoystickDirectionChanged(Joystickvalues(
                  val,
                  val2,
                  x == 0 ? 0 : math.cos(val),
                  y == 0 ? 0 : -math.sin(val),
                  t.variablename));
            },
          ),
        );
      }

      if (t is Clsuibutton) {
        // buttonlisteners.add(t);
        return Positioned(
            bottom: t.posbottom.isNaN ? null : t.posbottom,
            left: t.posleft.isNaN ? null : t.posleft,
            right: t.posright.isNaN ? null : t.posright,
            top: t.postop.isNaN ? null : t.postop,
            child: theuibutton(t));
      }
      if (t is Clsuiadbanner) {
        theads2.anchor = t.anchor;
        theads2.bannersize = t.bannersize;
        if (t.bannerid != null) {
          if (t.bannerid.length > 0) {
            theads2.bannerid = t.bannerid;
          }
        }
        if (getprojectsettingscore().admobapplicationid != null) {
          if (getprojectsettingscore().admobapplicationid.length > 0) {
            theads2.appid = getprojectsettingscore().admobapplicationid;
          }
        }
      }

      return Container();
    }));
  }
}

// List<Clsuibutton> buttonlisteners = List();

// bool checkbuttonlocations(String whatevent,int index) {
//   double screenheight = MediaQuery.of(playercontext).size.height;
//   double screenwidth = MediaQuery.of(playercontext).size.width;
//   bool naaynaigo = false;
//   for (int a = 0; a < buttonlisteners.length; a++) {
//     double top = buttonlisteners[a].postop;
//     double bottom = buttonlisteners[a].posbottom;
//     double left = buttonlisteners[a].posleft;
//     double right = buttonlisteners[a].posright;

//     double height = buttonlisteners[a].height;
//     double width = buttonlisteners[a].width;

//     if (top.isNaN) {
//       top = screenheight - bottom - height;
//     }
//     if (left.isNaN) {
//       left = screenwidth - right - width;
//     }
//     bool isnaa = false;
//     if (listeneroffset.dx > left && listeneroffset.dx < left + width) {
//       if (listeneroffset.dy > top && listeneroffset.dy < top + height) {
//         isnaa = true;
//         naaynaigo = true;
//       }
//     }
//     if (isnaa && whatevent != "up") {
//       if (buttonlisteners[a].isentering == false) {
//         buttonlisteners[a].isenteredoutside=true;
//         buttononfocus(buttonlisteners[a]);

//       }
//     } else {
//       if (buttonlisteners[a].isentering == true && buttonlisteners[a].isenteredoutside) {
//         buttononfocusout(buttonlisteners[a]);
//       }
//     }
//   }
//   return naaynaigo;
// }

void buttononfocus(Clsuibutton t) {
  if (t.isentering == false) {
    t.isentering = true;
    t.scale = 1.1;
    refreshuicomponents();
    gv.onButtonEvent(Buttonvalues(t.variablename, "tapdown"));
  }
}

void buttononfocusout(Clsuibutton t) {
  if (t.isentering) {
    t.isentering = false;
    t.scale = 1;
    refreshuicomponents();
    gv.onButtonEvent(Buttonvalues(t.variablename, "tapup"));
  }
}

void buttononcancel(Clsuibutton t) {
  if (t.isentering) {
    t.isentering = false;
    t.scale = 1;
    refreshuicomponents();
    gv.onButtonEvent(Buttonvalues(t.variablename, "tapcancel"));
  }
}

Widget theuibutton(Clsuibutton t) {
  return Listener(
    onPointerDown: (details) {
      buttononfocus(t);
    },
    onPointerUp: (details) {
      buttononfocusout(t);
    },
    onPointerMove: (details) {
      listeneroffset = details.position;
      double screenheight = MediaQuery.of(playercontext).size.height;
      double screenwidth = MediaQuery.of(playercontext).size.width;

      double top = t.postop;
      double bottom = t.posbottom;
      double left = t.posleft;
      double right = t.posright;

      double height = t.height;
      double width = t.width;

      if (top.isNaN) {
        top = screenheight - bottom - height;
      }
      if (left.isNaN) {
        left = screenwidth - right - width;
      }
      bool isnaa = false;
      if (listeneroffset.dx > left && listeneroffset.dx < left + width) {
        if (listeneroffset.dy > top && listeneroffset.dy < top + height) {
          isnaa = true;
        }
      }
      if (isnaa == false) {
        buttononcancel(t);
      }
    },
    child: Transform.scale(
      scale: t.scale,
      child: Container(
        color: Color(t.color),
        width: t.width,
        height: t.height,
      ),
    ),
  );
}
