document.observe("dom:loaded", function() {
  
  buildShowPassword();
  
  if (!supportsHtml5InputAttribute("placeholder")) {
    $$("input[placeholder]").each(function(input){
      new PlaceholderManager(input);
    });
  }
});


var PlaceholderManager = Class.create({
  initialize: function(field) {
    this.field = field;
    this.isPasswordField = field.type == "password";
    
    // Just for Firefox, if I reload the page twice...
    if (this.field.value == this.field.readAttribute("placeholder")) {
      this.field.value = "";
      this.field.removeClassName("placeholder");
    }
    
    // Need to replace password fields with regular text fields until they receive focus
    if (this.isPasswordField) {
      this.field = replacePasswordField(field, true);
    }
    
    this.setupObservers();
    this.resetField();
  },
  setupObservers: function() {
    this.field.observe("focus", this.clearField.bind(this));
    this.field.observe("blur", this.resetField.bind(this));
  },
  clearField: function() {
    if (this.field.value == this.field.readAttribute("placeholder")) {
      this.field.value = "";
      this.field.removeClassName("placeholder");
      
      if (this.isPasswordField) {
        this.field = replacePasswordField(this.field, false);
        this.field.focus(); // refocus (the newly create field)
        this.setupObservers(); //since we have a new field
      }
    }
  },
  resetField: function() { // Copy placeholder to value (if field is empty)
    if (this.field.value == "") {
      console.log(this.field)
      this.field.addClassName("placeholder");
      this.field.value = this.field.readAttribute("placeholder");
      
      if (this.isPasswordField) {
        this.field = replacePasswordField(this.field, true);
        this.setupObservers(); //since we have a new field
      }
    }
  }
  
});


function buildShowPassword() {
  
  $$('input[type=password]').each(function(el, index){
    var showPasswordWrap = new Element("div", { className:'show_password' });
    var showPasswordInput = new Element("input", { type:"checkbox", id:"show_password_"+index });
    var showPasswordLabel = new Element("label", { 'for':"show_password_"+index }).update("Show password");
    showPasswordWrap.insert(showPasswordInput).insert(showPasswordLabel);
    el.insert({ after: showPasswordWrap });
    
    showPasswordInput.observe("click", toggleShowPassword);
    showPasswordInput.checked = false; //Firefox reload ;-)
  });
  
}

function toggleShowPassword(event) {
  // I can't simply modify the type attribute of the field (from "password" to "text"), because IE doesn't support this
  // cf: http://www.alistapart.com/articles/the-problem-with-passwords
  var passwordField = event.element().up(1).select("input[type!=checkbox]").first();
  replacePasswordField(passwordField, this.checked);
}

function replacePasswordField(passwordField, textOrPassword) {
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
  passwordField.up().replaceChild(newPasswordField,passwordField);
  return newPasswordField;
}


function supportsHtml5InputOfType(inputType) { // e.g. "email"
  var i = document.createElement("input");
  i.setAttribute("type", inputType);
  return i.type !== "text";
}

function supportsHtml5InputAttribute(attribute) { // e.g "placeholder"
  var i = document.createElement('input');
  return attribute in i;
}


