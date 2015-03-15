module AlbumsHelper
  def pretty_dates(starts_at, ends_at, locale=I18n.locale)
    starts_on = starts_at.to_date
    ends_on = ends_at.to_date
    if starts_on.eql?(ends_on)
      I18n.localize(starts_at.to_date, :format => :long, :locale => locale)
    else
      # Different dates
      start_date = I18n.localize(starts_at.to_date, :format => :long, :locale => locale)
      end_date = I18n.localize(ends_at.to_date, :format => :long, :locale => locale)
      "#{start_date} - #{end_date}"
    end    
  end
end
