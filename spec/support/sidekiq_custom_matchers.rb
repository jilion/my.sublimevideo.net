RSpec::Matchers.define :delay do |message, *opts|
  match_for_should do |object|
    object.stub(:delay) { delayed_job_mock }
    object.should_receive(:delay).with(*opts) { delayed_job_mock }
    delayed_job_mock.should_receive(message).with(*@args)
  end

  match_for_should_not do |object|
    object.stub(:delay) { delayed_job_mock }
    object.should_not_receive(:delay).with(*opts) { delayed_job_mock }
  end

  def with(*args)
    @args = *args
    self
  end

  def delayed_job_mock
    @delayed_job_mock ||= mock("Delay Method").as_null_object
  end
end
