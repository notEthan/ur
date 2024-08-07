require_relative 'test_helper'

describe Ur::Weblink do
  describe '#parse_link_value' do
    it 'parses link headers' do
      examples = [
        # one link with some attributes
        [ %q(<http://example.com>; rel=foo; title=example; title*="an example"),
          'http://example.com',
          {'rel' => 'foo', 'title' => 'example', 'title*' => 'an example'},
        ],
        # two links
        [ %q(<http://example.com>; rel=foo; title=example; title*="an example", <http://example2.com>; rel=bar),
          'http://example.com',
          {'rel' => 'foo', 'title' => 'example', 'title*' => 'an example'},
          'http://example2.com',
          {'rel' => 'bar'},
        ],
        # spaces
        [ %q( <http://example.com> ;rel = foo ;title=example; title*="an example"  ),
          'http://example.com',
          {'rel' => 'foo', 'title' => 'example', 'title*' => 'an example'},
        ],
        # empty returns no links
        [''],
      ]
      examples.each do |example|
        link_value = example.shift
        links = Ur::Weblink.parse_link_value(link_value)
        assert_equal(example.size, links.size * 2)
        example.each_slice(2).zip(links).each do |((target_uri, attributes), link)|
          assert_equal(Addressable::URI.parse(target_uri), link.target_uri)
          assert_equal(attributes, link.attributes)
          attributes.each do |k, v|
            assert_equal(v, link[k])
          end
        end
      end
    end

    it 'gives an absolute uri based on context' do
      link = Ur::Weblink.parse_link_value('</bar>; rel=foo', 'http://example.com/foo').first
      assert_equal(Addressable::URI.parse('http://example.com/bar'), link.absolute_target_uri)
    end

    it 'gives an absolute uri with unused context' do
      link = Ur::Weblink.parse_link_value('<http://example.com/bar>; rel=foo', 'http://example.com/foo').first
      assert_equal(Addressable::URI.parse('http://example.com/bar'), link.absolute_target_uri)
    end

    it 'gives an absolute uri without context' do
      link = Ur::Weblink.parse_link_value('<http://example.com/bar>; rel=foo').first
      assert_equal(Addressable::URI.parse('http://example.com/bar'), link.absolute_target_uri)
    end

    it 'errors without context, trying to generate an absolute uri' do
      link = Ur::Weblink.parse_link_value('</bar>; rel=foo').first
      assert_raises(Ur::Weblink::NoContextError) { link.absolute_target_uri }
    end

    it 'returns an empty array for nil link header' do
      assert_equal([], Ur::Weblink.parse_link_value(nil))
    end

    it 'compares rel' do
      link = Ur::Weblink.parse_link_value('<http://example.com/bar>; rel=foo').first
      assert_equal('foo', link.rel)
      assert(link.rel?('FoO'))
    end

    it 'parse errors' do
      examples = [
        # missing >
        %q(<http://example.com),
        # missing <
        %q(http://example.com>; rel=foo),
        # , instead of ;
        %q(<http://example.com>, rel=foo),
        # non-ptoken characters (\,) unquoted
        %q(<http://example.com>; rel=b\\ar; title=example),
        %q(<http://example.com>; rel=b,ar; title=example),
      ]
      examples.each do |example|
        assert_raises(Ur::Weblink::ParseError) { Ur::Weblink.parse_link_value(example) }
      end
    end

    describe '#to_s' do
      it 'makes a string' do
        link = Ur::Weblink.new('http://example.com', :rel => 'foo', :title => 'example', 'title*' => 'an example')
        assert_equal(%q(<http://example.com>; rel="foo"; title="example"; title*="an example"), link.to_s)
      end
      it 'parses the string to the same values' do
        link = Ur::Weblink.new('http://example.com', 'rel' => 'foo', 'title' => 'example', 'title*' => 'an example')
        parsed_link = Ur::Weblink.parse_link_value(link.to_s).first
        assert_equal(link.target_uri, parsed_link.target_uri)
        assert_equal(link.attributes, parsed_link.attributes)
      end
    end
  end
end

describe('Ur::Request, Ur::Response #links') do
  it('has content type and media type') do
    ur = Ur.new({
      'request' => {
        'uri' => 'http://example.com/foo',
        'headers' => {
          'Link' => %q(<http://example.com>; rel="foo"; title="example"; title*="request example", </bar>,</baz>),
        },
      },
      'response' => {
        'headers' => {
          'LINK' => %q(<http://example.com>; rel="foo"; title="example"; title*="response example", </bar>,<http://example.com/baz>; a=b),
        },
      },
    })

    assert_equal([
      Ur::Weblink.new('http://example.com', {"rel"=>"foo", "title"=>"example", "title*"=>"request example"}, 'http://example.com/foo'),
      Ur::Weblink.new('/bar', {}, 'http://example.com/foo'),
      Ur::Weblink.new('/baz', {}, 'http://example.com/foo'),
    ], ur.request.links)

    assert_equal([
      Ur::Weblink.new('http://example.com', {"rel"=>"foo", "title"=>"example", "title*"=>"response example"}, 'http://example.com/foo'),
      Ur::Weblink.new('/bar', {}, 'http://example.com/foo'),
      Ur::Weblink.new('http://example.com/baz', {'a' => 'b'}, 'http://example.com/foo'),
    ], ur.response.links)
  end
end
