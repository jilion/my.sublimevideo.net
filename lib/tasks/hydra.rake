# set up a new hydra testing task named 'hydra:spec' run with "rake hydra:spec"
# Hydra::TestTask.new('hydra:spec') do |t|
#   # you may or may not need this, depending on how you require
#   # spec_helper in your test files:
#   # require 'spec/spec_helper'
#   require File.join(File.dirname(__FILE__), '..', '..', 'spec', 'spec_helper')
#   # add all files in the spec directory that end with "_spec.rb"
#   # t.add_files '../spec/**/*_spec.rb'
#   t.add_files File.join(File.dirname(__FILE__), '..', '..', 'spec', '**', '*_spec.rb')
# end