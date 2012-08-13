class Module
  def exceptions(*names)
    names.each do|n|
      n = n.to_s.capitalize
      
      class_eval %{
        unless const_defined?("Error")
          const_set("Error", Class.new(StandardError) )
        end
        class #{n} < Error; end
      }
    end
  end
end