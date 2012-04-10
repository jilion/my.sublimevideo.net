jQuery("#tweet_<%= @tweet.id %> .favorite").html "<%= j(render 'favorite_td', :tweet => @tweet) %>"
jQuery('#table_spinner').hide()
