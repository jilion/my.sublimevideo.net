class UserAgent
  module LinuxDistributions

    REGEXP_AND_NAMES = [
      [/debian[-\/\s]?(.*)/i,   "Debian"],
      [/kubuntu[-\/\s]?(.*)/i,  "Kubuntu"],
      [/ubuntu[-\/\s]?(.*)/i,   "Ubuntu"],
      [/fedora[-\/\s]?(.*)/i,   "Fedora"],
      [/suse[-\/\s]?(.*)/i,     "SUSE"],
      [/gentoo[-\/\s]?(.*)/i,   "Gentoo"],
      [/mandriva[-\/\s]?(.*)/i, "Mandriva"]
    ]

  end
end
