class VirusTotalScanJob < ApplicationJob
  queue_as :default

  def perform(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return unless attachment
    VirusTotalScanner.scan(attachment)
  end
end
