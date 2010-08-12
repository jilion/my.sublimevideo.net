module MySublimeVideo
  
  module Release
    def self.beta?
      self.current == :beta
    end
    
    def self.public?
      self.current == :public
    end
    
    def self.current
      :beta
    end
  end
  
end