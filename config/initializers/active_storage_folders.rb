ActiveSupport.on_load(:active_storage_blob) do
  module ActiveStorage
    class Blob
      FOLDER_MAP = {
        /\Aimage\//                        => "images",
        /\Avideo\//                        => "videos",
        "application/zip"                  => "archives",
        "application/x-zip-compressed"     => "archives",
        "application/pdf"                  => "documents",
        "text/plain"                       => "documents",
      }.freeze

      private

      def folder_for(ct)
        FOLDER_MAP.each do |pattern, folder|
          return folder if pattern === ct
        end
        "other"
      end

      public

      def key
        unless self[:key]
          token  = self.class.generate_unique_secure_token(length: MINIMUM_TOKEN_LENGTH)
          folder = folder_for(content_type.to_s)
          self[:key] = "#{folder}/#{token}"
        end
        self[:key]
      end
    end
  end
end
