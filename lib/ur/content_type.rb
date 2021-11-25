# frozen_string_literal: true

require 'ur' unless Object.const_defined?(:Ur)

module Ur
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
    # and the `/<subtype>` construct should not be optional. however, we'll aim
    # to match whatever media type we are given.
    #
    # example:
    #
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
    #
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

      while scanner.scan(/(;\s*)+/)
        key = scanner.scan(/[^;=\"]*/)
        if key && scanner.scan(/=/)
          value = String.new
          until scanner.eos? || scanner.check(/;/)
            if scanner.scan(/\s+/)
              ws = scanner[0]
              # discard trailing whitespace.
              # other whitespace isn't technically valid but we are permissive so we put it in the value.
              value << ws unless scanner.eos? || scanner.check(/;/)
            elsif scanner.scan(/"/)
              until scanner.eos? || scanner.scan(/"/)
                if scanner.scan(/\\/)
                  value << scanner.getch unless scanner.eos?
                end
                value << scanner.scan(/[^\"\\]*/)
              end
            else
              value << scanner.scan(/[^\s;\"]*/)
            end
          end
          @parameters[key.downcase.freeze] = value.freeze
        end
      end

      @parameters.freeze

      freeze
    end

    # the media type of this content type.
    # e.g. `"application/vnd.github+json"` in `content-type: application/vnd.github+json; charset="utf-8"`
    # @return [String, nil]
    attr_reader :media_type

    # the 'type' portion of our media type.
    # e.g. `"application"` in `content-type: application/vnd.github+json; charset="utf-8"`
    # @return [String, nil]
    attr_reader :type

    # the 'subtype' portion of our media type.
    # e.g. `"vnd.github+json"` in `content-type: application/vnd.github+json; charset="utf-8"`
    # @return [String, nil]
    attr_reader :subtype

    # the 'facet' portion of our media type.
    # e.g. `"vnd"` in `content-type: application/vnd.github+json; charset="utf-8"`
    # @return [String, nil]
    attr_reader :facet

    # the 'suffix' portion of our media type.
    # e.g. `"json"` in `content-type: application/vnd.github+json; charset="utf-8"`
    # @return [String, nil]
    attr_reader :suffix

    # parameters of this content type.
    # e.g. `{"charset" => "utf-8"}` in `content-type: application/vnd.github+json; charset="utf-8"`
    # @return [Hash<String, String>]
    attr_reader :parameters

    # is the 'type' portion of our media type equal (case-insensitive) to the given other_type
    # @param other_type
    # @return [Boolean]
    def type?(other_type)
      type && type.casecmp?(other_type)
    end

    # is the 'subtype' portion of our media type equal (case-insensitive) to the given other_subtype
    # @param other_subtype
    # @return [Boolean]
    def subtype?(other_subtype)
      subtype && subtype.casecmp?(other_subtype)
    end

    # is the 'suffix' portion of our media type equal (case-insensitive) to the given other_suffix
    # @param other_suffix
    # @return [Boolean]
    def suffix?(other_suffix)
      suffix && suffix.casecmp?(other_suffix)
    end

    SOME_TEXT_SUBTYPES = %w(
      x-www-form-urlencoded
      json
      json-seq
      jwt
      jose
      yaml
      x-yaml
      xml
      html
      css
      javascript
      ecmascript
    ).map(&:freeze).freeze

    # does this content type appear to be binary?
    # this library makes its best guess based on a very incomplete knowledge
    # of which media types indicate binary or text.
    # @param unknown [Boolean] return this value when we have no idea whether
    #   our media type is binary or text.
    # @return [Boolean]
    def binary?(unknown: true)
      return false if type_text?

      SOME_TEXT_SUBTYPES.each do |cmpsubtype|
        return false if (suffix ? suffix.casecmp?(cmpsubtype) : subtype ? subtype.casecmp?(cmpsubtype) : false)
      end

      # these are generally binary
      return true if type_image? || type_audio? || type_video?

      # we're out of ideas
      return unknown
    end

    # is this a JSON content type?
    # @return [Boolean]
    def json?
      suffix ? suffix.casecmp?('json') : subtype ? subtype.casecmp?('json') : false
    end

    # is this an XML content type?
    # @return [Boolean]
    def xml?
      suffix ? suffix.casecmp?('xml'): subtype ? subtype.casecmp?('xml') : false
    end

    # is this a `x-www-form-urlencoded` content type?
    # @return [Boolean]
    def form_urlencoded?
      suffix ? suffix.casecmp?('x-www-form-urlencoded'): subtype ? subtype.casecmp?('x-www-form-urlencoded') : false
    end

    # is the 'type' portion of our media type 'text'
    # @return [Boolean]
    def type_text?
      type && type.casecmp?('text')
    end

    # is the 'type' portion of our media type 'image'
    # @return [Boolean]
    def type_image?
      type && type.casecmp?('image')
    end

    # is the 'type' portion of our media type 'audio'
    # @return [Boolean]
    def type_audio?
      type && type.casecmp?('audio')
    end

    # is the 'type' portion of our media type 'video'
    # @return [Boolean]
    def type_video?
      type && type.casecmp?('video')
    end

    # is the 'type' portion of our media type 'application'
    # @return [Boolean]
    def type_application?
      type && type.casecmp?('application')
    end

    # is the 'type' portion of our media type 'message'
    # @return [Boolean]
    def type_message?
      type && type.casecmp?('message')
    end

    # is the 'type' portion of our media type 'multipart'
    # @return [Boolean]
    def type_multipart?
      type && type.casecmp?('multipart')
    end
  end
end
