# frozen_string_literal: true

require 'ur' unless Object.const_defined?(:Ur)
require 'strscan'

module Ur
  # a RFC5988 Web Link
  #
  # https://tools.ietf.org/html/rfc5988
  class Weblink
    # Weblink::Error, base class for all errors of the Weblink class
    class Error < StandardError
    end

    # error parsing a Weblink
    class ParseError < Error
    end

    # error when attempting an operation that requires a context URI which was not provided
    class NoContextError < Error
    end

    ATTR_CHAR = /[a-zA-Z0-9!#\$&+\-.^_`|~]/.freeze # defined in https://tools.ietf.org/html/rfc5987#section-3.2.1
    PTOKEN = %r([a-zA-Z0-9!#\$%&'()*+\-./:<=>?@\[\]^_`{|}~]).freeze
    QUOTED_STRING = /"([^"]*)"/.freeze

    # attributes: semicolon, some attr_chars, an optional asterisk, equals, and a quoted
    # string or series of unquoted ptokens
    ATTRIBUTE_PAIR = /\s*;\s*(#{ATTR_CHAR.source}+\*?)\s*=\s*(?:#{QUOTED_STRING.source}|(#{PTOKEN.source}+))\s*/.freeze

    # parses an array of Web Links from the value an HTTP Link header, as described in
    # https://tools.ietf.org/html/rfc5988#section-5
    #
    # returns an Array of Weblink objects
    def self.parse_link_value(link_value, context_uri=nil)
      links = []

      return links unless link_value

      ss = StringScanner.new(link_value)
      parse_fail = proc do
        raise ParseError, "Unable to parse link value: #{link_value} " +
          "around character #{ss.pos}: #{ss.peek(link_value.length - ss.pos)}"
      end

      while !ss.eos?
        # get the target_uri, within some angle brackets
        ss.scan(/\s*<([^>]+)>/) || parse_fail.call
        target_uri = JSI::Util.uri(ss[1].freeze)
        attributes = {}
        while ss.scan(ATTRIBUTE_PAIR)
          attributes[ss[1].freeze] = (ss[2] || ss[3]).freeze
        end
        links << new(target_uri, attributes.freeze, context_uri)
        unless ss.eos?
          # either the string ends or has a comma followed by another link
          ss.scan(/\s*,\s*/) || parse_fail.call
        end
      end
      links.freeze
    end

    def initialize(target_uri, attributes, context_uri=nil)
      @target_uri = JSI::Util.uri(target_uri)
      @attributes = attributes
      @context_uri = JSI::Util.uri(context_uri)
      freeze
    end

    # the context uri of the link, as an Addressable URI. this URI must be absolute, and the target_uri
    # may be resolved against it. this is most typically the request URI of a request to a service
    attr_reader :context_uri

    # RFC 5988 calls it IRI, but nobody else does. we'll throw in an alias.
    alias_method :context_iri, :context_uri

    # returns the target URI as an Addressable::URI
    attr_reader :target_uri

    # RFC 5988 calls it IRI, but nobody else does. we'll throw in an alias.
    alias_method :target_iri, :target_uri

    # attempts to make target_uri absolute, using context_uri if available. raises if
    # there is not information available to make an absolute target URI
    def absolute_target_uri
      if target_uri.absolute?
        target_uri
      elsif context_uri
        context_uri + target_uri
      else
        raise NoContextError, "Target URI is relative but no Context URI given - cannot determine absolute target URI"
      end
    end

    # link attributes
    attr_reader :attributes

    # subscript returns an attribute of this Link, if defined, otherwise nil
    def [](attribute_key)
      @attributes[attribute_key]
    end

    # link rel attribute
    def rel
      self['rel']
    end

    alias_method :relation_type, :rel

    # compares relation types in a case-insensitive manner as mandated in
    # https://tools.ietf.org/html/rfc5988#section-4.1
    def rel?(other_rel)
      rel && other_rel && rel.downcase == other_rel.downcase
    end

    # a string of this weblink, appropriate for adding to a Link header
    def to_s
      "<#{target_uri}>" + attributes.map { |k,v| %Q(; #{k}="#{v}") }.join('')
    end

    include(JSI::Util::Private::FingerprintHash::Immutable)

    # @private
    def jsi_fingerprint
      {
        class: Weblink,
        target_uri: @target_uri,
        attributes: @attributes,
        context_uri: @context_uri,
      }.freeze
    end
  end
end
