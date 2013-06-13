module PreviewKit

  def self.kit_names
    %w[classic flat light html5 twit sony anthony next15 blizzard df]
  end

  def self.kit_identifer(design_name)
    ((kit_names.index(design_name) || 0) + 1).to_s
  end

end
