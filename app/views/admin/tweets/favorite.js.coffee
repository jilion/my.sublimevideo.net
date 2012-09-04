$("#tweet_<%= @tweet.id %> .favorite").html "<%= j(render 'favorite_td', :tweet => @tweet) %>"
$('#table_spinner').hide()
