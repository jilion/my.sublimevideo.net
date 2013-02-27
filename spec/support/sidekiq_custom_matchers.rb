RSpec::Matchers.define :delay do |message, *opts|
  match_for_should do |object|
    setup(object, message)

    object.stub(:delay) { @delayed_job_mock }
    object.should_receive(:delay).with(*opts) { @delayed_job_mock }

    if @args.nil?
      @delayed_job_mock.should_receive(message).with(any_args)
    else
      @args.each do |args|
        args = *args if @several
        @delayed_job_mock.should_receive(message).with(*args)
      end
    end
  end

  match_for_should_not do |object|
    setup(object, message)

    object.stub(:delay) { @delayed_job_mock }
    object.should_not_receive(:delay).with(*opts) { @delayed_job_mock }
  end

  description do
    if @args.many?
      "delays #{object}.#{message} several times with #{@args.join(', ')}"
    else
      "delays #{object}.#{message} with #{@args}"
    end
  end

  def with(*args)
    @args = args
    self
  end

  def several_times_with(*arrays_of_args)
    @several = true
    with(*arrays_of_args)
  end

  def setup(object, message)
    @delayed_job_mock = mock("Delay Method for #{object}.#{message}")
  end
end
