#
# Implementation of RAKE (Rapid Automatic Keyword Extraction) Algoritm in Ruby
#
# Ref: S Rose, D Engel, N Cramer, W Cowley, Automatic keyword extraction from individual documents,
#      in "Text Mining: Applications and Theory", John Wiley & Sons, 2010
#
# (c) svet@efaber.net, Jan 2011
#

# require "pp"
require "matrix"

class Matrix
  def []=(i, j, x)
    @rows[i][j] = x
  end
end


class RakeKeyword

  def initialize(t)
    @t = t.downcase
    # add space around phrase separators "." and ","
    @t = @t.gsub(/([\,\.\:\;])/, ' \1 ')
    # reduce 2+ spaces to just one
    @t = @t.gsub(/(\ ){2,}/, " ")
  end
  
  def find_candidates()
    w = @t.split(" ")

     #stopwords = ["of", "the", "a", "in", "the", "all", "over", "and", "are", 
     #         "for", "can", "be", "given", "used", "these", "mixed", "types", 
     #         "considered"]

    stopwords = ["el", "de", "del", "y", "estan", "que", "las", "para", "con", 
                  "una", "su", "por", "ha", "en", "un", "a", "la", "estos", "al", 
                  "esta", "son", "los", "o", "se", "ya", "lo", "entre", "sus", "es",
                  "alguna", "haber", "cuando", "este", "algunos" ]

    phsep = [".", ",", ":", ";"]
 
    # puts "Candidate keywords ..."
    # candidate keywords
    @cw=[]
    cwc = ''
    w.each do |ow| 
      isstop = stopwords.any? {|e| e==ow}
      isphsep = phsep.any? {|e| e==ow}
      if isstop || isphsep
         @cw << " "+cwc.strip+" " if !cwc.empty?
         cwc = ""
      else
        cwc += " "+ow
      end
    end
    @cw << " "+cwc.strip+" " if !cwc.empty?

    # as sep words:
    @sepwords = @cw.join(" ").split(" ").sort.uniq
    @gc = Matrix.zero(@sepwords.size)

    # puts "Calc graph of word co-ocurrences ..."
    # calc the graph of word co-ocurrences
    @sepwords.each_with_index do |row, i|
      # puts "  ... "+row
      rr = (@cw.find_all {|c| c.match(/[^\w]#{row}[^\w]/) })
      @sepwords.each_with_index do |col, j|
        # @gc[i,j] = ((@cw.find_all {|c| c.match(/[^\w]#{row}[^\w]/) }).find_all {|c| c.match(/[^\w]#{col}[^\w]/) }).size  
        if j>=i 
          @gc[i,j] = (rr.find_all {|c| c.match(/[^\w]#{col}[^\w]/) }).size  
        else
          @gc[i,j] = @gc[j,i] 
        end
      end
    end
    # puts "Done ..."
  end


  def freq(word)
    (@cw.find_all {|c| c.match(/[^\w]#{word}[^\w]/) }).size
  end


  def deg(word)
    k = @sepwords.index(word)
    @gc[k, 0..-1].inject(0){|sum,item| sum + item}
  end


  def keywords()
    self.find_candidates()
    wordscores = Hash.new()
    @sepwords.each do |word|
      degv = deg(word)
      freqv = freq(word)
      dfr = 1.0 * degv / freqv
      wordscores[word] = [degv, freqv, dfr]
    end

    kwscores = Hash.new()
    @cw.uniq.each do |kw|
      score = 0.0
      kw.split.each { |onew| score += wordscores[onew][2] }
      kwscores[kw.strip] = score
    end
    
    kwsorted = kwscores.sort {|a,b| b[1]<=>a[1]}
    kwsorted
    
  end
end


