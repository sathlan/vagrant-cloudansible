require 'spec_helper'

describe VagrantPlugin::CloudAnsible do
  it 'should have a version number' do
    VagrantPlugin::CloudAnsible::VERSION.should_not be_nil
  end

  it 'should do something useful' do
    @plugin = VagrantPlugin::CloudAnsible::Plugin.new
    @config = VagrantPlugin::CloudAnsible::Plugin.data
    puts "#{@config}"
  end
end
