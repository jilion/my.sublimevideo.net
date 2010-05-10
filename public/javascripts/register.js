document.observe("dom:loaded", function() {
  
  buildShowPassword();
  
});

function buildShowPassword() {
  var showPasswordEl = new Element("input", { type:"checkbox", id:"show_password" });
  var showPasswordLabel = new Element("label", { 'for':"show_password" }).update("Show password");
  $('user_password').insert({ after: showPasswordLabel }).insert({ after: showPasswordEl });
  
  showPasswordEl.observe("click", toggleShowPassword);
  showPasswordEl.checked = false; //Firefox reload ;-)
}

function toggleShowPassword() {
  // I can't simply modify the type attribute of the field (from "password" to "text"), because IE doesn't support this
  // cf: http://www.alistapart.com/articles/the-problem-with-passwords
  
  var passwordField = $("user_password");
  var newPasswordField = new Element("input", {
    id: passwordField.id,
    name: passwordField.name,
    value: passwordField.value,
    size: passwordField.size,
    className: passwordField.className,
    type: this.checked ? 'text' : 'password'
  }); 
  
  passwordField.parentNode.replaceChild(newPasswordField,passwordField);
}
