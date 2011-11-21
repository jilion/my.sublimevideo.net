document.observe("dom:loaded", function() {
  SublimeVideo.interactiveDemo = new InteractiveDemoHandler();

  $$("#demo nav li a").each(function(navEl){
    navEl.on("click", function(event){
      event.stop();
      var sectionName = navEl.readAttribute("href").replace(/^.*#/,''); 
      $(sectionName).scrollTo();
    });
  });
});

sublimevideo.ready(function(){
  sublimevideo.onStart(function(sv){
    if (sv.element.id=="single_video") {
      SublimeVideo.updateModeBox(sv.mode);
    }
  });
  sublimevideo.onEnd(function(sv){
    if (sv.element.id.match(/video[1-4]/)) {
      SublimeVideo.interactiveDemo.handleAutoNext(sv.element.id);
    }
  });
  
  SublimeVideo.detectedChrome = navigator.userAgent.indexOf("Chrome")!=-1;
  SublimeVideo.detectedWindows = navigator.userAgent.indexOf("Windows")!=-1;
  SublimeVideo.detectedMac = navigator.userAgent.indexOf("Mac")!=-1;
  
  // Disable box shadows on Chrome Mac ( because of this issue http://code.google.com/p/chromium/issues/detail?id=59340 ) 
  // UPDATE: They've finally fixed it in Chrome 11!
  // if (SublimeVideo.detectedChrome && SublimeVideo.detectedMac) {
  //   $(document.body).addClassName('chrome_mac');
  // }
});

SublimeVideo.isWebkitAnimationSupported = function() { // remember to cache the result
  return (typeof WebKitAnimationEvent === "object" || typeof WebKitAnimationEvent === "function");
};

SublimeVideo.fadeInSublimeVideosContainer = function(video, speed) {
  if (SublimeVideo.detectedChrome && SublimeVideo.detectedWindows) return;
  
  // Need mini delay because it's called after prepare() needs a bit of time to move video to its wrapper at the bottom of DOM
  setTimeout(function(){
    var videoWrapper = video.up();
    if (videoWrapper) {
      var animClass = speed=='slow' ? 'slow_fade_in' : 'fade_in';
      videoWrapper.addClassName(animClass);
      var animEnd = videoWrapper.on("webkitAnimationEnd", function(event) {
        animEnd.stop(); // observe "once" behavior
        videoWrapper.removeClassName(animClass);
      });
    }
  },0);
};

SublimeVideo.updateModeBox = function(mode) {
  var modeSwitcher = $('mode_switcher');
  var newModeText = mode == "html5" ? "Flash" : "HTML5";
  modeSwitcher.className = "active "+mode;
  modeSwitcher.down("small em").update(newModeText);
};

var InteractiveDemoHandler = Class.create({
  initialize: function() {
    this.loadDemo();
    this.supportsWebkitAnimation = SublimeVideo.isWebkitAnimationSupported(); // to cache the result
    
    $$("#interactive li").each(function(thumb){
      thumb.on("click", function(event){
        event.stop();
        if (!thumb.hasClassName('active')) {
          this.clickOnThumb(thumb.readAttribute('id'));
        }
      }.bind(this));
    }.bind(this));
  },
  reset: function() {
    // Hide it active video
    $$("#interactive .video_wrap.active").first().removeClassName('active');
    // Get current active video and unprepare it
    sublimevideo.unprepare(this.activeVideoId); // we could have called unprepare() without any arguments, but this is faster
    // PAY ATTENTION, the unprepare method has hidden the video tag
    $(this.activeVideoId).show();
    // Deselect its thumb
    this.deselectThumb(this.activeVideoId);
  },
  clickOnThumb: function(thumbId) {
    // Basically undo all the stuff and bring it back to the point before js kicked in 
    this.reset();
    
    // Set new active video
    this.activeVideoId = thumbId.replace(/thumb_/,'');
    
    // Show it
    var newVideo = this.showVideo(this.activeVideoId);
    
    // PREPARE and play it
    sublimevideo.prepareAndPlay(newVideo);
    
    if (this.supportsWebkitAnimation)
      SublimeVideo.fadeInSublimeVideosContainer(newVideo, 'slow');
  },
  loadDemo: function() {
    if (this.activeVideoId) { //if not the first time here
      this.reset();
    }
    
    this.activeVideoId = "video1";
    
    // Show first video
    var firstVideo = this.showVideo(this.activeVideoId);
  },
  selectThumb: function(videoId) {
    $("thumb_"+videoId).addClassName('active');
  },
  deselectThumb: function(videoId) {
    $("thumb_"+videoId).removeClassName('active');
  },
  showVideo: function(videoId) {
    var video = $(videoId);
    // Show it 
    video.up().addClassName('active');
    // Select its thumb
    this.selectThumb(videoId);
    return video;
  },
  handleAutoNext: function(endedVideoId) {
    var nextId = parseInt(endedVideoId.replace(/video/,''),10) + 1;
    if (nextId>1 && nextId<5) {
      this.clickOnThumb('thumb_video'+nextId);
    }
  }
});
