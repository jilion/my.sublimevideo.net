$('#preview_custom_logo').html $('<img />').attr(src: '<%= j cdn_url(@custom_logo.path) %>?<%= Time.now.to_i %>')
