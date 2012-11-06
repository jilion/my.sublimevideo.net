require 'fast_spec_helper'
require File.expand_path('app/models/addons/custom_logo')

describe Addons::CustomLogo do

  describe 'Validations' do
    it { described_class.new(stub(original_filename: 'test.png', content_type: 'image/png')).should be_valid }
    it { described_class.new(stub(original_filename: 'test.jpg', content_type: 'image/jpg')).should_not be_valid }
  end

end
