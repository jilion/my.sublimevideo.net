module Admin::TailorMadePlayerRequestsHelper

  def select_options_for_highrise_export(tailor_made_player_request)
    options = []
    if tailor_made_player_request.company?
      options << ['Import this person & company into Highrise', :person]
      options << ['Import this company into Highrise', :company]
    else
      options << ['Import this person into Highrise', :person]
    end
    options << ['Create a case in Highrise from this request', :kase]

    options
  end

end
