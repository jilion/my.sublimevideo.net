module OgoneWrapper

  STATUS = {
    '0'  => :invalid,
    '1'  => :canceled,
    '2'  => :refused, # auth refused
    '5'  => :authorized,
    '9'  => :requested,
    '46' => :waiting_3d_secure,
    '51' => :waiting, # auth waiting
    '52' => :uncertain, # auth unknown
    '92' => :uncertain, # payment uncertain
    '93' => :refused # payment refused
  }

  def self.status
    STATUS
  end

end
