class UserAgent
  module OperatingSystems

    REGEXP_AND_NAMES = [
      # Windows
      [%r{Windows\s*NT\s*6\.1}i,     "Windows 7"],
      [%r{Windows\s*NT\s*6\.?0?}i,   "Windows Vista"],
      [%r{Windows\s*NT\s*5\.2}i,     "Windows Server 2003"],
      [%r{Windows\s*NT\s*5\.1}i,     "Windows XP"],
      [%r{Windows\s*NT\s*5\.01}i,    "Windows 2000, Service Pack 1 (SP1)"],
      [%r{Windows\s*NT\s*5\.[3-9]}i, "Windows NT"],
      [%r{Windows\s*NT\s*4\.?0?}i,   "Windows NT 4.0"],
      [%r{Win\s*NT\s*4\.?0?}i,       "Windows NT 4.0"],
      [%r{Win\s*NT}i,                "Windows NT"],
      [%r{Windows\s*NT\s*5\.?0?}i,   "Windows 2000"],
      [%r{Win 9x\s*.*}i,             "Windows Me"], # Windows Millennium Edition
      [%r{Win\s*(9[58])}i,           "Windows"], # Windows 95 & 98
      [%r{Windows\s*(9[58])}i,       "Windows"], # Windows 95 & 98
      [%r{Windows\s*(.*)}i,          "Windows"], # All other Windows

      # UNIX-based
      [%r{FreeBSD[-/\s]?(.*)}i, "FreeBSD"],
      [%r{OpenBSD[-/\s]?(.*)}i, "OpenBSD"],
      [%r{NetBSD[-/\s]?(.*)}i,  "NetBSD"],
      [%r{SunOS[-/\s]?(.*)}i,   "SunOS"],
      [%r{Linux\s*(.*)}i,       "Linux"],

      # Other
      [%r{BeOS[-/\s]?(.*)}i, "BeOS"],
      [%r{OS/2[-/\s]?(.*)}i, "OS/2"],
      [%r{AmigaOS}i,         "AmigaOS"],

      # TV
      [%r{WebTV[-/\s]?(.*)}i, "WebTV"],

      # Mobiles, Smartphones, tablets
      [%r{Bada[-/\s]?(.*)}i,      "Bada"],
      [%r{BlackBerry}i,           "BlackBerryOS"],
      [%r{SymbianOS[-/\s]?(.*)}i, "SymbianOS"],

      # Game devices
      [%r{Nintendo\s+DS[-/\s]?(.*)}i, "Nintendo DS"],
      [%r{PlayStation\s*3}i,          "PlayStation 3"],
      [%r{PlayStation\s*Portable}i,   "PlayStation Portable"]
    ]

  end
end
