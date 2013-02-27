require 'fast_spec_helper'

require 'core_ext/hash/join_keys'

describe Hash do

  it "concats sub hash keys" do
    { 'x' => { 'y' => { 'z' => 1, 'z2' => 2 } } }.join_keys.should eq('x.y.z' => 1, 'x.y.z2' => 2)
  end

  it "concats symbolized keys" do
    { x: { y: 1 }, z: 2 }.join_keys.should eq('x.y' => 1, 'z' => 2)
  end
end
