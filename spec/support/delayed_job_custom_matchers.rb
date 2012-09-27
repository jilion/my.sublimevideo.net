RSpec::Matchers.define :delay do |*args|
  match_for_should do |block|
    @delayed_job_handlers_and_expected_new_jobs = delayed_job_handlers_and_expected_new_jobs(*args, 1)
    execute_and_track_and_compare(@delayed_job_handlers_and_expected_new_jobs) { block.call }
  end
  match_for_should_not do |block|
    @delayed_job_handlers_and_expected_new_jobs = delayed_job_handlers_and_expected_new_jobs(*args, 0)
    execute_and_track_and_compare(@delayed_job_handlers_and_expected_new_jobs) { block.call }
  end
  failure_message_for_should do |x|
    @delayed_job_handlers_and_expected_new_jobs.inject('') do |text, (delayed_job_handler, expected_new_delayed_jobs_count)|
      if actual_new_delayed_jobs_count(delayed_job_handler) != expected_new_delayed_jobs_count
        text += if delayed_job_handler == :all
          "expected #{expected_new_delayed_jobs_count} new delayed jobs, but got " +
          "#{actual_new_delayed_jobs_count(delayed_job_handler)} new delayed jobs!"
        else
          "expected '#{delayed_job_handler}' to be delayed #{expected_new_delayed_jobs_count} " +
          "time#{'s' if expected_new_delayed_jobs_count > 1} but was delayed " +
          "#{actual_new_delayed_jobs_count(delayed_job_handler)} time#{'s' if actual_new_delayed_jobs_count(delayed_job_handler) > 1}!"
        end
      else
        text
      end
    end + "\n\nAll currently delayed jobs:\n#{Delayed::Job.pluck(:handler).inspect}"
  end
  failure_message_for_should_not do |x|
    @delayed_job_handlers_and_expected_new_jobs.inject('') do |text, (delayed_job_handler, expected_new_delayed_jobs_count)|
      if actual_new_delayed_jobs_count(delayed_job_handler) != expected_new_delayed_jobs_count
        text += if delayed_job_handler == :all
          "expected no new delayed jobs, but got " +
          "#{actual_new_delayed_jobs_count(delayed_job_handler)} new delayed jobs!"
        else
          "expected '#{delayed_job_handler}' not to be delayed but was delayed " +
          "#{actual_new_delayed_jobs_count(delayed_job_handler)} time#{'s' if actual_new_delayed_jobs_count(delayed_job_handler) > 1}!"
        end
      else
        text
      end + "\n\nAll currently delayed jobs:\n#{Delayed::Job.pluck(:handler).inspect}"
    end
  end

  def execute_and_track_and_compare(delayed_job_handlers_and_expected_new_delayed_jobs_count, &block)
    # puts delayed_job_handlers_and_expected_new_delayed_jobs_count.inspect
    result = true
    delayed_job_handlers_and_expected_new_delayed_jobs_count.each do |delayed_job_handler, expected_new_jobs|
      actual_new_jobs = track_delayed_jobs_count(delayed_job_handler, &block)
      # puts "actual new jobs for #{delayed_job_handler}: #{actual_new_jobs}"
      # puts "expected new jobs for #{delayed_job_handler}: #{expected_new_jobs}"
      result &= (actual_new_jobs == expected_new_jobs)
    end

    result
  end

  def track_delayed_jobs_count(delayed_job_handler)
    @delayed_jobs_before_call ||= {}
    @delayed_jobs_after_call ||= {}
    @delayed_jobs_before_call[delayed_job_handler] ||= delayed_jobs_count(delayed_job_handler)
    yield
    @delayed_jobs_after_call[delayed_job_handler] ||= delayed_jobs_count(delayed_job_handler)

    @delayed_jobs_after_call[delayed_job_handler] - @delayed_jobs_before_call[delayed_job_handler]
  end

  def delayed_jobs_count(delayed_job_handler)
    delayed_jobs(delayed_job_handler).count
  end

  def delayed_jobs(delayed_job_handler)
    if delayed_job_handler == :all
      Delayed::Job
    else
      Delayed::Job.where{ handler =~ delayed_job_handler }
    end
  end

  def delayed_job_handlers_and_expected_new_jobs(*args)
    @delayed_job_handlers_and_expected_new_jobs = []
    default_expectation = args.pop

    @delayed_job_handlers_and_expected_new_jobs[default_expectation] ||= case args[0]
    when Array
      args.shift
      Hash.new(1)
    when Hash
      args.shift
    when nil
      { all: default_expectation }
    else
      hash = {}
      while arg = args.shift and
        if arg.is_a?(String)
          hash[arg] = default_expectation
        else
          hash[last_handler] = arg
        end
        last_handler = arg
      end
      hash
    end
  end

  def actual_new_delayed_jobs_count(delayed_job_handler)
    @actual_new_delayed_jobs_count ||= {}
    @actual_new_delayed_jobs_count[delayed_job_handler] ||= @delayed_jobs_after_call[delayed_job_handler] - @delayed_jobs_before_call[delayed_job_handler]
  end
end
