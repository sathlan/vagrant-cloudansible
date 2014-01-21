require 'thread'

module VagrantPlugins
  module CloudAnsible
    class Provisioner < ::Vagrant.plugin('2', :provisioner)
      @@lock ||= Mutex.new

      VERSION = '0.0.1'

      def provision
      # we don't want several machines writing the host file at the
      # same time.
        @inventory_path == config.inventory_path ||
          File.join(@machine.env.root_path.to_s, 'hosts')
        
        @lock.synchronize do
          create_or_update_hosts_file
        end
      end

      protected
      def conf_to_hash
        # make it work with virtualenv
        hosts = {'[localhost]' => ['127.0.0.1 ansible_connection=local ansible_python_interpreter=python']}
        current_section = ''

        IO.readlines(@inventory_path).each do |line|
          case line
          when /^\s*(\[[^\]]+\])/ then
            hosts[$1] = hosts[$1].is_a?(Array) ? hosts[$1] : []
            current_section = "#{$1}"
          else hosts[current_section] << line
          end
        end
        hosts
      end

      def create_or_update_hosts_file
        hosts = conf_to_hash(env)
        ssh = @machine.ssh_info
        a_group = config.ansible_group
        hosts["[#{a_group}]"] = [] if hosts["[#{a_group}]"].nil?
        replaced = false
        ansible_host_option = ''
        ansible_host_option = config.ansible_options unless
          config.ansible_options == ::Vagrant::Plugin::V2::Config::UNSET_VALUE
        current_public_ip = ssh[:host]

        hosts["[#{ansible_group}]"].each_with_index do |entry, idx|
          if entry =~ /ansible_ssh_host=([\d.]+)/
            if $1 == current_public_ip
              env[:ui].info("Updating entry about #{current_public_ip}")
              hosts["[#{ansible_group}]"][idx] = "#{machine.name} ansible_ssh_host=#{current_public_ip} ansible_ssh_user=#{ssh[:username]} #{ansible_host_option}"
              replaced = true
            end
          end
        end
        if replaced == false
          env[:ui].info("Creating entry about #{machine.name} with ip #{current_public_ip} and options #{ansible_host_option}")
          hosts["[#{ansible_group}]"] << "#{machine.name} ansible_ssh_host=#{current_public_ip} ansible_ssh_user=#{ssh[:username]} #{ansible_host_option}"
        end

        File.open(@inventory_path, 'w') do |conf|
          hosts.each do |group, entries|
            conf.puts group
            entries.each do |entry|
              conf.puts entry
            end
          end
        end
        env[:ui].info("Ansible configuration Done")
      end
    end
  end
end

