ActiveSupport.on_load(:active_storage_blob) do
  module ActiveStorage
    class Blob
      FOLDER_MAP = {
        /\Aimage\//                        => "images",
        /\Avideo\//                        => "videos",
        "application/zip"                  => "archives",
        "application/x-zip-compressed"     => "archives",
        "application/pdf"                  => "documents",
        "text/plain"                       => "documents"
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
          folder = folder_for(content_type.to_s)
          token  = self.class.generate_unique_secure_token(length: 12)

          raw  = self[:filename].to_s.presence || "file"
          ext  = File.extname(raw)
          base = File.basename(raw, ext)
                     .gsub(/[^\w\-]/, "_")
                     .gsub(/_+/, "_")
                     .slice(0, 60)

          name = "#{base}[unknownforums.fun]_#{token}#{ext}"
          self[:key] = "#{folder}/#{name}"
        end
        self[:key]
      end
    end
  end
end
