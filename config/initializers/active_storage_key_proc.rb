Rails.application.config.active_storage.key_proc = ->(blob) {
  folder = case blob.content_type
           when /\Aimage\//                                          then "images"
           when /\Avideo\//                                          then "videos"
           when "application/zip", "application/x-zip-compressed"   then "archives"
           when "application/pdf"                                    then "documents"
           when "text/plain"                                         then "documents"
           else                                                           "other"
           end

  "#{folder}/#{blob.key}"
}
