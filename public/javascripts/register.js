document.observe("dom:loaded", function() {
  
  buildShowPassword();
  
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
  var newPasswordField = new Element("input", {
    id: passwordField.id,
    name: passwordField.name,
    value: passwordField.value,
    size: passwordField.size,
    placeholder: passwordField.placeholder,
    required: passwordField.required,
    className: passwordField.className,
    type: this.checked ? 'text' : 'password'
  }); 
  
  passwordField.up().replaceChild(newPasswordField,passwordField);
}