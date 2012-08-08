# UserAgent [![Build Status](https://secure.travis-ci.org/jilion/useragent.png?branch=master)](http://travis-ci.org/jilion/useragent)

UserAgent is a Ruby library that parses and compares HTTP User Agents.

## Detected platforms

UserAgent can detect the following platforms in any given User Agent string:

- Windows;
- Macintosh;
- iPhone Simulator, iPad, iPod, iPhone;
- FreeBSD, OpenBSD, NetBSD, SunOS, OpenSolaris, AIX, X11, Linux;
- BeOS, OS/2;
- Nintendo Wii, Nintendo DS;
- PlayStation 3, PlayStation Portable;
- WebTV;
- SunOS;
- webOS;
- Android, Samsung, Nokia, BlackBerry.

## Detected operating systems

UserAgent can detect the following operating systems (and versions, except for the Windows) in any given User Agent string:

- Windows 7, Vista, Server 2003, XP, 2000/Service Pack 1 (SP1), 2000, NT 4.0, NT, 2000, Me;
- PPC Mac OS X, Intel Mac OS X;
- FreeBSD, OpenBSD, NetBSD, SunOS, Linux;
- BeOS, OS/2, AmigaOS;
- WebTV;
- Android, Bada, BlackBerryOS, SymbianOS;
- Nintendo DS;
- PlayStation 3, PlayStation Portable.

## Detected linux distributions

UserAgent can detect the following linux distributions (and versions) in any given User Agent string:
- Debian, Kubuntu, Ubuntu;
- Red Hat;
- Fedora;
- SUSE;
- Gentoo;
- Mandriva.

## Detected languages

UserAgent can detect languages/countries based on the [ISO-639-2](http://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt) list (for language codes) and the [ISO-3166-1](http://www.iso.org/iso/list-en1-semic-3.txt) list (for country codes) in any given User Agent string. The detected formats are "en", "en-US" and "en_US".


## Examples

### Retrieve User Agent information from a User Agent string

```ruby
# Safari 4.0.4 on iPad 3.2
user_agent = UserAgent.parse("Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B367 Safari/531.21.10")

user_agent.gecko?         # => false
user_agent.webkit?        # => true
user_agent.browser        # => "Safari"
user_agent.version        # => "4.0.4"
user_agent.webkit_version # => "531.21.10"
user_agent.build          # => "531.21.10"
user_agent.platform       # => "iPad"
user_agent.os             # => "iOS 3.2"
user_agent.language       # => "en-US"
user_agent.security       # => :strong
user_agent.mobile?        # => true

# Firefox 3.1 on Ubuntu 8.04
user_agent = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.2) Gecko/2008092313 Ubuntu/8.04 (hardy) Firefox/3.1")

user_agent.gecko?             # => true
user_agent.webkit?            # => false
user_agent.browser            # => "Firefox"
user_agent.version            # => "3.1"
user_agent.gecko_version      # => "2008092313"
user_agent.platform           # => "Linux"
user_agent.os                 # => "Linux i686"
user_agent.linux_distribution # => "Ubuntu 8.04"
user_agent.language           # => "en-US"
user_agent.security           # => :strong
user_agent.mobile?            # => false

# Opera Mini 5.1.22784
user_agent = UserAgent.parse("Opera/9.80 (Series 60; Opera Mini/5.1.22784/22.394; U; en) Presto/2.5.25 Version/10.54")

user_agent.gecko?             # => false
user_agent.webkit?            # => false
user_agent.browser            # => "Opera Mini"
user_agent.version            # => "5.1.22784"
user_agent.platform           # => nil
user_agent.os                 # => nil
user_agent.linux_distribution # => nil
user_agent.language           # => "en"
user_agent.security           # => :strong
user_agent.mobile?            # => true
```

### Comparisons of browsers

```ruby
Browser = Struct.new(:browser, :version)
SupportedBrowsers = [
  Browser.new("Safari", "3.1.1"),
  Browser.new("Firefox", "2.0.0.14"),
  Browser.new("Internet Explorer", "7.0")
]

user_agent = UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13")

SupportedBrowsers.detect { |browser| user_agent >= browser } # => #<struct Browser browser="Firefox", version="2.0.0.14">

user_agent > SupportedBrowsers[0] # => false
user_agent > SupportedBrowsers[1] # => true
user_agent > SupportedBrowsers[2] # => false
```

Copyright (c) 2011 Joshua Peek, released under the MIT license
