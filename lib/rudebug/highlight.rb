begin
  require 'syntax/convertors/abstract'

  module Syntax
    module Convertors
      class GTKTextBuffer < Abstract
        def self.color(red, green, blue)
          Gdk::Color.new(red * 256, green * 256, blue * 256)
        end

        constant = 
        Styles = {
          "number" => {
            :foreground_gdk => color(0, 99, 0),
            :background_gdk => color(222, 229, 157)
          },
          "string" => {
            :priority => 0,
            :foreground_gdk => color(153, 99, 112),
            :background_gdk => color(255, 239, 216)
          },
          "regex" => {
            :foreground_gdk => color(99, 153, 112),
            :background_gdk => color(239, 255, 216)
          },
          "constant" => {
            :foreground_gdk => color(58, 82, 120)
          },
          "method" => {
            :foreground_gdk => color(127, 0, 127),
          },
          "attribute" => {
            :foreground_gdk => color(153, 29, 170)
          },
          "symbol" => {
            :priority => 0,
            :foreground_gdk => color(152, 159, 154),
            :background_gdk => color(243, 245, 244)
          },
          "keyword" => {
            :foreground_gdk => color(16, 125, 202)
          },
          "escape" => {
            :foreground_gdk => color(255, 255, 255),
            :background_gdk => color(172, 115, 77)
          },
          "expr" => {
            :foreground_gdk => color(188, 16, 2),
            :background_gdk => color(255, 239, 216)
          },
          "punct" => {
            :foreground_gdk => color(202, 0, 34)
          },
          "comment" => {
            :foreground_gdk => color(153, 155, 154)
          },
          "ident" => {},
          "expr" => {}
        }
        Styles["module"] = Styles["class"] = Styles["constant"]
        Styles["global"] = Styles["punct"]
        Styles["char"] = Styles["number"]

        def style_for(tag)
          Styles[tag.to_s]
        end

        def convert(code, buffer)
          regions = []
          region_tags = ["default"]

          @tokenizer.tokenize(code) do |tok|
            value = tok.to_s
            group = tok.group.to_s

            case tok.instruction
              when :region_close then
                region_tags.pop

              when :region_open then
                region_tags << group
            end

            unless value.empty?
              tags = (region_tags + [group]) - ["normal"]
              tags.uniq!

              tags.reject! do |tag_name|
                tag = buffer.tag_table.lookup(tag_name)
                style = style_for(tag_name)
                is_unknown = tag.nil? and style.nil?
              
                if tag.nil? and !style.nil? then
                  priority = style.delete(:priority)
                  buffer.create_tag(tag_name, style)
                  if priority then
                    buffer.tag_table.lookup(tag_name).priority = priority
                  end
                  is_unknown = false
                end
              
                puts "Unknown tag %p" % tag_name if is_unknown
                is_unknown
              end
                  
              buffer.insert(buffer.end_iter, value, *tags.reverse)
            end
          end
        end
      end
    end

    def self.gtk_highlight(code, buffer)
      @convertor ||= Syntax::Convertors::GTKTextBuffer.for_syntax "ruby"
      @convertor.tokenizer.set(:expressions => :highlight)
      @convertor.convert(code, buffer)
    end
  end
rescue LoadError => error
  module Syntax
    module Convertors
      class GTKTextBuffer
        def self.gtk_highlight(code, buffer)
          buffer.insert(buffer.end_iter, code)
        end
      end
    end
  end
end