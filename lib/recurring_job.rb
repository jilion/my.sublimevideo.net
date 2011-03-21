module RecurringJob

  logs_tasks = [
    '%Log::Voxcast%fetch_download_and_create_new_logs%',
    '%Log::Amazon::S3::Player%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Loaders%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Licenses%fetch_and_create_new_logs%'
  ]

  NAMES = if MySublimeVideo::Release.public?
    [
      '%User::LimitAlert%send_limit_alerts%',
      '%User::CreditCard%send_credit_card_expiration%',
      '%User::Trial%supervise_users%'
    ] + logs_tasks
  else
    logs_tasks
  end

  class << self

    def launch_all
      Log.delay_fetch_and_create_new_logs
      if MySublimeVideo::Release.public?
        User::CreditCard.delay_send_credit_card_expiration
        User::Trial.delay_supervise_users
        User::LimitAlert.delay_send_limit_alerts
      end
    end

    def supervise
      # check if there is no too much delayed jobs
      max_jobs_allowed = 50
      if too_much_jobs?(max_jobs_allowed)
        Notify.send("WARNING!!! There is more than #{max_jobs_allowed} delayed jobs, please investigate quickly!")
      end
      # check if recurring jobs are all delayed twice
      unless all_delayed?
        sleep 20
        unless all_delayed?
          Notify.send("WARNING!!! All recurring jobs are not delayed, please investigate quickly!")
        end
      end
    end

    def test_exception
      raise "THIS A DELAYED JOB EXCEPTION TEST"
    end

  private

    def all_delayed?
      NAMES.all? { |name| Delayed::Job.already_delayed?(name) }
    end

    def too_much_jobs?(max)
      Delayed::Job.count > max
    end

  end
end