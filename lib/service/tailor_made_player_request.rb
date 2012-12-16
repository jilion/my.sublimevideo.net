require_dependency 'highrise_wrapper'

module Service
  TailorMadePlayerRequest = Struct.new(:tailor_made_player_request) do

    def self.import_to_highrise(tailor_made_player_request_id)
      new(::TailorMadePlayerRequest.find(tailor_made_player_request_id)).import_to_highrise
    end

    def import_to_highrise
      create_case_in_highrise
    end

    private

    def create_case_in_highrise
      return true if tailor_made_player_request.highrise_kase_id?

     @highrise_kase = highrise_save(Highrise::Kase.new(name: "Tailor-made player request for #{tailor_made_player_request.company}",
                                                       background: "From https://admin.sublimevideo.net/tailor_made_player_requests/#{tailor_made_player_request.id}"))

      if @highrise_kase
        tailor_made_player_request.update_column(:highrise_kase_id, @highrise_kase.id)
        # Adding parties through the API is not supported...?!
        # party_company = Highrise::Party.new(highrise_company.attributes.merge(type: 'Company'))
        # party_people  = Highrise::Party.new(highrise_person.attributes.merge(type: 'Person'))
        # @highrise_kase.parties << party_company << party_people
        # highrise_save(@highrise_kase)

        attach_note_to_highrise_kase

        @highrise_kase
      else
        false
      end
    end

    def attach_note_to_highrise_kase
      attributes = { body: highrise_note_body, owner_id: highrise_person.id, author_id: highrise_person.id }
      # The highrise gem doesn't implement Highrise::Attachment at the moment
      # if tailor_made_player_request.document.present?
      #   attributes[:attachments] = Highrise::Attachment.new(url: tailor_made_player_request.document.url,
      #                                                name: File.basename(tailor_made_player_request.document.url))
      # end
      @highrise_kase.add_note(attributes)
    end

    def highrise_company
      @highrise_company ||= begin
        Highrise::Company.find_by_name(tailor_made_player_request.company) ||
        highrise_save(Highrise::Company.new(name: tailor_made_player_request.company,
                                            background: "From https://admin.sublimevideo.net/tailor_made_player_requests/#{tailor_made_player_request.id}"))
      end
    end

    def highrise_person
      @highrise_person ||= begin
        names = tailor_made_player_request.name.split(' ')
        first_name = names.first
        last_name  = names.size > 1 ? names.drop(1).join(' ') : ''

        attributes = {
          first_name: first_name, last_name: last_name,
          title: tailor_made_player_request.job_title,
          background: "From https://admin.sublimevideo.net/tailor_made_player_requests/#{tailor_made_player_request.id}",
          company_name: tailor_made_player_request.company,
          contact_data: {
            email_addresses: {
              email_address: {
                address: tailor_made_player_request.email,
                location: 'Work'
              }
            }
          }
        }

        highrise_save(Highrise::Person.new(attributes))
      end
    end

    def highrise_note_body
      body = ["Contact: #{tailor_made_player_request.name} (#{tailor_made_player_request.email})"]
      body << "Job & company: #{tailor_made_player_request.job_title} at #{tailor_made_player_request.company}"
      body << "Website: #{tailor_made_player_request.url}"
      body << "Country: #{Country[tailor_made_player_request.country].name}"
      topic = if tailor_made_player_request.topic == 'other'
        tailor_made_player_request.topic_other_detail
      else
        I18n.t("activerecord.attributes.tailor_made_player_request.topic_#{tailor_made_player_request.topic}")
      end
      body << "Topic: #{topic}"
      if tailor_made_player_request.topic_standalone_detail?
        body << "Main agency: #{tailor_made_player_request.topic_standalone_detail}"
      end
      body << "Description: #{tailor_made_player_request.description}"
      if tailor_made_player_request.document.present?
        body << "Document: https://admin.sublimevideo.net/tailor_made_player_requests/#{tailor_made_player_request.id}"
      end

      body.join("\n\n")
    end

    def highrise_save(record)
      if record.save!
        record
      else
        Rails.logger.info record.inspect
        false
      end
    end

  end
end
