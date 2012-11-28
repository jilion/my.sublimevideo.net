# SublimeVideo's "Service" app

- https://my.sublimevideo.net (https://my.sublimevideo-staging.net)
- https://api.sublimevideo.net
- https://admin.sublimevideo.net (https://admin.sublimevideo-staging.net)

## Setup

1. Update the Jilion Setup (including useful aliases): `$ jsau && mysv`;
2. Update brew: `$ brew update`;
3. [Optional but recommended] Install oh-my-zsh  and switch to ZSH by default: `$ curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh && chsh -s $(which zsh)`. Start / restart zsh (open a new terminal tab). [Additional help](https://github.com/robbyrussell/oh-my-zsh);
4. [Optional but recommended] Install rbenv: `$ brew install rbenv` and add `eval "$(rbenv init -)"` to your `~/.zshenv`/`~/.bash_profile`;
5. [Optional but recommended] Install ruby-build: `$ brew install ruby-build`
6. Install latest Ruby 1.9.3.
	- If you're using rbenv: `$ rbenv install 1.9.3-p286` (verify it's the latest 1.9.3 version by running `$ ruby-build --definitions` before).
	- If you're using RVM: `$ rvm install 1.9.3`;
7. Install PostgreSQL: `$ brew install postgresql` (and follow the installation instructions);
8. Install MongoDB: `$ brew install mongodb` (and follow the installation instructions);
9. Install Redis: `$ brew install redis` (and follow the installation instructions);
10. Install the app's gems: `$ bundle install`. If there's any issue at this step, the solution is usually to re-install Ruby, but you should ask a developer before;
11. [If you're using rbenv] Installs shims for all Ruby binaries known to `rbenv`: `$ rbenv rehash`;
12. Run the populate task: `$ dbrp user=<index between 0 and 5>` (0 is Mehdi, 5 is Andrea) or just `dbrp` if you need to warm the room;
13. Link your app to Pow: `powder link && cd ~/.pow && mv my.sublimevideo.net my.sublimevideo && mysv`;
14. Also links `admin` and `api` subdomains to the same app: `$ cp ~/.pow/my.sublimevideo ~/.pow/api.sublimevideo && cp ~/.pow/my.sublimevideo ~/.pow/admin.sublimevideo`;
15. Open http://my.sublimevideo.dev in your favorite browser (Chrome recommended!) and log with your account: `yourfirstname@jilion.com`/`123456` (same for the admin).

## Notes

* This app is using the [SublimeVideo layout gem](https://github.com/jilion/sublime_video_layout) (released as a private gem on Gemfury).

## Generate the JS docs

`gi codo && codo ./app/assets/javascripts`

------------
Copyright (c) 2010 - 2012 Jilion(r) - SublimeVideo and Jilion are registered trademarks.
