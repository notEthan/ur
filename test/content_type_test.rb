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
  end
end
