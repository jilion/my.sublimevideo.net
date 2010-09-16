var MySublimeVideo = MySublimeVideo || {};

document.observe("dom:loaded", function() {
  MySublimeVideo.initStarringForm();
});


// ====================
// = Onclick handlers =
// ====================

MySublimeVideo.initStarringForm = function() {
  $$(".with_spinner").each(function(element){
    new SpinnerForElement(element, true);
  });
}

// ===========
// = Classes =
// ===========

var SpinnerForElement = Class.create({
  initialize: function(elementId, update) {
    this.elementId     = elementId;
    this.spinner       = $(this.elementId+'_spinner') ? $(this.elementId+'_spinner') : null;
    this.updateElement = update;
    this.setup();
  },
  setup: function() {
    var element = $(this.elementId);
    element.on('ajax:before', function(){
      if(this.spinner == null) {
        this.spinner = new Element('img', { src: '/images/embed/admin/spinner.gif' })
        element.insert({ after: this.spinner });
      }
      if(this.updateElement) element.update(this.spinner);
      this.spinner.show();
    }.bind(this));
    
    element.on('ajax:success', function(){
      if(this.spinner) this.spinner.hide();
    }.bind(this));
  }
});