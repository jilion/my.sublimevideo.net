RSpec::Matchers.define :delay do |message, *opts|
  match_for_should do |object|
    setup(object, message)

    allow(object).to receive(:delay) { @delayed_job_mock }
    expect(object).to receive(:delay).with(*opts).and_return(@delayed_job_mock)

    if @args.nil?
      expect(@delayed_job_mock).to receive(message).with(any_args)
    else
      @args.each do |args|
        # puts "Array[args].flatten : #{(Array[args].flatten)}"
        expect(@delayed_job_mock).to receive(message).with(*Array[args].flatten)
      end
    end
  end

  match_for_should_not do |object|
    setup(object, message)

    allow(object).to receive(:delay) { @delayed_job_mock }
    expect(object).not_to receive(:delay).with(*opts).and_return(@delayed_job_mock)
  end

  description do
    if @args.many?
      "delays #{object}.#{message} several times with #{@args.join(', ')}"
    else
      "delays #{object}.#{message} with #{@args}"
    end
  end

  def with(*args)
    @args = [args]
    # puts "@args : #{@args}"
    self
  end

  def several_times_with(*arrays_of_args)
    @args = arrays_of_args
    self
  end

  def setup(object, message)
    @delayed_job_mock = double("Delay Method for #{object}.#{message}").as_null_object
  end
end
