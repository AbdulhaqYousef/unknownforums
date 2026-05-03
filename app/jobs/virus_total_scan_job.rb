class VirusTotalScanJob < ApplicationJob
  queue_as :default

  def perform(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return unless attachment

    result = VirusTotalScanner.scan(attachment)
    VirusTotalScanJob.set(wait: 2.minutes).perform_later(attachment.id) if result == :pending
  end
end
