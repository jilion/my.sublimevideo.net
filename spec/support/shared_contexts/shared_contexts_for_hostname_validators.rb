shared_context 'setup for hostname validators' do |validator|
  before :all do
    SiteTester = Struct.new(:hostname, :dev_hostnames, :extra_hostnames) do
      include ActiveModel::Validations

      validates validator, validator => true
    end
  end
  after :all do
    Object.send(:remove_const, :SiteTester)
  end

  before { @site = SiteTester.new }
end
