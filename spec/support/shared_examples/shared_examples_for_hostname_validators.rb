# This example assumes a `@site` with an attribute `field` already exists.
#
shared_examples 'valid hostnames' do |field, value|
  it 'has no errors' do
    described_class.new(attributes: field).validate_each(@site, field, value)

    expect(@site.errors[field]).to be_empty
  end
end
#
shared_examples 'invalid hostnames' do |field, value|
  it 'has an error' do
    described_class.new(attributes: field).validate_each(@site, field, value)

    expect(@site.errors[field].size).to eq(1)
  end
end
