var MySublimeVideo = MySublimeVideo || {};

document.observe("dom:loaded", function() {
  
  S2.Extensions.webkitCSSTransitions = true;
  
  // ================================================================
  // = Password fields, selects and placeholders and forms managers =
  // ================================================================
  
  $$('input[type=password]').each(function(input, index){
    new ShowPasswordFieldManager(input, index);
  });
  
  if (!supportsHtml5InputAttribute("placeholder")) {
    $$("input[placeholder]").each(function(input){
      new PlaceholderManager(input);
    });
    $$("textarea[placeholder]").each(function(textarea){
      new PlaceholderManager(textarea);
    });
  }
  
  $$("form").each(function(form){
    new FormManager(form);
  });
  
  // =================
  // = Flash notices =
  // =================
  
  $$('#flash .notice').each(function(element){
    MySublimeVideo.hideFlashMessageDelayed(element);
  });
  
  // =====================================
  // = Add site hanlder and Sites poller =
  // =====================================
  if ($("new_site")) {
    MySublimeVideo.addSiteHandler = new AddSiteHandler();
    MySublimeVideo.sitesPoller = new SitesPoller();
  }
  
  
  // ===================================================
  // = Fix a <select> CSS bug in Safari (under v4.0.5) =
  // ===================================================
  var webkitVersionNumber = navigator.userAgent.match(/AppleWebKit\/([0-9]+)./);
  var isSafari405OrPrevious = navigator.userAgent.indexOf("Macintosh") > -1 &&
                              webkitVersionNumber &&
                              parseInt(webkitVersionNumber[1],10) <= 531; // NOTE: Safari 4.0.4 and 4.0.5 have the same webkit version number (531)
                                                                          // Safari 5.0 has webkit version 533
                                                                          // Safari 4.0.5 is the last version pre-5.0
  
  if (isSafari405OrPrevious) {
    $$('select').each(function(element){
      element.setStyle({ fontFamily:"Lucida Grande, Arial, sans-serif", fontSize:"15px" });
    });
  }

});

// ====================
// = Global functions =
// ====================

MySublimeVideo.flashMessage = function(type, message) {
  var flashDiv = $("flash");
  if (flashDiv) flashDiv.remove();
  
  var noticeDiv = new Element("div", { className:type }).update(message);
  flashDiv = new Element("div", { id:"flash" }).insert(noticeDiv);
  $("content").insert({ top: flashDiv });
  
  MySublimeVideo.hideFlashMessageDelayed(noticeDiv);
};

MySublimeVideo.hideFlashMessageDelayed = function(flashEl) {
  setTimeout(function(){
    flashEl.morph('top:-35px', { duration: 0.7 });
  }, 15000);
};

MySublimeVideo.openPopup = function(itemId, idPrefix, url) { // item can be site
  if (!MySublimeVideo.popupHandler) MySublimeVideo.popupHandler = new PopupHandler();
  MySublimeVideo.popupHandler.open(itemId, idPrefix, url);
};


// ====================
// = Onclick handlers =
// ====================

MySublimeVideo.closePopup = function() {
  if (!MySublimeVideo.popupHandler) MySublimeVideo.popupHandler = new PopupHandler();
  MySublimeVideo.popupHandler.close();
  return false;
};

MySublimeVideo.makeSticky = function(element) {
  $$('#header .active').each(function(el){
    el.removeClassName('active');
  });
  element.addClassName("active");
};

MySublimeVideo.makeRemoteLinkSticky = function(element) {
  var container = element.up();
  container.select("a.active[data-remote]").each(function(el){
    el.removeClassName('active');
  });
  element.addClassName("active");
};

MySublimeVideo.showTableSpinner = function() {
  $('table_spinner').show();
};

MySublimeVideo.showSiteEmbedCode = function(siteId) {
  MySublimeVideo.openPopup(siteId, "embed_code_site", '/sites/'+siteId);
  return false;
};

MySublimeVideo.showSiteSettings = function(siteId) {
  MySublimeVideo.openPopup(siteId, "settings", '/sites/'+siteId+'/edit');
  return false;
};

MySublimeVideo.showSiteUsage = function(siteId) {
  MySublimeVideo.openPopup(siteId, "usage", '/sites/'+siteId+'/usage');
  return false;
};

MySublimeVideo.showSiteAddons = function(siteId) {
  MySublimeVideo.openPopup(siteId, "settings", '/sites/'+siteId+'/addons/edit');
  return false;
};


// ===========
// = Classes =
// ===========

var AddSiteHandler = Class.create({
  initialize: function() {
    this.setup();
  },
  setup: function() { //call this after ajax call to re-setup this handler
    this.element = $("new_site"); // this is a <form>
    
    this.beforeAjaxHandler = this.element.on('ajax:before', function(){
      this.numberOfRequestsUntilSpinnerHides = 1;
      this.element.next(".spinner").show();
      //only listen to this once (we can stop the listener now) because this.element will soon be replaced
      this.beforeAjaxHandler.stop();
    }.bind(this));
    
    // Unfourtunately we can't use: this.completeAjaxHandler = this.element.on('ajax:complete', function(event){....
    // ...because on successful creation, create.js.erb will execute two new Ajax requests one of which will
    // reload this form, hence it would be too early to reload/resetup the placeholder here...
  },
  reloadAfterAjax: function() {
    // Note: at this point, this.element has already been replaced
    
    this.hideSpinner();
    
    this.setup();
    
    // Re-apply other handlers (form and placeholder managers)
    if (!supportsHtml5InputAttribute("placeholder")) {
      new PlaceholderManager(this.element.down("input[placeholder]"));
    }
    new FormManager(this.element);
  },
  hideSpinner: function() { //tries to hide spinners (unless another ajax request must still complete)
    this.numberOfRequestsUntilSpinnerHides -= 1;
    
    if (this.numberOfRequestsUntilSpinnerHides == 0) {
      $('new_site_wrap').down(".spinner").hide();
    }
  }
});

/*
FormManager manages:
  on form submit:
    - disabling of submit button
    - asking for password
    - cleaning of pseudo-placeholders
    - cleaning HTML5 errors that are not present anymore but there still are errors (on other fields)
*/
var FormManager = Class.create({
  initialize: function(form) {
    var submitEvent = Prototype.Browser.IE ? "emulated:submit" : "submit";
    form.on(submitEvent, function(event) {
      // Disable submit button for ajax forms to prevent double submissions (quickly click muliple times the form submit button)
      //
      // (PAY ATTENTION: this considers that the ajax call will re-render the entire form hence re-enabling the submit button. 
      //  If we'll have some ajax forms that won't reload themselves, the code below must be updated)
      if (form.readAttribute("data-remote") != null) {
        form.select("input[type=submit]","button").each(function(button) {
          button.disable();
        });
      }
      
      if (form.readAttribute("data-password-protected") == "true") {
        event.stop(); // don't submit form
        MySublimeVideo.passwordCheckerManager = new PasswordCheckerManager(event.element());
      }
      
      // Reset pseudo-placeholders values (for browsers who don't support HTML5 placeholders)
      if (!supportsHtml5InputAttribute("placeholder")) {
        form.select("input.placeholder").each(function(input) {
          input.value = "";
        });
      }
    });
    
    form.select("input[type=submit]").each(function(submitButton) {
      submitButton.on("click", function() { //when HTML5 form validitation doesn't pass, the submit event is not fired
        // HTML5 Input validity
        form.select("input").each(function(input) {
          if (input.validity) {
            if (input.validity.valid) input.removeClassName("errors");
            else input.addClassName("errors");
          }
        });
      });
    });
  }
});

var PasswordCheckerManager = Class.create({
  initialize: function(originForm) {
    this.originForm = originForm;
    MySublimeVideo.openPopup(0, "password_checker", null);
    this.popup = $("password_checker_0");
    
    if (this.popup) {
      this.popup.removeClassName("loading");
      
      var passwordCheckerForm = new Element("form", {
        id:"password_checker",
        action:"/password/validate",
        "data-remote":"true"
      }).update("<div class='entry site'>" +
      "<label for='password_check'>Your current password is needed to perform this action:</label>" +
      "<input type='password' id='password_check' name='password' placeholder='Please enter your current password' class='text' />" +
      "<div class='actions'><input type='submit' class='submit small' value='Done' /></div>" +
      "</div>");
      passwordCheckerForm.store("originFormId", this.originForm.id);
      this.popup.down(".content").update(passwordCheckerForm);
      $('password_check').focus();
    }
  }
});


/*
ShowPasswordFieldManager manages:
  - showing/hiding in clear text the entered password
*/
var ShowPasswordFieldManager = Class.create({
  initialize: function(field, index) {
    this.field = field;
    this.field.store("showPasswordFieldManager", this); // so that the placeholderManager can eventually pick this up
    
    // Only add the Show password checkbox if the input field has the "show_password" class
    if (this.field.hasClassName("show_password")) { 
      var showPasswordWrap = new Element("div", { className:'checkbox_wrap' });
      var showPasswordLabel = new Element("label", { 'for':"show_password_"+index }).update("Show password");
      this.showPasswordCheckbox = new Element("input", { type:"checkbox", id:"show_password_"+index });
      showPasswordWrap.insert(this.showPasswordCheckbox).insert(showPasswordLabel);
      
      var errorMessage = this.field.up().select(".inline_errors").first();
      if (errorMessage) {
        errorMessage.insert({ after: showPasswordWrap });
      }
      else {
        this.field.insert({ after: showPasswordWrap });
      }
      
      this.showPasswordCheckbox.on("click", this.toggleShowPassword.bind(this));
      this.showPasswordCheckbox.checked = false; //Firefox reload ;-)
    }
  },
  isShowingPassword: function() {
    if (this.showPasswordCheckbox) return this.showPasswordCheckbox.checked;
    else return false; //for exemple for Login form where we don't want to show the checkbox
  },
  toggleShowPassword: function(event) {
    var placeholderManager = this.field.retrieve("placeholderManager"); //exists only for browsers that do not support HTML5 placeholders
    if (placeholderManager) {
      if (this.field.value != this.field.readAttribute("placeholder")) {
        this.replacePasswordField(this.field, this.isShowingPassword());
        placeholderManager.passwordFieldDidUpdate(this.field);
      }
    }
    else {
      this.replacePasswordField(this.field, this.isShowingPassword());
    }
  },
  replacePasswordField: function(passwordField, textOrPassword) {
    // I can't simply modify the type attribute of the field (from "password" to "text"), because IE doesn't support this
    // cf: http://www.alistapart.com/articles/the-problem-with-passwords
    var newPasswordField = new Element("input", {
      id: passwordField.id,
      name: passwordField.name,
      value: passwordField.value,
      size: passwordField.size,
      placeholder: passwordField.readAttribute("placeholder"),
      required: passwordField.readAttribute("required"),
      className: passwordField.className,
      type: textOrPassword ? 'text' : 'password'
    }); 
    passwordField.purge(); //removes eventual observers and storage keys
    passwordField.replace(newPasswordField);
    this.field = newPasswordField;
    
    if(this.field.id == "user_password" && $("current_password_wrap")) MySublimeVideo.currentPasswordHandler.setupField(this.field);
    return newPasswordField;
  }
});

/*
PlaceholderManager manages pseudo-placeholders
*/
var PlaceholderManager = Class.create({
  initialize: function(field, check) {
    //
    // NOTE: 'field' can be textfield or textarea
    //
    this.field = field;
    this.showPasswordFieldManager = this.field.retrieve("showPasswordFieldManager"); //it means field.type == "password"
    
    // Just for Firefox, if I reload the page twice...
    if (this.field.value == this.field.readAttribute("placeholder")) {
      this.field.value = "";
      this.field.removeClassName("placeholder");
    }
    
    this.setupObservers();
    this.resetField(); //if it's a password field this will also take care to initially replace it with regular text fields (until it receives focus)
  },
  setupObservers: function() {
    this.field.store("placeholderManager", this);
    this.field.on("focus", this.clearField.bind(this));
    this.field.on("blur", this.resetField.bind(this));
  },
  clearField: function(event) {
    if (this.field.value == this.field.readAttribute("placeholder")) {
      this.field.value = "";
      this.field.removeClassName("placeholder");
      
      if (this.showPasswordFieldManager) {
        this.field = this.showPasswordFieldManager.replacePasswordField(this.field, this.showPasswordFieldManager.isShowingPassword());
        
        // refocus (the newly create field)
        if (Prototype.Browser.IE) {
          setTimeout(function(){
            this.field.focus();
          }.bind(this),0);
        }
        else {
          this.field.focus();
        }
        
        this.setupObservers(); //since we have a new field
      }
    }
    else if (this.field.value == "") { // This is a workaround for Opera...
      // =====================
      // = OPERA GRRRRRRRRRR =
      // =====================
      //... in fact Opera is currently the only browser supporting HTML5 form validty but NOT HTML5 placeholders!
      // The bugs happens when a field is not valid (from the HTML5 validity point of view) because of the way we 
      // reset the fields value in FormManager before submitting the form on browsers who do not support HTML5 placeholders...
      if (this.field.validity && !this.field.validity.valid) {
        if (this.showPasswordFieldManager) {
          this.resetField();
        }
        else {
          this.field.removeClassName("placeholder");
        }
      }
    }
  },
  resetField: function(event) { // Copy placeholder to value (if field is empty)
    if (this.field.value == "") {
      this.field.addClassName("placeholder");
      this.field.value = this.field.readAttribute("placeholder");
      
      if (this.showPasswordFieldManager) {
        this.field = this.showPasswordFieldManager.replacePasswordField(this.field, true);
        this.setupObservers(); //since we have a new field
      }
    }
  },
  passwordFieldDidUpdate: function(field) {
    this.field = field;
    this.setupObservers();
  }
});

/*
PopupHandler handles creation and behavior of SV pop-up (used for showing the embed code and the usage, asking the password..)
*/
var PopupHandler = Class.create({
  initialize: function(popup) {
    this.keyDownHandler = document.on("keydown", this.keyDown.bind(this));
  },
  startKeyboardObservers: function() {
    this.keyDownHandler.start();
  },
  stopKeyboardObservers: function() {
    this.keyDownHandler.stop();
  },
  open: function(itemId, idPrefix, url) {
    // Creates the base skeleton for the popup, and will render it's content via an ajax request:
    //
    // <div class='popup loading'>
    //   <div class='wrap'>
    //     <div class='content'></div>
    //   </div>
    //   <a class='close'><span>Close</span></a>
    // </div>
    
    this.close();
    
    var popupId = idPrefix + "_" + itemId;
    var popupLoading = new Element("div", {
      id:popupId,
      className:"popup loading"
    }).update("<div class='wrap'><div class='content "+idPrefix+"'></div></div>");
    var closeButton = new Element("a", {
      href:"",
      className:"close",
      onclick:"return MySublimeVideo.closePopup()"
    }).update("<span>Close</span>");
    popupLoading.insert({ bottom:closeButton });
    
    $('global').insert({ after:popupLoading });
    
    this.startKeyboardObservers();
    
    if(url != null) {
      //js.erb of the called method will take care of replacing the wrap div with the response content
      new Ajax.Request(url, { method:'get' });
    }
  },
  close: function() {
    this.stopKeyboardObservers();
    $$('.popup').each(function(el) {
      el.remove();
      // el.fade({ after :function(){ el.remove(); }});
    });
  },
  keyDown: function(event) {
    switch(event.keyCode) {
      case Event.KEY_ESC: //27
        this.close();
        break;
    }
  }
});


var SitesPoller = Class.create({
  initialize: function() {
    this.pollingDelay  = 3000;
    this.maxAttempts   = 20; // try for 3000 ms * 20 = 1 minute
    this.attempts      = 0;
    this.currentSiteId = null;
    this.poll          = null;
    this.checkForSiteInProgress();
  },
  checkForSiteInProgress: function() {
    var siteInProgress = $$('#sites .in_progress').first();
    if (siteInProgress) {
      this.currentSiteId = parseInt(siteInProgress.up('tr').id.replace("site_", ''), 10);
      this.startPolling();
    }
  },
  startPolling: function() {
    if (this.poll) this.stopPolling();
    this.poll = setInterval(this.remoteCheckForStateUpdate.bind(this), this.pollingDelay);
  },
  stopPolling: function() {
    clearInterval(this.poll);
    this.poll = null;
  },
  remoteCheckForStateUpdate: function() {
    if (this.attempts < this.maxAttempts) {
      this.attempts++;
      new Ajax.Request('/sites/'+this.currentSiteId+'/state', { method: 'get' });
    }
    else {
      this.stopPolling();
    }
    // this will simply reply with a HEAD OK if the state is still pending, or it'll will call the updateSite() method below if the state changed to active
  },
  updateSite: function(siteId) {
    // Stop polling
    this.stopPolling();
    
    // Remove the "cdn updating in progress..." test
    var inProgressWrap = $$("#site_"+siteId+" .in_progress").first();
    if (inProgressWrap) inProgressWrap.remove();
    
    // Check if a restart polling is needed
    this.checkForSiteInProgress();
  }
});


// var CurrentPasswordHandler = Class.create({
//   initialize: function() {
//     this.emailField          = $("user_email");
//     this.passwordField       = $("user_password");
//     this.currentPasswordWrap = $("current_password_wrap");
//     
//     [this.emailField, this.passwordField].each(function(field){
//       this.setupField(field);
//     }.bind(this));
//   },
//   setupField: function(field) {
//     field.on("focus", function(e){
//       this.showCurrentPassword();
//     }.bind(this));
//   },
//   showCurrentPassword: function() {
//     this.currentPasswordWrap.show();
//   }
// });


function supportsHtml5InputOfType(inputType) { // e.g. "email"
  var i = document.createElement("input");
  i.setAttribute("type", inputType);
  return i.type !== "text";
}

function supportsHtml5InputAttribute(attribute) { // e.g "placeholder"
  var i = document.createElement('input');
  return attribute in i;
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