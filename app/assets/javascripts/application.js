// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require modernizr
//= require prototype
//= require prototype_ujs
//= require s2
//= require prototype/sites_select_title

//= require global

//= require_self
//= require_tree ./ui

document.observe("dom:loaded", function() {
  S2.Extensions.webkitCSSTransitions = true;

  // ================================================================
  // = Password fields, selects and placeholders and forms managers =
  // ================================================================

  // ## Flash notices
  // 
  //   jQuery('#flash .notice').each ->
  //     new MySublimeVideo.UI.Flash(jQuery(this)).setupDelayedHiding()
  // 
  //   jQuery('.hidable_notice').each ->
  //     new HideableNoticeManager jQuery(this)
  // 
  // ## Sites poller
  // SublimeVideo.sitesPoller = new SitesPoller() if jQuery('#sites_table_wrap')
  // 
  // $$('#flash .notice').each(function(element) {
  //   MySublimeVideo.hideFlashMessageDelayed(element);
  // });
  // 
  // $$('.hidable_notice').each(function(element) {
  //   new HideableNoticeManager(element);
  // });
  // 
  // // =====================================
  // // = Add site hanlder and Sites poller =
  // // =====================================
  // if ($("sites_table_wrap")) {
  //   MySublimeVideo.sitesPoller = new SitesPoller();
  // }

  MySublimeVideo.showSiteEmbedCode = function(siteToken) {
    popup = new SublimeVideo.UI.Popup("embed_code_site_#{siteToken}", anchor: "embed_code_site_content_#{siteToken}")
    popup.setContent(jQuery("embed_code_site_content_#{siteToken}").html())
    popup.open()

    return false;
  };
});

// ====================
// = Global functions =
// ====================


MySublimeVideo.openPopup = function(itemId, idPrefix, url, className, anchorId) { // item can be site
  // if (!MySublimeVideo.popupHandler) MySublimeVideo.popupHandler = new PopupHandler();
  MySublimeVideo.popupHandler = new PopupHandler();
  MySublimeVideo.popupHandler.open(itemId, idPrefix, url, className, anchorId);
};

// ====================
// = Onclick handlers =
// ====================


MySublimeVideo.showSiteEmbedCodeWithSSL = function(element, siteToken) {
  var textarea = element.up().previous('textarea');
  if (element.checked) {
    textarea.value = textarea.value.gsub('http://cdn.sublimevideo.net', 'https://4076.voxcdn.com');
  } else {
    textarea.value = textarea.value.gsub('https://4076.voxcdn.com', 'http://cdn.sublimevideo.net');
  }
  return false;
    
  // var text = '';
  // switch (element.value) {
  // case 'no':
  //   text += ' src="http://cdn.sublimevideo.net/js/' + siteToken + '.js">';
  //   break;
  // case 'yes':
  //   text += ' src="https://4076.voxcdn.com/js/' + siteToken + '.js">';
  //   break;
  // case 'mixed':
  //   text += '>document.write(unescape("%3Cscript src=\'" + ((\'https:\' == document.location.protocol) ? "https://4076.voxcdn.com" : "http://cdn.sublimevideo.net") + "/js/' + siteToken + '.js\' type=\'text/javascript\'%3E%3C/script%3E"));';
  //   break;
  // }
  // element.up().previous('textarea').value = '<script type="text/javascript"' + text + '</script>';
  // return false;
};

// ===========
// = Classes =
// ===========

var HideableNoticeManager = Class.create({
  initialize: function(noticeElement) {
    this.noticeElement = noticeElement;
    this.noticeId      = noticeElement.readAttribute('data-notice-id');

    this.setupObservers();
  },
  setupObservers: function() {
    this.noticeElement.down(".close").on("click", this.updateUserAndHideNotice.bind(this));
  },
  updateUserAndHideNotice: function(event) {
    event.stop();
    new Ajax.Request('/hide_notice/' + this.noticeId, { method: 'put' });
    this.noticeElement.fade({ duration: 1.5, after: function(){ this.noticeElement.remove(); }.bind(this) });
  }
});

/*
SitesPoller make poll requests for the retrieving the up-to-dateness state of the assets of sites that don't have their assets up-to-date n the CDN
*/
var SitesPoller = Class.create({
  initialize: function() {
    this.pollingDelay  = 1000;
    this.maxAttempts   = 10; // try for !1000 ms = 55 seconds
    this.attempts      = 0;
    this.currentSiteId = null;
    this.poll          = null;
    this.checkForSiteInProgress();
  },
  checkForSiteInProgress: function() {
    var siteInProgress = $$('#sites span.icon.in_progress').first();
    if (siteInProgress) {
      this.currentSiteId = parseInt(siteInProgress.up('tr').id.replace("site_", ''), 10);
      this.startPolling();
    }
  },
  startPolling: function() {
    if (this.poll) this.stopPolling();
    this.poll = setTimeout(this.remoteCheckForStateUpdate.bind(this), this.pollingDelay * this.attempts);
  },
  stopPolling: function() {
    clearTimeout(this.poll);
    this.poll = null;
  },
  remoteCheckForStateUpdate: function() {
    if (this.attempts < this.maxAttempts) {
      this.attempts++;
      new Ajax.Request('/sites/' + this.currentSiteId + '/state', { method: 'get' });
    }
    else {
      this.stopPolling();
    }
    // this will simply reply with a HEAD OK if the state is still pending, or it'll will call the updateSite() method below if the state changed to active
  },
  updateSite: function(siteId) {
    // Stop polling
    this.stopPolling();

    // Remove "in progress" span
    var inProgressWrap = $$("#site_" + siteId + " span.icon.in_progress").first();
    if (inProgressWrap) inProgressWrap.remove();
    // Show "ok" span
    var okWrap = $$("#site_" + siteId + " td.status.box_hovering_zone div.completed").first();
    if (okWrap) okWrap.show();

    // Check if a restart polling is needed
    this.checkForSiteInProgress();
  }
});

function supportsHtml5InputOfType(inputType) { // e.g. "email"
  var i = document.createElement("input");
  i.setAttribute("type", inputType);
  return i.type !== "text";
}

function supportsHtml5InputAttribute(attribute) { // e.g "placeholder"
  var i = document.createElement('input');
  return attribute in i;
}

function supportsHtml5Storage() {
  try {
    return 'localStorage' in window && window['localStorage'] !== null;
  }
  catch (e) {
    return false;
  }
}


Element.addMethods({
  shake: function(element, options) {
    S2.Extensions.webkitCSSTransitions = false; //essential, cause webkit transitions in this case are less smooth

    element = $(element);
    var originalLeft = parseFloat(element.getStyle('left') || '0');
    var oldStyle = { left:originalLeft };
    element.makePositioned();

    var opts = { distance:15, duration:0.5 };
    Object.extend(opts, options);
    var distance = opts.distance;
    var duration = opts.duration;

    var split = parseFloat(duration) / 10.0;

    var shakeEffect = element.morph('left:' + (originalLeft+distance) + 'px', { duration:split
      }).morph('left:' + (originalLeft-distance) + 'px', { duration:split*2
        }).morph('left:' + (originalLeft+distance) + 'px', { duration:split*2
          }).morph('left:' + (originalLeft-distance) + 'px', { duration:split*2
            }).morph('left:' + (originalLeft+distance) + 'px', { duration:split*2
              }).morph('left:' + (originalLeft) + 'px', { duration:split*2, after: function() {
                element.undoPositioned().setStyle(oldStyle);
                }});

    return shakeEffect;
  },
  pulsate: function(element, options) {
  }
});

function ddd(){console.log.apply(console, arguments);}