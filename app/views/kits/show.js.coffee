$("#kit_settings_form<%= params[:addon] ? '_' + params[:addon] : '' %>").html "<%= j(render 'video_code') %>"
