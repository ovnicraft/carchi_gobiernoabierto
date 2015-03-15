class DebateStage < ActiveRecord::Base
  belongs_to :debate
  
  STAGES = [:presentation, :discussion, :contribution, :conclusions]
  
  validates_inclusion_of :label, :in => STAGES.map {|s| s.to_s}
  
  validates_presence_of :starts_on
  validate :ends_later_than_or_equals_starts, :if => Proc.new {|stage| stage.ends_on && stage.starts_on}  
  
  before_create :set_position
  before_save :set_ends_on_if_empty

  attr_accessor :active

  def is_passed?
    self.ends_on < Date.today
  end

  def is_future?
    self.starts_on > Date.today
  end

  def is_current?
    !self.is_passed? && !self.is_future?
  end

  def active
    @active.nil? ? true : @active
  end
  
  protected  
  #
  # Comprueba si la fase tiene la fecha de inicio correcta con respecto 
  # a la fase anterior dentro de la lista de fases del debate.
  #
  # NOTA: No se puede usar self.debate porque si es un debate nuevo,
  # para las fases debate_id todavía es nil.
  # Por esto, llamamos este método desde un before_save del modelo Debate
  # donde tenemos acceso a todas las fases del debate. 
  #
  def has_correct_starts_on?(debate_stages)
    current_stage_position = DebateStage::STAGES.index(self.label.to_sym)
    if current_stage_position > 0
      if prev_stage = debate_stages.detect {|s| s.label.eql?(STAGES[current_stage_position-1].to_s)}
        if prev_stage.starts_on >= starts_on
          errors.add(:starts_on, "La fecha de inicio tiene que ser posterior a la fecha de inicio de la fase anterior.")
          return false
        end
      end
    end
    return true
  end

  private
  
  def ends_later_than_or_equals_starts
    errors.add(:base, "La fecha de fin debe ser posterior o igual a la de inicio") if self.ends_on < self.starts_on
  end
  
  # Si no está inidcada la fecha fin, esta coincide con la de inicio.
  def set_ends_on_if_empty
    self.ends_on ||= self.starts_on
  end

  # Asigna la posición de la fase dentro del debate
  def set_position
    self.position = DebateStage::STAGES.index(self.label.to_sym) + 1
  end    
end
