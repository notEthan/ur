require_relative 'test_helper'

describe 'Ur::ContentType' do
  let(:content_type) { Ur::ContentType.new(content_type_str) }
  describe 'application/vnd.github+json; charset="utf-8"' do
    let(:content_type_str) { 'application/vnd.github+json; charset="utf-8"' }
    it 'parses' do
      assert_equal(content_type, content_type_str)

      assert_equal('application/vnd.github+json', content_type.media_type)

      assert_equal('application', content_type.type)
      assert(content_type.type?('Application'))
      assert(content_type.type_application?)

      assert_equal('vnd.github+json', content_type.subtype)
      assert_equal('vnd', content_type.facet)
      assert_equal('json', content_type.suffix)

      assert_equal({'charset' => 'utf-8'}, content_type.parameters)
      assert_equal('utf-8', content_type.parameters['CharSet'])
    end
  end
  describe 'no subtype' do
    let(:content_type_str) { 'application; charset="utf-8"' }
    it 'will allow it' do
      assert_equal(content_type, content_type_str)

      assert_equal('application', content_type.media_type)

      assert_equal('application', content_type.type)
      assert(content_type.type?('Application'))

      assert_equal(nil, content_type.subtype)
      assert_equal(nil, content_type.facet)
      assert_equal(nil, content_type.suffix)

      assert_equal({'charset' => 'utf-8'}, content_type.parameters)
      assert_equal('utf-8', content_type.parameters['CharSet'])
    end
  end
  describe 'no facet' do
    let(:content_type_str) { 'application/github+json; charset="utf-8"' }
    it 'parses' do
      assert_equal(content_type, content_type_str)

      assert_equal('application/github+json', content_type.media_type)

      assert_equal('application', content_type.type)
      assert(content_type.type?('Application'))

      assert_equal('github+json', content_type.subtype)
      assert_equal(nil, content_type.facet)
      assert_equal('json', content_type.suffix)

      assert_equal({'charset' => 'utf-8'}, content_type.parameters)
      assert_equal('utf-8', content_type.parameters['CharSet'])
    end
  end
  describe 'no suffix' do
    let(:content_type_str) { 'application/vnd.github.json; charset="utf-8"' }
    it 'parses' do
      assert_equal(content_type, content_type_str)

      assert_equal('application/vnd.github.json', content_type.media_type)

      assert_equal('application', content_type.type)
      assert(content_type.type?('Application'))

      assert_equal('vnd.github.json', content_type.subtype)
      assert_equal('vnd', content_type.facet)
      assert_equal(nil, content_type.suffix)

      assert_equal({'charset' => 'utf-8'}, content_type.parameters)
      assert_equal('utf-8', content_type.parameters['CharSet'])
    end
    describe('[invalid] quote in type') do
      let(:content_type_str) { 'applic"ation/foo; foo=bar' }
      it('gives up') do
        assert_equal('applic', content_type.type)
        assert_equal(nil, content_type.subtype)
      end
    end
    describe('[invalid] backslash in type') do
      let(:content_type_str) { 'applicati\on/foo; foo=bar' }
      it('parses') do
        assert_equal('applicati\\on', content_type.type)
        assert_equal('foo', content_type.subtype)
      end
    end
    describe('[invalid] quote in subtype') do
      let(:content_type_str) { 'application/f"oo; foo=bar' }
      it('gives up') do
        assert_equal('application', content_type.type)
        assert_equal('f', content_type.subtype)
      end
    end
    describe('[invalid] backslash in subtype') do
      let(:content_type_str) { 'application/fo\\o; foo=bar' }
      it('parses') do
        assert_equal('application', content_type.type)
        assert_equal('fo\\o', content_type.subtype)
      end
    end
  end
  describe 'parameters' do
    describe 'basic usage' do
      let(:content_type_str) { 'application/foo; charset="utf-8"; foo=bar' }
      it('parses') do
        assert_equal({'charset' => 'utf-8', 'foo' => 'bar'}, content_type.parameters)
      end
    end
    describe 'params with capitalization' do
      let(:content_type_str) { 'application/foo; Charset="utf-8"; FOO=bar' }
      it('parses') do
        assert_equal({'charset' => 'utf-8', 'foo' => 'bar'}, content_type.parameters)
        assert_equal('utf-8', content_type.parameters['CharSet'])
        assert_equal('utf-8', content_type.parameters['Charset'])
        assert_equal('bar', content_type.parameters['foo'])
        assert_equal('bar', content_type.parameters['FOO'])
      end
    end
    describe 'repeated params' do
      let(:content_type_str) { 'application/foo; foo="first"; foo=second' }
      it('will just overwrite') do
        assert_equal({'foo' => 'second'}, content_type.parameters)
      end
    end
    describe 'repeated params, different capitalization' do
      let(:content_type_str) { 'application/foo; FOO=first; Foo=second' }
      it('will just overwrite') do
        assert_equal({'foo' => 'second'}, content_type.parameters)
      end
    end
    describe 'empty strings' do
      let(:content_type_str) { 'application/foo; empty1=; empty2=""' }
      it('parses') do
        assert_equal({'empty1' => '', 'empty2' => ''}, content_type.parameters)
      end
    end
    describe 'empty strings with whitespace' do
      let(:content_type_str) { 'application/foo; empty1=  ; empty2=""   ' }
      it('parses') do
        assert_equal({'empty1' => '', 'empty2' => ''}, content_type.parameters)
      end
    end
    describe('[invalid] opening quote only') do
      let(:content_type_str) { 'application/foo; foo=1; bar="' }
      it('parses') do
        assert_equal({'foo' => '1', 'bar' => ''}, content_type.parameters)
      end
    end
    describe('[invalid] backlash with no character') do
      let(:content_type_str) { 'application/foo; foo=1; bar="\\' }
      it('parses') do
        assert_equal({'foo' => '1', 'bar' => ''}, content_type.parameters)
      end
    end
    describe('[invalid] extra following quoted string') do
      let(:content_type_str) { 'application/foo; foo="1" 2; bar=3' }
      it('sorta parses') do
        assert_equal({'foo' => '1 2', 'bar' => '3'}, content_type.parameters)
      end
    end
    describe('[invalid] quotes silliness') do
      let(:content_type_str) { 'application/foo; foo="1" 2 "3 4" "5 "  ; bar=3' }
      it('sorta parses') do
        assert_equal({'foo' => '1 2 3 4 5 ', 'bar' => '3'}, content_type.parameters)
      end
    end
    describe('[invalid] backlash quote') do
      let(:content_type_str) { 'application/foo; foo=1; bar="\\"' }
      it('parses') do
        assert_equal({'foo' => '1', 'bar' => '"'}, content_type.parameters)
      end
    end
    describe('[invalid] trailing ;') do
      let(:content_type_str) { 'application/foo; foo=bar;' }
      it('parses') do
        assert_equal({'foo' => 'bar'}, content_type.parameters)
      end
    end
    describe('[invalid] extra ; inline') do
      let(:content_type_str) { 'application/foo; ; ; foo=bar' }
      it('parses') do
        assert_equal({'foo' => 'bar'}, content_type.parameters)
      end
    end
    describe('[invalid] whitespace around the =') do
      let(:content_type_str) { 'application/foo; foo = bar; baz = qux' }
      it('parses') do
        assert_equal({'foo ' => ' bar', 'baz ' => ' qux'}, content_type.parameters)
      end
    end
    describe('whitespace before the ;') do
      let(:content_type_str) { 'application/foo; foo=bar ; baz=qux' }
      it('parses') do
        assert_equal({'foo' => 'bar', 'baz' => 'qux'}, content_type.parameters)
      end
    end
    describe('no media_type') do
      let(:content_type_str) { '; foo=bar' }
      it('parses') do
        assert_equal({'foo' => 'bar'}, content_type.parameters)
      end
    end
    describe('[invalid] quote in parameter name') do
      let(:content_type_str) { 'application/foo; fo"o=bar' }
      it('gives up') do
        assert_equal({}, content_type.parameters)
      end
    end
    describe('[invalid] backslash in parameter name') do
      let(:content_type_str) { 'application/foo; fo\\o=bar' }
      it('parses') do
        assert_equal({'fo\\o' => 'bar'}, content_type.parameters)
      end
    end
  end
end
