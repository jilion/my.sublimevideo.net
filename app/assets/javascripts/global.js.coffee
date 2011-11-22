# C IS FOR COOKIE
window.Cookie =
  get: (name) ->
    name = escape(name) + '='
    if document.cookie.indexOf(name) >= 0
      cookies = document.cookie.split(/\s*;\s*/)
      for cookie in cookies
        if cookie.indexOf(name) == 0 then return unescape cookie.substring(name.length, cookie.length)

    null

  set: (name, value, options) ->
    newcookie = [escape(name) + "=" + escape(value)]
    if options
      if options.expires then newcookie.push "expires=" + options.expires.toGMTString()
      if options.path    then newcookie.push "path=#{options.path}"
      if options.domain  then newcookie.push "domain=#{options.domain}"
      if options.secure  then newcookie.push "secure"
    document.cookie = newcookie.join '; '
