var SublimeVideoSizeChecker = SublimeVideoSizeChecker || {};

SublimeVideoSizeChecker.rootPath = "";

SublimeVideoSizeChecker.setRoot = function(path) {
  SublimeVideoSizeChecker.rootPath = path.replace(/\/$/,'')+'/';
};

SublimeVideoSizeChecker.getVideoSize = function(url, callback) {
  SublimeVideoSizeChecker.callback = callback;

  if (SublimeVideoSizeChecker.isHtml5VideoSupported()) {
    var video = document.createElement('video');
    var support = video.canPlayType(SublimeVideoSizeChecker.mediaTypeFromFileName(url));
    if  (support == "maybe" || support == "probably") {
      SublimeVideoSizeChecker.html5Check(video, url, callback);
    } else SublimeVideoSizeChecker.flashCheck(url, callback);
  } else {
    SublimeVideoSizeChecker.flashCheck(url, callback);
  }
};

SublimeVideoSizeChecker.html5Check = function(video, url, callback) {
  video.src     = url;
  video.width   = video.height = video.volume = 0;
  video.preload = "auto";
  video.play();
  video.addEventListener('error', function(e) {
    callback();
    document.body.removeChild(video);
  }, false);
  var hasLoadedMetaData = false;
  video.addEventListener('loadedmetadata', function(e) {
    if (video) {
      hasLoadedMetaData = true;
      var width  = video.videoWidth;
      var height = video.videoHeight;
      var size   = width > 0 && height > 0 ? { width: width, height: height } : undefined;
      callback(url, size);
      document.body.removeChild(video);
    }
  }, false);

  document.body.appendChild(video);

  setTimeout(function() {
    if (!hasLoadedMetaData) {
      callback();
      document.body.removeChild(video);
      video = null;
    }
  }, 8000);
};

SublimeVideoSizeChecker.flashCheck = function(url, callback) {
  var flashWrap  = document.createElement('div');
  flashWrap.id   = "video_size_checker";
  var flashvars  = { videoUrl: url };
  var params     = { allowscriptaccess: "always" };
  var attributes = {};
  document.body.appendChild(flashWrap);
  swfobject.embedSWF(SublimeVideoSizeChecker.rootPath+"video-size-checker.swf", flashWrap.id, "0", "0", "9.0.0", SublimeVideoSizeChecker.rootPath+"expressInstall.swf", flashvars, params, attributes);
};

SublimeVideoSizeChecker.getVideoSizeFlashCallback = function(url, size) {
  SublimeVideoSizeChecker.callback(url, size);
  var embed = document.getElementById('video_size_checker');
  document.body.removeChild(embed);
};

SublimeVideoSizeChecker.isHtml5VideoSupported = function() {
  return !!document.createElement('video').canPlayType;
};

SublimeVideoSizeChecker.mediaTypeFromFileName = function(path) {
  if (path.match(/\.og[gv](\?[^?\/]*)?$/i)) {
    return "video/ogg";
  }
  else if (path.match(/\.webm(\?[^?\/]*)?$/i)) {
    return "video/webm";
  }
  else {
    return "video/mp4";
  }
};