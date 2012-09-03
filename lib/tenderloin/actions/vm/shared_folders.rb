module Tenderloin
  module Actions
    module VM
      class SharedFolders < Base
        def shared_folders
          shared_folders = @runner.invoke_callback(:collect_shared_folders)

          # Basic filtering of shared folders. Basically only verifies that
          # the result is an array of 3 elements. In the future this should
          # also verify that the host path exists, the name is valid,
          # and that the guest path is valid.
          shared_folders.collect do |folder|
            if folder.is_a?(Array) && folder.length == 3
              folder
            else
              nil
            end
          end.compact
        end

        def before_boot

        end

        def after_boot
          logger.info "Creating shared folders metadata..."

          shared_folders.each do |name, hostpath, guestpath|
            @runner.fusion_vm.share_folder(name, hostpath)
            @runner.fusion_vm.enable_shared_folders
          end

          logger.info "Linking shared folders..."

          Tenderloin::SSH.execute(@runner.fusion_vm.ip) do |ssh|
            shared_folders.each do |name, hostpath, guestpath|
              logger.info "-- #{name}: #{guestpath}"
              ssh.exec!("sudo ln -s /mnt/hgfs/#{name} #{guestpath}")
              ssh.exec!("sudo chown #{Tenderloin.config.ssh.username} #{guestpath}")
            end
          end
        end

      end
    end
  end
end