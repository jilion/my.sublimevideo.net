# Be sure to restart your server when you modify this file.

MySublimeVideo::Application.config.session_store :cookie_store, :key => '_my.sublimevideo.net_session', :domain => Rails.env.test? ? nil : ".sublimevideo.net"

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# MySublimeVideo::Application.config.session_store :active_record_store
