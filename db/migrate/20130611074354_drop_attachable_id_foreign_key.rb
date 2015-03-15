class DropAttachableIdForeignKey < ActiveRecord::Migration
  def self.up
    execute 'ALTER TABLE attachments DROP CONSTRAINT "att_doc_id_fk"'
  end

  def self.down
  end
end
