var MySublimeVideo = MySublimeVideo || {};

document.observe("dom:loaded", function() {

  S2.Extensions.webkitCSSTransitions = true;

  // =======================================================
  // = Password fields and placeholders and forms managers =
  // =======================================================
  
  $$('input[type=password]').each(function(input, index){
    new PasswordFieldManager(input, index);
  });
  
  if (!supportsHtml5InputAttribute("placeholder")) {
    $$("input[placeholder]").each(function(input){
      new PlaceholderManager(input);
    });
  }
  
  $$("form").each(function(form){
    new FormManager(form);
  });

  // =================
  // = Flash notices =
  // =================
  
  $$('#flash .notice').each(function(element){
    MySublimeVideo.hideFlashNoticeDelayed(element);
  });
  
  // ============
  // = Add site =
  // ============
  if ($("new_site")) {
    MySublimeVideo.addSiteHandler = new AddSiteHandler();
  }

});

// ====================
// = Global functions =
// ====================

MySublimeVideo.flashNotice = function(message) {
  var flashDiv = $("flash");
  if (flashDiv) flashDiv.remove();
  
  var noticeDiv = new Element("div", { className:"notice" }).update(message);
  flashDiv = new Element("div", { id:"flash" }).insert(noticeDiv);
  $("content").insert({ top: flashDiv });

  MySublimeVideo.hideFlashNoticeDelayed(noticeDiv);

};

MySublimeVideo.hideFlashNoticeDelayed = function(flashEl) {
  setTimeout(function(){
    flashEl.morph('top:-35px', { duration: 0.7 });
  }, 4000);
};

MySublimeVideo.closePopup = function() {
  $$('.popup').each(function(el) {
    el.fade({ after :function(){ el.remove(); }});
  });
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

var FormManager = Class.create({
  initialize: function(form) {
    
    form.on("submit", function(event){
      // Reset pseudo-placeholders values (for browsers who don't support HTML5 placeholders)
      if (!supportsHtml5InputAttribute("placeholder")) {
        form.select("input.placeholder").each(function(input){
          input.value = "";
        });
      }
    });
    
    form.select("input[type=submit]").each(function(submitButton){
      submitButton.on("click", function() { //when HTML5 form validitation doesn't pass, the submit event is not fired
        // HTML5 Input validity
        form.select("input").each(function(input){
          if (input.validity) {
            if (input.validity.valid) input.removeClassName("errors");
            else input.addClassName("errors");
          }
        });
      });
    });
    
  }
});


var PasswordFieldManager = Class.create({
  initialize: function(field, index) {
    this.field = field;
    this.field.store("passwordFieldManager", this); // so that the placeholderManager can eventually pick this up
    
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
    // ddd("Replacing password field")
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
    return newPasswordField;
  }
});


var PlaceholderManager = Class.create({
  initialize: function(field, check) {
    this.field = field;
    this.passwordFieldManager = this.field.retrieve("passwordFieldManager"); //it means field.type == "password"
    
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
      
      if (this.passwordFieldManager) {
        this.field = this.passwordFieldManager.replacePasswordField(this.field, this.passwordFieldManager.isShowingPassword());
        this.field.focus(); // refocus (the newly create field)
        this.setupObservers(); //since we have a new field
      }
    }
  },
  resetField: function(event) { // Copy placeholder to value (if field is empty)
    if (this.field.value == "") {
      this.field.addClassName("placeholder");
      this.field.value = this.field.readAttribute("placeholder");
      
      if (this.passwordFieldManager) {
        this.field = this.passwordFieldManager.replacePasswordField(this.field, true);
        this.setupObservers(); //since we have a new field
      }
    }
  },
  passwordFieldDidUpdate: function(field) {
    this.field = field;
    this.setupObservers();
  }
});


var VideoEmbedCodeUpdater = Class.create({
  initialize: function(textarea, originalWidth, originalHeight) {
    this.embedVideoTextarea = textarea; // the textarea containing the video embed code
    this.originalWidth      = originalWidth; // used when the user clear a field
    this.originalHeight     = originalHeight; // used when the user clear a field
    this.ratio              = this.originalWidth / this.originalHeight; // used to automatically keep the aspect ratio
    
    this.setupObservers();
  },
  setupObservers: function() {
    var el = null;
    ['width', 'height'].each(function(size, index){
      el = $('video_'+size);
      el.on("keyup", this.updateSizeHandler.bind(this));
      el.on("blur", this.cleanupSizeFieldsHandler.bind(this));
    }.bind(this));
  },
  updateSizeHandler: function(event) {
    this.updateSizesFromInput(event.element());
  },
  cleanupSizeFieldsHandler: function(event) {
    var el = event.element();
    if (el.value == '') this.resetSizeFields();
    else this.cleanupUnallowedChars(el);
  },
  updateSizesFromInput: function(input) {
    var newValue = input.value.match(/^\d*$/);
    if (newValue) { // sizes must be integers to be able to update the enbed code
      var modifiedSizeElement = input;
      var oppositeSizeElement = this.oppositeSizeElement(modifiedSizeElement);
      
      // Update the opposite size input value of the updated one
      this.updateInputValue(oppositeSizeElement.readAttribute('name'), modifiedSizeElement.value);
      
      // Update both sizes in the embed code
      this.updateSizeInEmbed(modifiedSizeElement);
      this.updateSizeInEmbed(oppositeSizeElement);
    }
  },
  resetSizeFields: function() {
    $('video_width').value  = this.originalWidth;
    $('video_height').value = this.originalHeight;
  },
  cleanupUnallowedChars: function(sizeInputField) {
    var newValue = sizeInputField.value.gsub(/[^\d]/, '');
    if (newValue != sizeInputField.value) {
      sizeInputField.value = newValue;
      this.updateSizesFromInput(sizeInputField);
    }
  },
  oppositeSizeElement: function(sizeElement) {
    var size = 'width';
    if(sizeElement.readAttribute('name') == 'width') size = 'height';
    return $('video_'+size);
  },
  updateInputValue: function(sizeName, oppositeValue) {
    oppositeValue = parseInt(oppositeValue, 10);
    $('video_'+sizeName).value = isNaN(oppositeValue) ? '' : (sizeName == 'height' ? oppositeValue/this.ratio : oppositeValue*this.ratio).round();
  },
  updateSizeInEmbed: function(input) {
    var sizeName = input.readAttribute('name');
    this.embedVideoTextarea.value = this.embedVideoTextarea.value.replace(new RegExp(sizeName+"='\\d*'"), sizeName+"='"+input.value+"'");
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


function ddd(){console.log.apply(console, arguments);}