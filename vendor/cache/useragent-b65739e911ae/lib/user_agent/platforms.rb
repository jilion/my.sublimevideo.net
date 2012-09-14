class UserAgent
  module Platforms

    REGEXP_AND_NAMES = [
      # TV
      [/webtv/i, "WebTV"],

      # Windows
      [/windows phone/i, "Windows Phone"],
      [/win(dows)?/i, "Windows"],

      # Mobiles, Smartphones, tablets
      [/android/i,       "Android"],
      [/samsung/i,       "Samsung"],
      [/nokia/i,         "Nokia"],
      [/blackberry/i,    "BlackBerry"],

      # Other
      [/beos/i,  "BeOS"],
      [/os\/2/i, "OS/2"],
      [/webos/i, "webOS"],

      # iOS
      [/iphone\s*.*\s*simulator/i, "iPhone Simulator"],
      [/ipad/i,                    "iPad"],
      [/ipod/i,                    "iPod"],
      [/iphone/i,                  "iPhone"],

      # UNIX-based
      [/freebsd/i,     "FreeBSD"],
      [/openbsd/i,     "OpenBSD"],
      [/netbsd/i,      "NetBSD"],
      [/linux/i,       "Linux"],
      [/sunos/i,       "SunOS"],
      [/opensolaris/i, "OpenSolaris"],
      [/aix/i,         "AIX"],
      [/x11/i,         "X11"],

      # Game devices
      [/nintendo\s+wii/i,         "Nintendo Wii"],
      [/nintendo\s+ds/i,          "Nintendo DS"],
      [/playstation\s*portable/i, "PlayStation Portable"],

      # Mac
      [/mac/i, "Macintosh"]
    ]

  end
end
