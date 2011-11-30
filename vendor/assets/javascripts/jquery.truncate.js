(function($){
  $.fn.truncate = function(options) {

    var defaults = {
      length: 300,
      moreText: "...",
      lessText: " <",
      moreAni: "",
      lessAni: ""
    };

    var options = $.extend(defaults, options);

    return this.each(function() {
      obj = $(this);
      var body = obj.html();

      if(body.length > options.length) {
        var str1 = body.substring(0, options.length);
        var str2 = body.substring(options.length, body.length - 1);
        obj.html(str1 + '<span class="truncate_more">' + str2 + '</span>');
        obj.find('.truncate_more').css("display", "none");
        // insert more link
        obj.append(
          '<span class="clearboth">' +
            '<a href="#" class="truncate_more_link">' + options.moreText + '</a>' +
          '</span>'
        );

        // set onclick event for more/less link
        var moreLink = $('.truncate_more_link', obj);
        var moreContent = $('.truncate_more', obj);
        moreLink.click(function() {
          if(moreLink.text() == options.moreText) {
            moreContent.show(options.moreAni);
            moreLink.text(options.lessText);
          } else {
            moreContent.hide(options.lessAni);
            moreLink.text(options.moreText);
          }
          return false;
        });
      }
    }) // end if
  }
})(jQuery);