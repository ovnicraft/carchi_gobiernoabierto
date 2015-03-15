class Streaming
  def logger(*args)
    ActiveRecord::Base.logger(*args)
  end
  
  attr_reader :live
  attr_reader :announced
  attr_reader :programmed
  
  def initialize
    # próximo streaming programado: eventos con streaming en Irekia que empiezan dentro de 5 horas o menos
    # y no han acabado.
    next4streaming = Event.next4streaming
    grouped_streamings = next4streaming.group_by {|se| se.streaming_status.to_sym}
        
    grouped_streamings[:live] ||= []
    StreamFlow.live().map do |sf| 
      if sf.on_air?
        grouped_streamings[:live].push sf.event.present? ? sf.event : sf
      end
    end
    grouped_streamings[:live] = grouped_streamings[:live].compact.uniq
    
    
    grouped_streamings[:announced] ||= []
    StreamFlow.announced().map do |sf| 
      if sf.announced?
        grouped_streamings[:announced].push sf.event.present? ? sf.event : sf
      end
    end
    grouped_streamings[:announced] = grouped_streamings[:announced].compact.uniq
    
    grouped_streamings[:programmed] ||= []
    
    @live = grouped_streamings[:live]
    @announced = grouped_streamings[:announced]
    @programmed = grouped_streamings[:programmed]
  end
  
  def has_next_streaming?
    (self.live + self.announced + self.programmed).flatten.present?
  end
end
