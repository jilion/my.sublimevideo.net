class Populator

  def execute(*args)
    raise NotImplementedError, '#execute must be implemented in the subclass of Populator'
  end

end
