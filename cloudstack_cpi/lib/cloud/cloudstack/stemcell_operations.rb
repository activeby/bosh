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
        not_implemented(:create_stemcell)
      end

      ##
      # Deletes a stemcell
      #
      # @param [String] stemcell stemcell id that was once returned by {#create_stemcell}
      # @return nil
      def delete_stemcell(stemcell_id)
        not_implemented(:delete_stemcell)
      end
    end
  end
end
