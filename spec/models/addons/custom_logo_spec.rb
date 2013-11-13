require 'fast_spec_helper'
require File.expand_path('app/models/addons/custom_logo')

describe Addons::CustomLogo do

  describe 'Validations' do
    it { expect(described_class.new(double(original_filename: 'test.png', content_type: 'image/png'))).to be_valid }
    it { expect(described_class.new(double(original_filename: 'test.jpg', content_type: 'image/jpg'))).not_to be_valid }
  end

end
