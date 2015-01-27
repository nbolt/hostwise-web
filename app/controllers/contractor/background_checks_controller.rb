require 'rest_client'

class Contractor::BackgroundChecksController < Contractor::AuthController
  def create
    dob = current_user.contractor_profile.dob
    formatted_dob = [dob[4..dob.length-1], dob[0..1], dob[2..3]].join '-'

    application = Nokogiri::XML::Builder.new do |xml|
      xml.BackgroundCheck(userId: ENV['TAZWORKS_USERID'], password: ENV['TAZWORKS_PASSWORD']) {
        xml.BackgroundSearchPackage(action: 'submit', type: 'EMPLOYMENT PACKAGE ALC NO CREDIT') {
          xml.PersonalData {
            xml.PersonName {
              xml.GivenName current_user.first_name
              xml.FamilyName current_user.last_name
            }
            xml.DemographicDetail {
              xml.GovernmentId(issuingAuthority: 'SSN') {
                xml.text current_user.contractor_profile.ssn
              }
              xml.DateOfBirth formatted_dob
            }
            xml.PostalAddress(type: 'current') {
              xml.PostalCode current_user.contractor_profile.zip
              xml.Region current_user.contractor_profile.state
              xml.Municipality current_user.contractor_profile.city
              xml.DeliveryAddress {
                xml.AddressLine current_user.contractor_profile.address1
              }
            }
            xml.EmailAddress current_user.email
            xml.Telephone current_user.phone_number
          }
          xml.Screenings(useConfigurationDefaults: 'Yes') {
            xml.AdditionalItems(type: 'x:postback_url') {
              xml.Text background_check_notification_url
            }
            xml.AdditionalItems(type: 'x:postback_format') {
              xml.Text 'PDF'
            }
            xml.AdditionalItems(type: 'x:return_xml_results') {
              xml.Text 'yes'
            }
          }
        }
      }
    end

    xml = application.doc.serialize(save_with: 0).sub("\n", '')
    BackgroundCheckSubmissionJob.perform_later(current_user, xml)

    render nothing: true
  end
end
