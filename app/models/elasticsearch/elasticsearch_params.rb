class Time
  def strftime_search
    self.strftime("%Y-%m-%dT%H:%M:%S")
  end
end

module Elasticsearch::ElasticsearchParams
  I18n.locale ||= :es

  URI = Rails.application.secrets['elasticsearch']['uri']
  RELATED_URI = Rails.application.secrets['elasticsearch']['related_uri']
  BOPV_URI = Rails.application.secrets['elasticsearch']['bopv_uri']
  ALBISTE_URI = Rails.application.secrets['elasticsearch']['albiste_uri']

  # Exclusions = ['y', 'de']
  ITEMS_PER_PAGE = 18

  MONTH_NAMES = {1 => 'Enero', 2 => 'Febrero', 3 => 'Marzo', 4 => 'Abril', 5 => 'Mayo', 6 => 'Junio', 7 => 'Julio', 8 => 'Agosto', 9 => 'Septiembre', 10 => 'Octubre', 11 => 'Noviembre', 12 => 'Diciembre'}

  DATE_RANGES = {
    '24h' => { 'from' => 24.hours.ago.strftime_search, 'to' => Time.zone.now.strftime_search},
    '1w' => { 'from' => 1.week.ago.strftime_search, 'to' => Time.zone.now.strftime_search},
    '1m' => { 'from' => 1.month.ago.strftime_search, 'to' => Time.zone.now.strftime_search},
    '1y' => { 'from' => 1.year.ago.strftime_search, 'to' => Time.zone.now.strftime_search},
    '4y' => { 'from' => 4.year.ago.strftime_search, 'to' => Time.zone.now.strftime_search}
  }
  # '2y' => { 'from' => I18n.localize(2.year.ago, :format => 'search'), 'to' => I18n.localize(Time.zone.now, :format => 'search')}

  DATE_IN_HOURS = { 24 => '24h', 168 => '1w', 672 => '1m', 696 => '1m', 720 => '1m', 744 => '1m', 8760 => '1y', 8784 => '1y', 17520 => '2y', 17544 => '2y' }

  FACETS = {
    'type' => {
      :type => 'terms', :field => '_type', :size => 100, :show => {:no_facets => 5}
    },
    'areas' => {
      :type => 'terms', :field => 'areas.analyzed', :size => begin;Area.count;rescue;15;end, :show => {:no_facets => 5}
    },
    'tags' => {
      :type => 'terms', :field => 'tags.analyzed', :size => 15, :show => {:no_facets => 5}
    },
    'politicianst' => {
      :type => 'terms', :field => 'politicianst.analyzed', :size => 15, :show => {:no_facets => 5}
    },
    'organization' => {
      :type => 'terms', :field => 'organization.analyzed', :size => begin;Organization.count;rescue;15;end, :show => {:no_facets => 5}
    },
    'term' => {
      :type => 'terms', :field => 'term', :size => 5, :show => {:no_facets => 5}
    },
    'date' => {
      :type => 'range', :field => 'published_at', :other => {'ranges' => [ DATE_RANGES['24h'], DATE_RANGES['1w'], DATE_RANGES['1m'], DATE_RANGES['1y'] ]}, :show => {:no_facets => 4}
    },
    'year' => {
      :type => 'terms', :field => 'year', :size => 100, :other => {'order' => 'reverse_term'}, :show => {:no_facets => 5}
    },
    'month' => {
      :type => 'terms', :field => 'month', :size => 12, :show => {:no_facets => 12}
    },
    'rango' => {
      :type => 'terms', :field => 'rango.analyzed', :size => 15, :show => {:no_facets => 5}
    },
    'seccion' => {
      :type => 'terms', :field => 'seccion.analyzed', :size => 15, :show => {:no_facets => 5}
    },
    'organo' => {
      :type => 'terms', :field => 'organo.analyzed', :size => 15, :show => {:no_facets => 5}
    },
    'materias' => {
      :type => 'terms', :field => 'materias.analyzed', :size => 15, :show => {:no_facets => 5}
    }
  }

  # An array is needed in order to preserve order
  # 'organization',
  FACET_FIELDS = ['type', 'areas', 'tags', 'politicianst', 'term', 'date', 'year', 'month', 'materias', 'dept', 'seccion', 'rango']

  # these are indexed in en|es|eu
  TRANSLATABLE_FACETS = ['tags', 'organization', 'month', 'areas', 'seccion', 'rango', 'organo', 'materias', 'term']

  BOPV_FACETS = ['seccion', 'rango', 'organo', 'materias']

end
