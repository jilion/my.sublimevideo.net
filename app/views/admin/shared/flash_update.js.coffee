if (flash = $('#flash')).exists()
  flash.html "<%= render('layouts/flash', flash: flash) %>"
else
  $('#content').prepend "<%= render('layouts/flash', flash: flash) %>"
  flash = $('#flash')

new MySublimeVideo.UI.Notice(element: flash.find('.notice')).setupDelayedHiding(duration: 0.7, delay: 5)
