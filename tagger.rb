require "./apertium.rb"

class Tagger
  def initialize
    @p = IO.popen("lt-proc -z eng.automorf.bin | cg-proc -z eng-tha.rlx.bin", "r+")
    @parser = Apertium::StreamParser.new
  end

  def align(tags, l0)
    tagBuf = []
    offset = 0
    source = l0.gsub("%", "S").gsub("$", "S")

    for tag in tags
      surface = tag["surface"]
      s = source.index(surface)
      if s.nil?
        raise "Cannot align #{surface}"
      end
      e = s + surface.length
      new_tag = {
        "s" => offset + s,
        "e" => offset + e,
        "tag" => tag["tag"],
        "surface" => surface,
        "lemma" => tag["lemma"],
        "attrs" => tag["attrs"],
        "surface" => tag["surface"]
      }
      offset += e
      tagBuf << new_tag
      source = source[e..-1]
    end

    rest = source[offset..(l0.length - 1)]

    if rest =~ /[A-Za-z\u0E00-\u0EFF]/
      raise "Cannot align ===#{rest}=== is left"
    end

    tagBuf
  end

  def to_tag(stream)
    tags = stream.map do |lu|
      if not lu.kind_of?(Apertium::AmbiLu)
        nil
      else
        w_ = {"surface" => lu.analyses[0].lemma}
        if lu.analyses.length < 2
          w_["lemma"] = nil
          w_["tag"] = nil
          w_["attrs"] = nil
          w_["surface"] = nil
        else
          w_info = lu.analyses[1]
          w_["analyses"] = lu.analyses[1..-1].map{|w_info|
            {"lemma" => w_info.lemma,
             "attrs" => w_info.tags.map{|tag| tag.gsub(/[<>]/, "")},}
          }
        end
        w_
      end
    end
    return tags.select{|w| not w.nil?}
  end

  def escape_stream(t)
    t.gsub /([\^\$\/])/, '\\\\\1'
  end

  def tag(text)
    text = escape_stream(text.chomp)
    @p.write text
    @p.write "\n\0"
    @p.flush
    raw = @p.gets
    stream = @parser.parse(raw)
    return to_tag(stream)
  end
end
