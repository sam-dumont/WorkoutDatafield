using Toybox.WatchUi;
using Toybox.Attention;
using Toybox.UserProfile;
using Toybox.AntPlus;
using Toybox.System as Sys;

class WorkoutDatafieldView extends WatchUi.DataField {
  hidden var alertDelay;
  hidden var alternateMetric = false;
  hidden var correctionTimestamp = 0;
  hidden var currentSpeed;
  hidden var elapsedDistance;
  hidden var durationType;
  hidden var durationValue;
  hidden var fontOffset = 0;
  hidden var fonts;
  hidden var hr = 0;
  hidden var hrZones;
  hidden var maxAlerts;
  hidden var paused = true;
  hidden var powerAverage;
  hidden var remainingDistance = 0;
  hidden var remainingTime = 0;
  hidden var sensor;
  hidden var showAlerts;
  hidden var showColors;
  hidden var shouldDisplayAlert;
  hidden var stepTime = 0;
  hidden var stepStartDistance = 0;
  hidden var stepStartTime = 0;
  hidden var targetHigh = 0;
  hidden var targetLow = 0;
  hidden var timer;
  hidden var useMetric;
  hidden var useSpeed;
  hidden var vibrate;
  hidden var stepType;

  function initialize() {

    showAlerts =
        Utils.replaceNull(Application.getApp().getProperty("C"), true);

    vibrate =
        Utils.replaceNull(Application.getApp().getProperty("D"), true);

    showColors =
        Utils.replaceNull(Application.getApp().getProperty("F"), 1);

    alertDelay =
        Utils.replaceNull(Application.getApp().getProperty("G"), 15);

    maxAlerts =
        Utils.replaceNull(Application.getApp().getProperty("H"), 3);

    useSpeed =
        Utils.replaceNull(Application.getApp().getProperty("J"), false);

    useMetric = System.getDeviceSettings().paceUnits == System.UNIT_METRIC
                    ? true
                    : false;

    set_fonts();
    
    DataField.initialize();
    
    hrZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
  }

  function onTimerStart() { paused = false; }

  function onTimerStop() { paused = true; }

  function onTimerResume() { paused = false; }

  function onTimerPause() { paused = true; }

  function onTimerLap() {}

  function onWorkoutStepComplete() {
    stepStartDistance = elapsedDistance;
    stepStartTime = timer;
    
  }

  function onTimerReset() {
  }

  (:highmem) function set_fonts() {
    if (Utils.replaceNull(Application.getApp().getProperty("I"), true)) {
      fontOffset = -4;
      fonts = [
        WatchUi.loadResource(Rez.Fonts.A), WatchUi.loadResource(Rez.Fonts.C),
        WatchUi.loadResource(Rez.Fonts.C), WatchUi.loadResource(Rez.Fonts.D),
        WatchUi.loadResource(Rez.Fonts.E), WatchUi.loadResource(Rez.Fonts.E)
      ];
    } else {
      fonts = [ 0, 1, 2, 3, 7, 8 ];
    }
  }

  (:lowmemlow) function set_fonts() { fonts = [ 0, 1, 2, 3, 7, 8 ]; }

  (:lowmemlarge) function set_fonts() {
    fontOffset = 2;
    fonts = [ 0, 1, 2, 3, 7, 8 ];
  }

  function onLayout(dc) { return true; }

  function compute(info) {
    if (info has :currentHeartRate) {
      hr = info.currentHeartRate;
    }

    if (info has :currentSpeed) {
      currentSpeed = info.currentSpeed;
    }

    if (paused != true) {
      if (info != null) {

        var workout = Activity.getCurrentWorkoutStep();

        timer = info.timerTime / 1000;
        stepTime = timer - stepStartTime;
        elapsedDistance = info.elapsedDistance;

        shouldDisplayAlert = (stepTime > alertDelay);

        if (workout != null) {

          stepType = workout.step.targetType;
          durationType = workout.step.durationType;
          durationValue = workout.step.durationValue;
          targetHigh = workout.step.targetValueHigh;
          targetLow = workout.step.targetValueLow;


          if (stepType == 1){
              if (targetHigh < 100) {
                targetHigh = ((targetHigh / 100.0) * hrZones[5]).toNumber();
              } else {
                targetHigh = targetHigh - 100;
              }
              if (targetLow < 100) {
                targetLow = ((targetLow / 100.0) * hrZones[5]).toNumber();
              } else {
                targetLow = targetLow - 100;
              }
          }


          if (stepType != null && durationType == 1) {
            if (durationValue != null && remainingDistance >= 0) {
              remainingDistance = durationValue -
                                  (elapsedDistance.toNumber() -
                                   stepStartDistance);
            }
          } else if (stepType != null && durationType == 0) {
            if (durationValue != null &&
                remainingTime >= 0) {
              remainingTime =
                  (durationValue - stepTime).toNumber();
              if (shouldDisplayAlert && remainingTime < 20) {
                shouldDisplayAlert = false;
              }
            }
          }
        } 
      }
    }

    if(timer != null && timer % 5 == 0){
      alternateMetric = !alternateMetric;
    }
    
    return true;
  }

  function onUpdate(dc) {
    if (dc has :setAntiAlias){
      dc.setAntiAlias(true);
    }

    dc.clear();

    var width = dc.getWidth();
    var height = dc.getHeight();

    var bgColor = getBackgroundColor();
    var fgColor = bgColor == 0x000000 ? 0xFFFFFF : 0x000000;

    var geometry = [
      width / 2, height / 2, height * 0.70, height * 0.4, height * 0.1, height * 0.3// horizontal
    ];

    drawMetric(dc,0,0,0,width,geometry[1],1,bgColor,fgColor);
    drawMetric(dc,1,10,geometry[3],geometry[0],geometry[4],2,-1,0xFFFFFF);
    drawMetric(dc,2,geometry[1],geometry[3],geometry[0] - 10,geometry[4],0,-1,0xFFFFFF);
    drawMetric(dc,3,0,geometry[1],geometry[0],geometry[5],0,bgColor,fgColor);
    drawMetric(dc,5,geometry[1],geometry[1],geometry[0],geometry[5],2,bgColor,fgColor);
    drawMetric(dc,6,geometry[1],geometry[2],geometry[0],geometry[5],2,bgColor,fgColor);
    drawMetric(dc,4,0,geometry[2],geometry[0],geometry[5],0,bgColor,fgColor);

    dc.setColor(fgColor,-1);
    // draw the lines
    dc.drawLine(0, geometry[1], width, geometry[1]);
    dc.drawLine(geometry[0], geometry[1], geometry[0], height);
    dc.drawLine(0, geometry[2], width, geometry[2]);
  }

  function drawMetric(dc,type,x,y,width,height,align,bgColor,fgColor) {
    dc.setColor(bgColor,bgColor);
    dc.fillRectangle(x, y, width, height);
    dc.setColor(fgColor,-1);

    var label = "";
    var value = "";
    var textx = x + (width / 2);
    var labelx = textx;
    var labelFont = fonts[0];
    var textFont = fonts[3];
    var localOffset = 0;
    var labelOffset = 0;
    var showText = true;

    if(align == 0){
      textx = x + width - 3;
      labelx = textx;
    } else if(align == 2){
      textx = x + 3;
      labelx = textx;
    }

    if (type == 0){
      label = "";
      textFont = fonts[5];
      if(stepType == 0) {
        value = currentSpeed == null ? Utils.convert_speed_pace(0,useMetric,useSpeed) : Utils.convert_speed_pace(currentSpeed,useMetric,useSpeed);
        if(currentSpeed < targetLow){
          dc.setColor(0x0000FF, -1);
        } else if(currentSpeed > targetHigh) {
          dc.setColor(0xAA0000, -1);
        } else {
          dc.setColor(0x00AA00, -1);
        }
        dc.fillRectangle(x, y, width, height);
        dc.setColor(0xFFFFFF, -1);
      } else if (stepType == 1) {
        value = hr == null ? 0 : hr;
        if(hr < targetLow){
          dc.setColor(0x0000FF, -1);
        } else if(hr > targetHigh) {
          dc.setColor(0xAA0000, -1);
        } else {
          dc.setColor(0x00AA00, -1);
        }
        dc.fillRectangle(x, y, width, height);
        dc.setColor(0xFFFFFF, -1);
      } else {
        value = "---";
      }
    } else if(type == 1){
      showText = false;
      label = stepType == 0 ? Utils.convert_speed_pace(targetLow, useMetric, useSpeed) : targetLow;
      labelFont = fontOffset == -4 ? fonts[1] : fonts[0];
      labelOffset = fontOffset == -4 ? 2 : 1;
    } else if(type == 2){
      showText = false;
      label = stepType == 0 ? Utils.convert_speed_pace(targetHigh, useMetric, useSpeed) : targetHigh;
      labelFont = fontOffset == -4 ? fonts[1] : fonts[0];
      labelOffset = fontOffset == -4 ? 2 : 1;
    } else if(type == 3){
      var distance = Utils.format_distance(remainingDistance, useMetric);
      value = durationType == 0 ? Utils.format_duration(remainingTime) : distance[0]+distance[1];
      label = durationType == 0 ? "REM TIME" : "REM DIST";
    } else if(type == 4){
      value = stepType == 1 ? Utils.convert_speed_pace(currentSpeed,useMetric,useSpeed) : (hr == null ? 0 : hr);
      label = stepType == 1 ? (useSpeed ? "SPEED" : "PACE") : "HR";
      if(stepType == 0 && hr != null){
        if (showColors == 1) {
          if (hr > hrZones[4]) {
            dc.setColor(0xFF0000, -1);
          } else if (hr > hrZones[3]) {
            dc.setColor(0xFF5500, -1);
          } else if (hr > hrZones[2]) {
            dc.setColor(0x00AA00, -1);
          } else if (hr > hrZones[1]) {
            dc.setColor(0x0000FF, -1);
          } else {
            dc.setColor(0x555555, -1);
          }
          dc.fillRectangle(x, y, width, height);
          dc.setColor(0xFFFFFF, -1);
        } else if (showColors == 2) {
          if (hr > hrZones[4]) {
            dc.setColor(0xFF0000, -1);
          } else if (hr > hrZones[3]) {
            dc.setColor(0xFF5500, -1);
          } else if (hr > hrZones[2]) {
            dc.setColor(0x00AA00, -1);
          } else if (hr > hrZones[1]) {
            dc.setColor(0x0000FF, -1);
          } else {
            dc.setColor(0x555555, -1);
          }
        }
      }
    } else if(type == 5){
      value = Utils.format_duration(timer == null ? 0 : timer);
      label = "EL TIME";
    } else if(type == 6){
      var distance = Utils.format_distance(elapsedDistance == null ? 0 : elapsedDistance, useMetric);
      value = distance[0]+distance[1];
      label = "EL DIST";
    } 

    dc.drawText(labelx, y + (fontOffset * (1 + labelOffset)), labelFont, label, align);

    if(showText){
      dc.drawText(textx, y + (fontOffset * (5 + localOffset)) + 15, textFont, value, align);
    }
  }

}