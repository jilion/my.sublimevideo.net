# SublimeVideo's "Service" app
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/repos/50ee7c0013d6373a44010c21/feed)

- https://my.sublimevideo.net (https://my.sublimevideo-staging.net)
- https://admin.sublimevideo.net (https://admin.sublimevideo-staging.net)

## Setup

1. Update the Jilion Setup (including useful aliases): `$ jsau && mysv`;
2. Update brew: `$ brew update`;
3. [Optional but recommended] Install oh-my-zsh and switch to ZSH by default: `$ curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh && chsh -s $(which zsh)`. Start / restart zsh (open a new terminal tab). [Additional help](https://github.com/robbyrussell/oh-my-zsh); [Why ZSH is better than Bash](https://gist.github.com/wisq/1507733);
4. [Optional but recommended] Install rbenv: `$ brew install rbenv` and add:
  ```bash
  # To use Homebrew's directories rather than ~/.rbenv add to your profile:
  export RBENV_ROOT=/usr/local/var/rbenv

  # To enable shims and autocompletion add to your profile:
  if which rbenv > /dev/null; then eval "$(rbenv init - --no-rehash)"; fi
  ```
  to your `~/.zshenv`/`~/.bash_profile`;
5. [Optional but recommended] Install ruby-build: `$ brew install ruby-build`
6. Install latest Ruby 1.9.3.
  - If you're using rbenv: `$ rbenv install 1.9.3-p392` (verify it's the latest 1.9.3 version by running `$ ruby-build --definitions` before). Set the system's default ruby version with `rbenv global 1.9.3-p392`
7. Install PostgreSQL: `$ brew install postgresql` and follow the installation instructions;
8. Install MongoDB: `$ brew install mongodb` and follow the installation instructions;
9. Install Redis: `$ brew install redis` and follow the installation instructions;
10. Install bundler: `$ gem install bundler`
11. Install the app's gems: `$ bundle install`. If there's any issue at this step, the solution is usually to re-install Ruby, but you should ask a developer before;
12. [If you're using rbenv] Installs shims for all Ruby binaries known to `rbenv`: `$ rbenv rehash`;
13. Run the populate task: `$ rake 'db:populate:all[<yourfirstname>]'` (e.g. 'remy');
14. Link your app to Pow: `$ be powder link && cd ~/.pow && mv my.sublimevideo.net my.sublimevideo && mysv`;
15. Also links `admin` subdomains to the same app: `$ cp ~/.pow/my.sublimevideo ~/.pow/admin.sublimevideo`;
16. Open http://my.sublimevideo.dev in your favorite browser (Chrome recommended!) and log with your account: `yourfirstname@jilion.com`/`123456` (same for the admin).

## Notes

This app is using the following private Gemfury gems:

* [SublimeVideo layout gem](https://github.com/jilion/sublime_video_layout).
* [SublimeVideo private API gem](https://github.com/jilion/sublime_video_private_api).

## Generate the JS docs

```bash
gi codo && codo ./app/assets/javascripts
```

------------
Copyright (c) 2010 - 2013 Jilion(r) - SublimeVideo and Jilion are registered trademarks.
