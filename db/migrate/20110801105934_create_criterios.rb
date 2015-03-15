class CreateCriterios < ActiveRecord::Migration
  def self.up
    create_table :criterios, :force => true do |t|
      t.string :title
      t.integer :parent_id
      t.integer :results_count
      t.timestamps
    end
  end

  def self.down
    drop_table :criterios
  end
end