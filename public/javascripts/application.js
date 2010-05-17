var MySublimeVideo = MySublimeVideo || {};

document.observe("dom:loaded", function() {

  // =============================================
  // = Password fields and placeholders managers =
  // =============================================
  
  $$('input[type=password]').each(function(input, index){
    new PasswordFieldManager(input, index);
  });
  
  if (!supportsHtml5InputAttribute("placeholder")) {
    $$("input[placeholder]").each(function(input){
      new PlaceholderManager(input);
    });
  }
  
  $$("form").each(function(form){
    
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
  });

  // =================
  // = Flash notices =
  // =================
  
  $$('#flash .notice').each(function(element){
    setTimeout(function(){
      element.morph('top:-35px', { duration: 0.7 });
    },6000);
  });
  
  // ============
  // = Add site =
  // ============
  if ($("new_site")) {
    MySublimeVideo.addSiteHandler = new AddSiteHandler();
  }

});

var AddSiteHandler = Class.create({
  initialize: function() {
    this.setup();
  },
  setup: function() { //call this after ajax call to re-setup this handler
    this.element = $("new_site");
    
    this.beforeAjaxHandler = this.element.on('ajax:before', function(){
      this.element.down('.spinner').show();
      //only listen to this once (we can stop the listener now) because this.element will soon be replaced
      this.beforeAjaxHandler.stop();
    }.bind(this));
    
    this.completeAjaxHandler = this.element.on('ajax:complete', function(){
      // Note1: at this point, this.element has already been replaced
      // Note2: there's no need to hide the spinner, 'cause the whole form has been reset/replaced
      
      // Reload this handler:
      this.setup();
      
    }.bind(this));
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
  initialize: function(field) {
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