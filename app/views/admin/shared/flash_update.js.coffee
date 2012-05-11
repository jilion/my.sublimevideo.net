if (flash = jQuery('#flash')).exists()
  flash.html "<%= render('layouts/flash', flash: flash) %>"
else
  jQuery('#content').prepend "<%= render('layouts/flash', flash: flash) %>"
  flash = jQuery('#flash')

new MySublimeVideo.UI.Notice(element: flash.find('.notice')).setupDelayedHiding(duration: 0.7, delay: 5)