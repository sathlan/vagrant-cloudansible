require 'vagrant'

module VagrantPlugin
  module CloudAnsible
    class Plugin < Vagrant.plugin('2')
      name 'CloudAnsible'

      description <<-DESC
      Provide support for hosts file creation for ansible with instance with unknown ip.
      DESC
      
      config(:cloudansible, :provisioner) do
        require File.expand_path('../config', __FILE__)
        Config
      end

      provisioner(:cloudansible) do
        require File.expand_path('../provisioner', __FILE__)
        Provisioner
      end
    end
  end
end
