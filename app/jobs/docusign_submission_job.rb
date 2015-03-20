class DocusignSubmissionJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    begin
      client = DocusignRest::Client.new
      @envelope_response = client.create_envelope_from_template(
        status: 'sent',
        email: {
          subject: 'Please DocuSign this document: 1099 Contractor Agreement_For Hosts.pdf',
          body: "Hello #{user.first_name},\n\nHi! Thanks for interviewing with us. Please read and sign this contract. Once we receive confirmation that you have signed the contract, we will schedule your training.\n\nThanks,\nTeam HostWise"
        },
        template_id: ENV['DOCUSIGN_TEMPLATE_ID'],
        event_notification: {
          url: "#{root_url}/notifications/docusign?id=#{user.id}",
          envelope_events: [
            include_documents: true,
            envelope_event_status_code: 'completed'
          ]
        },
        signers: [
          {
            name: user.name,
            email: user.email,
            role_name: 'Independent Contractor'
          }
        ]
      )

      user.contractor_profile.docusign_id = @envelope_response['envelopeId']
      user.contractor_profile.docusign_completed = false
      user.contractor_profile.save
    rescue Exception => e
      Rails.logger.error "Docusign submission error: #{e}"
    end
  end
end
