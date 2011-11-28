var SublimeVideo = SublimeVideo || {};

document.observe("dom:loaded", function() {
  SublimeVideo.playlistDemo = new PlaylistDemo("playlist");
});

if (typeof(sublimevideo) != "undefined") {
  sublimevideo.ready(function(){
    sublimevideo.onStart(function(sv){
      if (sv.element.id=="single_video" && !SublimeVideo.detectedMobile) {
        SublimeVideo.updateModeBox(sv.mode);
      }
      else if (sv.element.id=="home_video") {
        SublimeVideo.showCredits(true);
      }
    });
    sublimevideo.onEnd(function(sv){
      if (sv.element.id.match(/video[1-4]/)) {
        SublimeVideo.playlistDemo.handleAutoNext(sv.element.id);
      }
      else {
        sublimevideo.stop();
        
        if (sv.element.id=="home_video") {
          SublimeVideo.showCredits(false);
        }
      }
    });
  });
}

var ua = navigator.userAgent;
SublimeVideo.detectedMobile = ua.indexOf("Mobile")!=-1 ||
                              ua.indexOf('Windows Phone') != -1 ||
                              ua.indexOf('Android') != -1 ||
                              ua.indexOf('webOS') != -1;

SublimeVideo.updateModeBox = function(mode) {
  var modeSwitcher = $('mode_switcher');
  var newModeText = mode == "html5" ? "Flash" : "HTML5";
  modeSwitcher.className = "active "+mode;
  modeSwitcher.down("small em").update(newModeText);
};

SublimeVideo.showCredits = function(onOff) {
  var credits = $('video_credits');
  var timerIn, timerOut;
  if (credits) {
    if (onOff) {
      timerIn = setTimeout(function(){
        credits.appear({ duration:1 });
      },3000);
    }
    else {
      clearTimeout(timerIn);
      clearTimeout(timerOut);
      credits.fade({ duration:1 });
    }
  }
};

var PlaylistDemo = Class.create({
  initialize: function(interactiveWrapperId) {
    if (!$(interactiveWrapperId)) return;
    
    this.interactiveWrapperId = interactiveWrapperId;
    this.videosCount = $$("#" + this.interactiveWrapperId + " .video_wrap").size();
    
    var matches = $$("#" + this.interactiveWrapperId + " video")[0].id.match(/^video(\d+)$/);
    this.firstVideoIndex = parseInt(matches[1], 10);
    
    this.setupObservers();
    
    this.loadDemo();
  },
  setupObservers: function() {
    $$("#" + this.interactiveWrapperId + " li").each(function(thumb) {
      thumb.on("click", function(event) {
        event.stop();
        
        if (!thumb.hasClassName("active")) {
          this.clickOnThumbnail(thumb.readAttribute("id"));
        }
      }.bind(this));
    }.bind(this));
  },
  loadDemo: function() {
    // Only if not the first time here
    if (this.activeVideoId) this.reset();
    
    this.activeVideoId = "video" + this.firstVideoIndex;
    
    // Show first video
    this.showActiveVideo();
  },
  reset: function() {
    // Hide the current active video
    $$("#" + this.interactiveWrapperId + " .video_wrap.active").first().removeClassName("active");
    
    // Get current active video and unprepare it
    // we could have called sublimevideo.unprepare() without any arguments, but this is faster
    sublimevideo.unprepare(this.activeVideoId);
    
    // Deselect its thumbnail
    this.deselectThumbnail(this.activeVideoId);
  },
  clickOnThumbnail: function(thumbnailId) {
    // Basically undo all the stuff and bring it back to the point before js kicked in
    this.reset();
    
    // Set the new active video
    this.activeVideoId = thumbnailId.replace(/^thumbnail_/, "");
    
    // And show the video
    this.showActiveVideo();
    
    // And finally, prepare and play it
    sublimevideo.prepareAndPlay(this.activeVideoId);
  },
  selectThumbnail: function(videoId) {
    $("thumbnail_" + videoId).addClassName("active");
  },
  deselectThumbnail: function(videoId) {
    $("thumbnail_" + videoId).removeClassName("active");
  },
  showActiveVideo: function() {
    // Select its thumbnail
    this.selectThumbnail(this.activeVideoId);
    
    // Show it
    $(this.activeVideoId).up().addClassName("active");
  },
  handleAutoNext: function(endedVideoId) {
    var nextId = parseInt(endedVideoId.replace(/^video/, ""), 10) + 1;
    if (nextId > 1 && nextId < this.firstVideoIndex + this.videosCount) {
      this.clickOnThumbnail("thumbnail_video" + nextId);
    }
    else { // last video in the playlist
      sublimevideo.stop();
    }
  }
});
