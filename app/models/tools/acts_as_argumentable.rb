module Tools::ActsAsArgumentable
  def self.included(base)
    base.has_many :arguments, :as => :argumentable, :dependent => :destroy
  end

  def argumenters
    self.arguments.collect {|c| c.user}.uniq
  end
end
