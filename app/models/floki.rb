module Floki 
  # para news y events podemos compartir factor pq comparten tabla y sabemos que sus ids no se van a solapar
  FACTORS = {:news => 10**4, :event => 10**4, 
             :proposal => 3*10**4, :vote => 32*10**3, :argument => 35*10**3,
             # HQ :question => 4*10**4, :answer => 41*10**3, :answer_request => 42*10**3, 
             :video => 5*10**4,
             :photo => 6*10**4, :comment => 8*10**4, :area => 10**5,
             :debate => 7*10**4, :politician => 10**6}
  
  TITLE_SIZE = 17
  TITLE_COLOR = [0, 91, 140]
  TITLE_LINES = 3  
  TEXT_SIZE = 12
  TEXT_COLOR = [64, 64, 64]

  BACK_COLOR = [255, 255, 255]
  BACK_HIGHLIGHT_COLOR = [186, 196, 210]
  
  IMAGE_SIZE = [70, 70]
  
  SECTION_COLOR = [255, 255, 255]
  SECTION_BACK_COLOR = [31, 47, 66]
  
  def floki_id
    Floki::FACTORS[self.class.to_s.underscore.to_sym] + self.id
  end
end
