# Clase para los documentos adjuntos de noticias y páginas
class Attachment < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true
  belongs_to :document, :foreign_key => :attachable_id, :class_name => 'Document'
  belongs_to :proposal, :foreign_key => :attachable_id, :class_name => 'Proposal'  

  has_attached_file :file,
                    :url  => "/uploads/attachments/:id/:sanitized_basename.:extension",
                    :path => ":rails_root/public/uploads/attachments/:id/:sanitized_basename.:extension"

  validates_attachment :file, presence: true, size: {less_than: 15.megabytes}                    
  do_not_validate_attachment_file_type :file
  # validates_attachment_content_type :file, :message => I18n.t('attachments.must_be_pdf'), :allow_blank => true,
  #                                   :content_type => ['application/pdf', 'application/x-pdf']

  def is_audio?
    self.file_content_type.match(/^audio/) || self.file_content_type.match('application/x-mp3')
  end                                    
  
  # This should be done via paperclip's validates_attachment_content_type but it is not possible to 
  # have different format validations in different models(!). Since we are using image type validations
  # elsewhere, we validate that Politician attachments are PDF via a callback
  before_save :validate_content_type  
  private
  def validate_content_type
    if self.attachable.is_a?(User)
      content_type = self.file_content_type
      unless ['application/pdf', 'application/x-pdf'].include?(content_type)
        errors.add(:file, I18n.t('attachments.must_be_pdf'))
        return false
      end
    end
  end
end
