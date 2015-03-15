require 'tiny_mce/tiny_mce'
require 'tiny_mce/tiny_mce_helper'

TinyMCE::OptionValidator.load
ActionController::Base.send(:include, TinyMCE)