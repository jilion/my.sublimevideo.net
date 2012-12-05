require_dependency 'highrise_wrapper'

module Service
  TailorMadePlayerRequest = Struct.new(:tailor_made_player_request) do

    def export_person_to_highrise
      names = tailor_made_player_request.name.split(' ')
      first_name = names.first
      last_name  = names.size > 1 ? names.drop(1).join(' ') : ''

      attributes = {
        first_name: first_name, last_name: last_name,
        title: tailor_made_player_request.job_title,
        company_name: tailor_made_player_request.company,
        background: "Imported from https://admin.sublimevideo.net/tailor_made_player_requests/#{tailor_made_player_request.id}",
        contact_data: {
          email_addresses: {
            email_address: {
              address: tailor_made_player_request.email,
              location: 'Work'
            }
          },
          web_addresses: {
            web_address: {
              url: tailor_made_player_request.url,
              location: 'Work'
            }
          }
        }
      }

      save(Highrise::Person.new(attributes))
    end

    def export_company_to_highrise
      attributes = {
        name: tailor_made_player_request.company,
        background: "Imported from https://admin.sublimevideo.net/tailor_made_player_requests/#{tailor_made_player_request.id}"
      }

      save(Highrise::Company.new(attributes))
    end

    def create_case_in_highrise
      attributes = {
        name: "Tailor-made player request for #{tailor_made_player_request.company}"
      }

      save(Highrise::Kase.new(attributes))
    end

    private

    def save(record)
      if record.save
        true
      else
        log_and_airbrake(record)
        false
      end
    end

    def log_and_airbrake(record)
      Rails.logger.info record.inspect
      Notify.send("#{record.class} at https://admin.sublimevideo.net/tailor_made_player_requests/#{tailor_made_player_request.id} couldn't be imported into Highrise: #{record.inspect}")
    end

  end
end
