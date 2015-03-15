module BulletinsHelper
  def bulletin_follow_links
    follow_irekia_links.delete_if {|l| ![:twitter, :facebook].include?(l[0])}
  end
end
