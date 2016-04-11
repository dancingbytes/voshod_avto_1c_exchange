#
# Подсчет строк в файле
#
module VoshodAvtoExchange

  class LineCounter < ::Nokogiri::XML::SAX::Document

    def self.count(file_name)

      total = 0

      parser  = ::Nokogiri::XML::SAX::Parser.new(
        new(->(lines) { total = lines })
      )
      parser.parse_file(file_name)

      total

    end # self.count

    def initialize(clb)

      @lines  = 0
      clb     = ->(lines) {} unless clb.is_a?(::Proc)
      @clb    = clb

    end # initialize

    def start_element(name, attrs = [])
      @lines += 1
    end # start_element

    def end_element(name)
    end # end_element

    def characters(str)
    end # characters

    def end_document
      @clb.call(@lines)
    end # end_document

end # Parsers

end # VoshodAvtoExchange
