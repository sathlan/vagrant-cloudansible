module VagrantPlugin
  module CloudAnsible
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :hosts
      attr_accessor :ansible_group
      attr_accessor :ansible_options
      attr_accessor :inventory_path
      attr_accessor :sudo
      attr_accessor :user
    end

    def initialize
      @inventory_path  = UNSET_VALUE
      @ansible_group   = UNSET_VALUE
      @ansible_options = UNSET_VALUE
      @sudo            = UNSET_VALUE
      @user            = UNSET_VALUE
    end

    def finalize!
      @inventory_path  = nil if @inventory_path  == UNSET_VALUE
      @ansible_group   = nil if @ansible_group   == UNSET_VALUE
      @ansible_options = nil if @ansible_options == UNSET_VALUE
      @sudo            = nil if @sudo            == UNSET_VALUE
      @user            = nil if @user            == UNSET_VALUE
    end

    def validate(machine)
      # TODO(chem)
      errors = _detected_errors
      { "ansible provisioner" => errors }
    end

  end
end
