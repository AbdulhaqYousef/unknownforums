class SitePage < ApplicationRecord
  DEFAULTS = {
    "rules" => {
      title: "Forum Rules",
      body_html: <<~HTML
        <p style="margin-bottom:14px;">By using UnknownForums, you agree to follow these rules. Violations may result in warnings, post removal, or bans at moderator discretion.</p>

        <div style="background:#1e1e1e; border:1px solid #333; padding:12px 16px; margin-bottom:16px;">
          <h3 style="color:#f0c060; font-size:13px; margin:0 0 8px;">&#9888; General Rules</h3>
          <ol style="margin:0 0 0 20px; color:#b0b0b0;">
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">Be respectful.</strong> Treat all members with respect. No personal attacks, harassment, bullying, or hate speech.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No spam.</strong> Do not post spam, advertisements, or self-promotional content without permission.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No NSFW content.</strong> Do not post pornographic, excessively violent, or otherwise inappropriate content.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No illegal content.</strong> Do not post anything that violates local, national, or international law.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">English only.</strong> Posts should be in English to allow moderation and participation from all members.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No alt accounts.</strong> One account per person. Ban evasion will result in permanent removal.</li>
          </ol>
        </div>

        <div style="background:#1e1e1e; border:1px solid #333; padding:12px 16px; margin-bottom:16px;">
          <h3 style="color:#7aabde; font-size:13px; margin:0 0 8px;">&#128172; Posting Rules</h3>
          <ol style="margin:0 0 0 20px; color:#b0b0b0;">
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">Stay on topic.</strong> Keep posts relevant to the subforum and thread topic.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">Use descriptive titles.</strong> Thread titles should clearly describe the content or question.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No double posting.</strong> Edit your post instead of posting multiple times in a row.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No necroposting.</strong> Do not bump threads older than 30 days unless you have something meaningful to add.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No low-effort posts.</strong> Posts like "lol", "+1", or "bump" with no substance will be removed.</li>
          </ol>
        </div>

        <div style="background:#1e1e1e; border:1px solid #333; padding:12px 16px; margin-bottom:16px;">
          <h3 style="color:#60c060; font-size:13px; margin:0 0 8px;">&#128190; File Upload Rules</h3>
          <ol style="margin:0 0 0 20px; color:#b0b0b0;">
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No malware.</strong> Uploading malicious files will result in an immediate permanent ban.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No pirated content.</strong> Do not upload copyrighted software, media, or materials you do not own or have rights to share.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">Describe your uploads.</strong> Include a description of what the file is and what it does.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">Unverified files.</strong> Files that have not been approved by staff carry a warning. Download at your own risk.</li>
          </ol>
        </div>

        <div style="background:#1e1e1e; border:1px solid #333; padding:12px 16px; margin-bottom:16px;">
          <h3 style="color:#c08080; font-size:13px; margin:0 0 8px;">&#9878; Reputation Rules</h3>
          <ol style="margin:0 0 0 20px; color:#b0b0b0;">
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">No rep manipulation.</strong> Do not ask for, trade, or exchange reputation points.</li>
            <li style="margin-bottom:6px;"><strong style="color:#cfcfcf;">Honest feedback.</strong> Give reputation based on the quality and helpfulness of posts.</li>
          </ol>
        </div>

        <div style="background:#2a1a1a; border:1px solid #4a2a2a; padding:12px 16px;">
          <h3 style="color:#f08080; font-size:13px; margin:0 0 8px;">&#128683; Enforcement</h3>
          <p style="margin:0; color:#b0b0b0;">Violations are handled at staff discretion. Consequences include: <strong style="color:#cfcfcf;">verbal warning → post removal → temporary ban → permanent ban.</strong> Severe violations (malware, doxxing, threats) may result in an immediate permanent ban without warning.</p>
        </div>
      HTML
    },
    "terms" => {
      title: "Terms of Service",
      body_html: <<~HTML
        <p style="color:#888; font-size:11px; margin-bottom:14px;">Last updated: #{Date.today.strftime("%B %d, %Y")}</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">1. Acceptance of Terms</h3>
        <p>By accessing or using UnknownForums ("the Forum"), you agree to be bound by these Terms of Service. If you do not agree, do not use the Forum.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">2. Account Registration</h3>
        <p>You must provide accurate information when creating an account. You are responsible for maintaining the security of your account credentials. You must be at least 13 years old to use this service.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">3. User Conduct</h3>
        <p>You agree not to post illegal, harmful, threatening, abusive, harassing, defamatory, or otherwise objectionable content; impersonate others; upload malicious software; spam or disrupt the Forum; scrape data without permission; or circumvent bans.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">4. Content Ownership</h3>
        <p>You retain ownership of content you post. By posting content, you grant the Forum a non-exclusive, royalty-free license to display, distribute, and store your content as part of the service.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">5. File Uploads</h3>
        <p>Files uploaded to the Forum are subject to review. Unapproved files carry a warning and may be removed at any time. You are solely responsible for the files you upload.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">6. Moderation</h3>
        <p>Forum moderators and administrators may edit, move, or delete any content, and may ban or suspend accounts at their discretion. Decisions by moderators are final.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">7. Disclaimer of Warranties</h3>
        <p>The Forum is provided "as is" without warranties of any kind, express or implied.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">8. Limitation of Liability</h3>
        <p>To the fullest extent permitted by law, the Forum and its operators shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the service.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">9. Termination</h3>
        <p>We reserve the right to terminate or suspend your account at any time, for any reason, without notice.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">10. Changes to Terms</h3>
        <p>We may update these Terms at any time. Continued use of the Forum after changes constitutes acceptance of the new Terms.</p>
        <h3 style="color:#cfcfcf; font-size:13px; margin:16px 0 6px;">11. Contact</h3>
        <p>Questions about these Terms? Contact us at <a href="mailto:admin@unknownforums.fun">admin@unknownforums.fun</a>.</p>
      HTML
    }
  }.freeze

  belongs_to :updated_by, class_name: "User", optional: true

  validates :slug, presence: true, uniqueness: true, inclusion: { in: DEFAULTS.keys }
  validates :title, presence: true
  validates :body_html, presence: true

  def self.fetch!(slug)
    find_or_create_by!(slug: slug) do |page|
      defaults = DEFAULTS.fetch(slug)
      page.title = defaults.fetch(:title)
      page.body_html = defaults.fetch(:body_html)
    end
  end
end
