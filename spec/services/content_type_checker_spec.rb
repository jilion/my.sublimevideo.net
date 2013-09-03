require 'fast_spec_helper'

require 'services/content_type_checker'

describe ContentTypeChecker do
  let(:checker) { described_class.new('http://foo.com/bar.mp4') }

  describe '#found?' do

    context 'asset is not found' do
      before { checker.stub(:head).and_return({ 'found' => false }) }

      it 'return false' do
        checker.should_not be_found
      end
    end

    context 'asset is found' do
      before { checker.stub(:head).and_return({ 'found' => true, 'content-type' => 'video/mp4' }) }

      it 'return true' do
        checker.should be_found
      end
    end
  end

  describe '#valid_content_type?' do
    context 'asset has valid content type' do
      before { checker.stub(:head).and_return({ 'found' => true, 'content-type' => 'video/mp4' }) }

      it 'returns true' do
        checker.should be_valid_content_type
      end
    end

    context 'asset has invalid content type' do
      before { checker.stub(:head).and_return({ 'found' => true, 'content-type' => 'video/mov' }) }

      it 'returns false' do
        checker.should_not be_valid_content_type
      end
    end
  end

end
