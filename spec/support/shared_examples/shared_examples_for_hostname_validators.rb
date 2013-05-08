# This example assumes a `@site` with an attribute `field` already exists.
#
shared_examples 'valid hostnames' do |field, value|
  it 'has no errors' do
    described_class.new(attributes: field).validate_each(@site, field, value)

    @site.errors[field].should be_empty
  end
end
#
shared_examples 'invalid hostnames' do |field, value|
  it 'has an error' do
    described_class.new(attributes: field).validate_each(@site, field, value)

    @site.errors[field].should have(1).item
  end
end
