module Apertium
  OUTSIDE_WORD = 0
  INSIDE_WORD = 1
  
  class B
    attr_reader :text
    def initialize(text)
      @text = text
    end

    def to_simple
      {type: :B, text: @text}
    end
    
    def parse
      self
    end
    
    def to_stream
      "#{@text}"
    end
  end
  
  class Analyse
    attr_reader :lemma, :tags
    def initialize(lemma, tags)
      @lemma = lemma
      @tags = tags
    end

    def to_simple
      {lemma: @lemma, 
        tags: @tags}
    end

    def to_stream(part="a")
      if part == "a"
        tags = ""
        if @tags.length > 0
          tags = @tags.map{|t| "<#{t}>"}.join("")
        end
        "#{@lemma}#{tags}"
      else
        lemma_lst = @lemma.split("#")
        #$stderr.puts "@@@ part = 
        if part == "h"
          "#{lemma_lst[0]}"
        else
          "#{lemma_lst[1..-1].join("")}"
        end
      end
    end
  end
  
  class AmbiLu
    attr_reader :analyses, :part
    attr_writer :analyses, :part
    def initialize(analyses, part = "a")
      @analyses = analyses
      @part = part
    end

    def to_stream
      #PP.pp analyses, $stderr
      "^#{@analyses.map{|a| a.to_stream(@part)}.join("/")}$"
    end

    def to_simple
      {analyses: @analyses.map{|t| t.to_simple}, part: @part}
    end
  end
  
  class W0
    attr_reader :text
    def initialize(text)
      @text = text
    end
    
    def to_simple
      {type: :W0, text: @text}
    end

    def parse_analisis(t)
      t = t.split(/(<[^>]+>)/).select{|w| w != ""}    
      lemma = t[0]
      tags = t[1..-1].map{|tag| tag[1..-2]}
      return Analyse.new(lemma, tags)
    end
    
    def parse
      s = 0
      analyses = []
      text = @text[1..-2]
      for i in 0..(text.length-1)
        if text[i] == '/' and (i == 0 or text[i] != '\\')
          analyses << parse_analisis(text[s..(i-1)])
          s = i+1
        end
      end
      if s < text.length
        analyses << parse_analisis(text[s..(text.length-1)])
      end
      return AmbiLu.new(analyses)
    end
  end

  class StreamParser
    
    def initialize
    end
    
    def parse(stream)    
      pass0 = parse0(stream)
      return pass0.map{|t| t.parse}    
    end
    
    def parse0(stream)
      state = OUTSIDE_WORD
      s = 0
      
      pass0 = []
      
      for i in 0 .. (stream.length - 1)
        case state
        when OUTSIDE_WORD
          if stream[i] == '^' and (i == 0 or stream[i] != '\\')
            if i > 0
              if i-1 >= s
                txt = stream[s..(i-1)]
                pass0 << B.new(txt)
              end
            end
            s = i
            state = INSIDE_WORD
          end
        when INSIDE_WORD
          if stream[i] == '$' and (i == 0 or stream[i] != '\\')
            state = OUTSIDE_WORD
            txt = stream[s..i]
            pass0 << W0.new(txt)
            s = i + 1
          end
          
        end
      end #for
      
      return pass0
    end
  end
end
