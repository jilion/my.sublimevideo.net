$('#spinner').data().spinner.stop()
$('#preview_custom_logo').css(opacity: 1).html $('<img />').attr
  src: '<%= j cdn_url(@logo_path) %>?<%= Time.now.to_i %>'
  width: '<%= @logo_width / 2 %>'
  height: '<%= @logo_height / 2 %>'
$('#kit_setting-logo-image_url').val('<%= j cdn_url(@logo_path) %>').change()

<% if (@logo_width * @logo_height) > (400*120) %>
message  = "We advise you to reduce the size of your logo to a maximum of 400x120 (or 120x400). "
message += "Please remember that your logo will be displayed at half this size on all non-Retina® displays."
$('#notices').html "<div class='notice'>#{message}</div>"
<% end %>
