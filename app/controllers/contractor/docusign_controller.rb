class Contractor::DocusignController < Contractor::AuthController
  def create
    client = DocusignRest::Client.new
    @envelope_response = client.create_envelope_from_template(
      status: 'sent',
      email: {
        subject: 'Please DocuSign this document: 1099 Contractor Agreement_For Hosts.pdf',
        body: "Hello #{current_user.first_name},\n\nHi! Thanks for interviewing with us. Please read and sign this contract. Once we receive confirmation that you have signed the contract, we will schedule your training.\n\nThanks,\nTeam HostWise"
      },
      template_id: ENV['DOCUSIGN_TEMPLATE_ID'],
      signers: [
        {
          name: current_user.name,
          email: current_user.email,
          role_name: 'Independent Contractor'
        }
      ]
    )
    render nothing: true
  end
end
