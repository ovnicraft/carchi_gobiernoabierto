# Métodos compartidos entre todas las clases que se pueden votar
# Ahora: Debate y Propuesta
module Tools::Votable
  def percent_in_favor
    return 0 if participation == 0
    (self.n_in_favor * 100.00 / participation).round
  end

  def percent_against
    100 - percent_in_favor
  end

  def percent_neutral
    50
  end

  def percentage
    [percent_in_favor, percent_against].sort.last
  end

  def participation
    self.n_in_favor + self.n_against
  end

  def n_in_favor
    @in_favor ||= self.votes.where("value = 1").count('value')
  end

  def n_against
    @against ||= self.votes.where("value = -1").count('value')
  end

  def percentage_to_text
    if self.percent_in_favor == 50 || self.participation == 0
      "neutral"
    elsif self.percent_in_favor > self.percent_against
      "in_favor"
    else
      "against"
    end
  end

end
