var MySublimeVideo = MySublimeVideo || {};

document.observe("dom:loaded", function() {

  // ====================
  // = Live Search form =
  // ====================
  if ($('search_input')) {
    new Form.Element.Observer('search_input', 1, function(element, value) {
      form   = element.form;
      method = form.readAttribute('method') || 'post';
      url    = form.readAttribute('action');
      params = form.serialize();
      new Ajax.Request(url, {
        method: method,
        parameters: params,
        onComplete: function(request) {
          $('table_spinner').hide();
          if (history && history.pushState) {
            history.replaceState(null, document.title, url + "?" + params);
          }
        },
        onLoading:  function(request) { $('table_spinner').show(); }
      });
    });
  }
  
  if (history && history.pushState) {
    Event.observe(window, 'popstate', function(event) {
      if (event.state.isHistory) {
        MySublimeVideo.showTableSpinner();
        new Ajax.Request(location.href, {
          method: 'get'
        });
      }
    });
  }

  MySublimeVideo.remoteSortLink = function(element) {
    MySublimeVideo.makeRemoteLinkSticky(element);
    MySublimeVideo.showTableSpinner();
    if (history && history.pushState) {
      history.pushState({isHistory:true}, document.title, element.href);
    };
  };

});

// ===========
// = Classes =
// ===========

// var SpinnerForElement = Class.create({
//   initialize: function(elementId, update) {
//     this.elementId     = elementId;
//     this.spinner       = $(this.elementId+'_spinner') ? $(this.elementId+'_spinner') : null;
//     this.updateElement = update;
//     this.setup();
//   },
//   setup: function() {
//     var element = $(this.elementId);
//     element.on('ajax:before', function(){
//       if(this.spinner == null) {
//         this.spinner = new Element('img', { src: '/images/embed/admin/spinner.gif' });
//         element.insert({ after: this.spinner });
//       }
//       if(this.updateElement) element.update(this.spinner);
//       this.spinner.show();
//     }.bind(this));
//
//     element.on('ajax:success', function(){
//       if(this.spinner) this.spinner.hide();
//     }.bind(this));
//   }
// });

