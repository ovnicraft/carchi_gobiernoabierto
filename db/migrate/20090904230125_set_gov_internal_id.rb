class SetGovInternalId < ActiveRecord::Migration
  def self.up
    # El internal_id = 0 para el Gobierno Vasco.
    execute 'UPDATE organizations SET internal_id=0 where (internal_id is null) and (parent_id is null)'
  end

  def self.down
  end
end
