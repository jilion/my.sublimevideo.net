Delayed::Worker.destroy_failed_jobs = false
# Delayed::Worker.sleep_delay = 60
# Delayed::Worker.max_attempts = 3
# Delayed::Worker.max_run_time = 5.minutes

# Worker can't load model instances (http://github.com/collectiveidea/delayed_job/issues/labels/blocker#issue/65)
# => As a short term workaround, require your models in an initializer.
# require 'site'