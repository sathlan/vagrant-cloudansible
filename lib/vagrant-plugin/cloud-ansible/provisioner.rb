require 'thread'

module VagrantPlugin
  module CloudAnsible
    class Provisioner < ::Vagrant.plugin('2', :provisioner)
      @@lock ||= Mutex.new

      VERSION = '0.0.1'

      def provision
      # we don't want several machines writing the host file at the
      # same time.
        @inventory_path == config.inventory_path ||
          File.join(@machine.env.root_path.to_s, 'hosts')
        
        @@lock.synchronize do
          create_or_update_hosts_file
        end
      end

      protected
      def conf_to_hash
        # make it work with virtualenv
        hosts = {'[localhost]' => ['127.0.0.1 ansible_connection=local ansible_python_interpreter=python']}
        current_section = ''
        if File.exists?(config.inventory_path)
          IO.readlines(config.inventory_path).each do |line|
            case line
            when /^\s*(\[[^\]]+\])/
              hosts[$1] = hosts[$1].is_a?(Array) ? hosts[$1] : []
              current_section = "#{$1}"
            else
              hosts[current_section] << line unless current_section == '[localhost]'
            end
          end
        end
        hosts
      end

      def create_or_update_hosts_file
        hosts = conf_to_hash
        ssh = @machine.ssh_info
        a_group = config.ansible_group || 'no_group'
        hosts["[#{a_group}]"] = [] if hosts["[#{a_group}]"].nil?
        replaced = false
        ansible_host_option = ''
        ansible_host_option = config.ansible_options unless
          config.ansible_options == ::Vagrant::Plugin::V2::Config::UNSET_VALUE
        current_public_ip = ssh[:host]
        fqdn = machine.config.vm.hostname
        current_entry = "#{fqdn} ansible_ssh_host=#{current_public_ip} ansible_ssh_user=#{ssh[:username]} #{ansible_host_option}"
        hosts["[#{a_group}]"].each_with_index do |entry, idx|
          if entry =~ /^#{fqdn}/
            hosts["[#{a_group}]"][idx] = current_entry
            replaced = true
          end
        end
        if replaced == false
          hosts["[#{a_group}]"] << current_entry
        end

        File.open(config.inventory_path, 'w') do |conf|
          hosts.each do |group, entries|
            conf.puts group
            entries.each do |entry|
              conf.puts entry
            end
          end
        end
      end
    end
  end
end

