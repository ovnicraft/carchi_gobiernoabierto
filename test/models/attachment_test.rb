require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  
  test "polymorphic document" do
    att = attachments(:news_attachment)
    news = documents(:irekia_news)
    assert_equal news, att.attachable
    assert_equal [att], news.attached_files
    assert_equal [att], news.attachments
  end  
  
 if Settings.optional_modules.proposals
  test "polymorphic proposal" do
    att = attachments(:proposal_attachment)
    prop = proposals(:governmental_proposal)
    assert_equal prop, att.attachable
    assert_equal [att], prop.attached_files
    assert_equal [att], prop.attachments
  end
 end
  
  test "image type file is not valid for politician curriculum" do
    att = users(:politician_one).attachments.build
    att.file = File.open(File.join(Document::MULTIMEDIA_PATH, "test.txt"))
    # assert !att.valid? # cannot use this one since the validation is not being done via validation but via before_save callback
    assert !att.save
    assert_equal [I18n.t('attachments.must_be_pdf')], att.errors[:file]
  end
  
  test "PDf file is valid for politician curriculumxx" do
    att = users(:politician_one).attachments.build
    att.file = File.open(File.join(Document::MULTIMEDIA_PATH, "test.pdf"))
    assert att.save
    # clean test assets
    assert FileUtils.rm_rf File.dirname(att.file.path)
  end
end
