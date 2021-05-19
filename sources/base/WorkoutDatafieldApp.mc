using Toybox.Application;

class WorkoutDatafieldApp extends Application.AppBase {

  function initialize() { AppBase.initialize(); }

  // onStart() is called on application start up
  function onStart(state) {}

  function onStop(state) {}

  function getInitialView() { return [new WorkoutDatafieldView()]; }
}