module Bosh
  module CloudStackCloud
    module StemcellOperations
      ##
      # Creates a stemcell
      #
      # @param [String] image_path path to an opaque blob containing the stemcell image
      # @param [Hash] cloud_properties properties required for creating this template
      #               specific to a CPI
      # @return [String] opaque id later used by {#create_vm} and {#delete_stemcell}
      def create_stemcell(image_path, cloud_properties)
        with_thread_name("create_stemcell(#{image_path}...)") do
          Dir.mktmpdir do |tmp_dir|
            image_path = extract_and_convert_image(image_path, tmp_dir)

            symlink_name = rand(36**8).to_s(36) + ".qcow2"

            link = cloud_properties[:web_root] + "/#{symlink_name}"
            File.symlink(image_path, link)

            image_url = "http://" + cloud_properties[:public_dns_name] + "/#{symlink_name}"

            template_id = create_cloudstack_template image_url, cloud_properties
            return template_id.to_s
          end
        end
      end

      ##
      # Deletes a stemcell
      #
      # @param [String] stemcell stemcell id that was once returned by {#create_stemcell}
      # @return nil
      def delete_stemcell(stemcell_id)
        with_thread_name("delete_stemcell(#{stemcell_id})") do
          @logger.info("Deleting `#{stemcell_id}' stemcell")
          image = @cloudstack.images.get(stemcell_id)
          image.destroy
        end
      end

      private

      def extract_image(from_tarball, to_tmp_dir)
        # TODO: move this code into the class that can be reused among different CPI implementations
        # it this method will host the template somewhere (CloudStack requirement) then it is ok not to share it
        tar_output = `tar -C #{to_tmp_dir} -xzf #{from_tarball} 2>&1`
        if $?.exitstatus != 0
          cloud_error("Failed to unpack stemcell root image" \
                    "tar exit status #{$?.exitstatus}: #{tar_output}")
        end

        image_path = File.join(to_tmp_dir, "root.img")
        unless File.exists?(image_path)
          cloud_error("Root image is missing from stemcell archive")
        end
        image_path
      end

      def extract_and_convert_image(from_tarball, to_tmp_dir)
        # TODO: move this code into the class that can be reused among different CPI implementations
        # it this method will host the template somewhere (CloudStack requirement) then it is ok not to share it
        tar_output = `tar -C #{to_tmp_dir} -xzf #{from_tarball} 2>&1`
        if $?.exitstatus != 0
          cloud_error("Failed to unpack stemcell root image" \
                    "tar exit status #{$?.exitstatus}: #{tar_output}")
        end

        image_path = File.join(to_tmp_dir, "root.img")
        unless File.exists?(image_path)
          cloud_error("Root image is missing from stemcell archive")
        end

        qemu_img_output = `qemu-img convert -f raw -O qcow2 #{image_path} #{to_tmp_dir}/root.qcow2 2>&1`
        if $?.exitstatus != 0
          cloud_error("Failed to convert stemcell root image" \
            "qemu-img exit status #{$?.exitstatus}: #{qemu_img_output}")
        end

        image_path = File.join(to_tmp_dir, "root.qcow2")
        unless File.exists?(image_path)
          cloud_error("Root qcow2 image is missing from stemcell archive")
        end
        image_path
      end

      def create_cloudstack_template(image_url, cloud_properties)

        # WARNING: image_path might not work. registerTemplate method requires URL of the template...

        #@cloudstack.request {
        #  'command' = > 'registerTemplate',
        #
        #  # Required parameters from http://download.cloud.com/releases/2.2.0/api_2.2.8/global_admin/registerTemplate.html
        #  'displaytext' => '',   # the display text of the template. This is usually used for display purposes.
        #  'format' => '',        # the format for the template. Possible values include QCOW2, RAW, and VHD.
        #  'hypervisor' => '',    # the target hypervisor for the template
        #  'name' => '',          # the name of the template
        #  'ostypeid' => '',      # the ID of the OS Type that best represents the OS of this template.
        #  'url' => '',           # the URL of where the template is hosted. Possible URL include http:// and https://
        #  'zoneid' => '',        # the ID of the zone the template is to be hosted on
        #}

        template_params = {
            :command => "registerTemplate",
            :displaytext => "BOSH-#{generate_unique_name}",
            :format => cloud_properties[:template_format],
            :hypervisor => cloud_properties[:hypervisor],
            :name => "BOSH",
            :ostypeid => 1, # hardcoded - bad
            :url => image_url,
            :zoneid => 4, # hardcoded - bad
        }

        template = @cloudstack.request(template_params)

        id = template["registertemplateresponse"]["template"][0]["id"]

        image = @cloudstack.images.get(id)
        image.wait_for {
          |img| puts img.status; img.status == 'ok'
        }

        @logger.info("Creating new image...")

      end

      def generate_unique_name
        UUIDTools::UUID.random_create.to_s
      end

    end
  end
end

