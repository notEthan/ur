require 'ur' unless Object.const_defined?(:Ur)

class Ur
  # Ur::ContentType represents a Content-Type header field.
  # it parses the media type and its components, as well as any parameters.
  #
  # this class aims to be permissive in what it will parse. it will not raise any
  # error when given a malformed or syntactically invalid Content-Type string.
  # fields and parameters parsed from invalid Content-Type strings are undefined,
  # but this class generally tries to make the most sense of what it's given.
  #
  # this class is based on RFCs:
  # - Hypertext Transfer Protocol (HTTP/1.1): Semantics and Content
  #   Section 3.1.1.1. Media Type
  #   https://tools.ietf.org/html/rfc7231#section-3.1.1.1
  # - Media Type Specifications and Registration Procedures https://tools.ietf.org/html/rfc6838
  # - Multipurpose Internet Mail Extensions (MIME) Part One: Format of Internet Message Bodies.
  #   Section 5.1. Syntax of the Content-Type Header Field
  #   https://tools.ietf.org/html/rfc2045#section-5.1
  # - Multipurpose Internet Mail Extensions (MIME) Part Two: Media Types
  #   https://tools.ietf.org/html/rfc2046
  class ContentType < String
    # the character ranges in this SHOULD be significantly more restrictive,
    # and the /<subtype> construct should not be optional. however, we'll aim
    # to match whatever media type we are given.
    #
    # example:
    #     MEDIA_TYPE_REGEXP.match('application/vnd.github+json').named_captures
    #     =>
    #     {
    #       "media_type" => "application/vnd.github+json",
    #       "type" => "application",
    #       "subtype" => "vnd.github+json",
    #       "facet" => "vnd",
    #       "suffix" => "json",
    #     }
    #
    # example of being more permissive than the spec allows:
    #     MEDIA_TYPE_REGEXP.match('where the %$*! am I').named_captures
    #     =>
    #     {
    #       "media_type" => "where the %$*! am I",
    #       "type" => "where the %$*! am I",
    #       "subtype" => nil,
    #       "facet" => nil,
    #       "suffix" => nil
    #     }
    MEDIA_TYPE_REGEXP = %r{
      (?<media_type>       # the media type includes the type and subtype
        (?<type>[^\/;\"]*) # the type precedes the first slash
        (?:\/              # slash
          (?<subtype>      # the subtype includes the facet, the suffix, and bits in between
            (?:
              (?<facet>[^.+;\"]*) # the facet name comes before the first . in the subtype
              \.             # dot
            )?
            [^\+;\"]*      # anything between facet and suffix
            (?:\+          # plus
              (?<suffix>[^;\"]*) # optional suffix
            )?
          )
        )? # the subtype should not be optional, but we will match a type without subtype anyway
      )
    }x

    def initialize(*a)
      super

      scanner = StringScanner.new(self)

      if scanner.scan(MEDIA_TYPE_REGEXP)
        @media_type = scanner[:media_type].strip.freeze if scanner[:media_type]
        @type      = scanner[:type].strip.freeze       if scanner[:type]
        @subtype  = scanner[:subtype].strip.freeze    if scanner[:subtype]
        @facet   = scanner[:facet].strip.freeze      if scanner[:facet]
        @suffix = scanner[:suffix].strip.freeze     if scanner[:suffix]
      end

      @parameters = Hash.new do |h, k|
        if k.respond_to?(:downcase) && k != k.downcase
          h[k.downcase]
        else
          nil
        end
      end

      @parameters_parsed = catch(:parse_success) do
        while scanner.scan(/;\s*(?<key>[^=;\"]+)=/)
          key = scanner[:key]
          if scanner.scan(/"/)
            value = String.new
            until scanner.scan(/"/)
              if scanner.scan(/\\/)
                throw(:parse_success, false) if scanner.eos?
                value << scanner.getch
              end
              value << scanner.scan(/[^\"\\]*/)
              throw(:parse_success, false) if scanner.eos?
            end
          else
            value = scanner.scan(/[^;]*/)
          end
          @parameters[key.freeze] = value.freeze
        end
        throw(:parse_success, scanner.eos?)
      end

      @parameters.freeze

      freeze
    end

    # @return [String, nil] the media type of this content type.
    #   e.g. "application/vnd.github+json" in content-type: application/vnd.github+json; charset="utf-8"
    attr_reader :media_type

    # @return [String, nil] the 'type' portion of our media type.
    #   e.g. "application" in content-type: application/vnd.github+json; charset="utf-8"
    attr_reader :type

    # @return [String, nil] the 'subtype' portion of our media type.
    #   e.g. "vnd.github+json" in content-type: application/vnd.github+json; charset="utf-8"
    attr_reader :subtype

    # @return [String, nil] the 'facet' portion of our media type.
    #   e.g. "vnd" in content-type: application/vnd.github+json; charset="utf-8"
    attr_reader :facet

    # @return [String, nil] the 'suffix' portion of our media type.
    #   e.g. "json" in content-type: application/vnd.github+json; charset="utf-8"
    attr_reader :suffix

    # @return [Hash<String, String>] parameters of this content type.
    #   e.g. {"charset" => "utf-8"} in content-type: application/vnd.github+json; charset="utf-8"
    attr_reader :parameters

    # @return [Boolean] whether the parameters were parsed successfully
    def parameters_parsed?
      @parameters_parsed
    end
  end
end
