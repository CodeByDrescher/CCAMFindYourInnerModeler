require 'test_helper'

class AssetButtonsTest < ActionDispatch::IntegrationTest

  include HtmlHelper

  ASSETS = %w(investigations studies assays data_files models sops strains presentations events)
  def setup
    User.current_user = Factory(:user, login: 'test')
    @current_user = User.current_user
    post '/session', login: 'test', password: 'blah'
    stub_request(:head, 'http://somewhere.com/piccy.pdf').to_return(status: 404)
    stub_request(:head, 'http://www.abc.com/').to_return(status: 404)
    stub_request(:head, 'http://somewhere.com/piccy_no_copy.pdf').to_return(status: 404)
  end

  test 'show delete' do
    ASSETS.each do |type_name|
      if type_name == 'assays'
        contributor = @current_user.person
        human_name = I18n.t('assays.modelling_analysis').humanize
      else
        contributor = @current_user
        human_name = type_name.singularize.humanize
      end
      item = Factory(type_name.singularize.to_sym, contributor: contributor,
                                                   policy: Factory(:all_sysmo_viewable_policy))
      assert item.can_delete?, 'This item is deletable for the test to pass'

      get "/#{type_name}/#{item.id}"
      assert_response :success
      assert_select '#buttons' do
        assert_select 'a', text: /Delete #{human_name}/i
      end

      delete "/#{type_name}/#{item.id}"
      assert_redirected_to eval("#{type_name}_path"), 'Should redirect to index page after deleting'
      assert_nil flash[:error]
    end
  end

  test 'configurable showing as external link when there is no local copy' do
    pdf_blob_with_local_copy_attrs = Factory(:content_blob, url: 'http://somewhere.com/piccy.pdf', uuid: UUID.generate, data: File.new("#{Rails.root}/test/fixtures/files/a_pdf_file.pdf", 'rb').read)
    pdf_blob_without_local_copy_attrs = Factory(:content_blob, data: nil, url: 'http://somewhere.com/piccy_no_copy.pdf', uuid: UUID.generate)
    html_blob_attrs = Factory(:content_blob, data: nil, url: 'http://www.abc.com', uuid: UUID.generate)

    Seek::Util.inline_viewable_content_types.each do |klass|
      underscored_type_name = klass.name.underscore
      human_name = klass.name.humanize

      with_config_value :show_as_external_link_enabled, true do
        if Seek::Util.is_multi_file_asset_type? klass
          item = Factory(underscored_type_name.to_sym, policy: Factory(:all_sysmo_downloadable_policy),
                         content_blobs: [pdf_blob_with_local_copy_attrs])
          assert_download_button "/#{underscored_type_name.pluralize}/#{item.id}", human_name

          item2 = Factory(underscored_type_name.to_sym, policy: Factory(:all_sysmo_downloadable_policy),
                          content_blobs: [pdf_blob_without_local_copy_attrs])
          assert_link_button "/#{underscored_type_name.pluralize}/#{item2.id}"

          item3 = Factory(underscored_type_name.to_sym, policy: Factory(:all_sysmo_downloadable_policy),
                          content_blobs: [pdf_blob_with_local_copy_attrs, pdf_blob_without_local_copy_attrs])
          assert_download_button "/#{underscored_type_name.pluralize}/#{item3.id}", human_name

          item4 = Factory(underscored_type_name.to_sym, policy: Factory(:all_sysmo_downloadable_policy),
                          content_blobs: [html_blob_attrs, pdf_blob_without_local_copy_attrs])
          assert_neither_download_nor_link_button "/#{underscored_type_name.pluralize}/#{item4.id}", human_name

        else
          item = Factory(underscored_type_name.to_sym, policy: Factory(:all_sysmo_downloadable_policy),
                         content_blob: pdf_blob_with_local_copy_attrs)
          assert_download_button "/#{underscored_type_name.pluralize}/#{item.id}", human_name

          item2 = Factory(underscored_type_name.to_sym, policy: Factory(:all_sysmo_downloadable_policy),
                          content_blob: html_blob_attrs)
          assert_link_button "/#{underscored_type_name.pluralize}/#{item2.id}"

          item3 = Factory(underscored_type_name.to_sym, policy: Factory(:all_sysmo_downloadable_policy),
                          content_blob: pdf_blob_without_local_copy_attrs)
          assert_link_button "/#{underscored_type_name.pluralize}/#{item3.id}"
        end
      end
    end
  end

  private

  def create_content_blobs(asset, multi_attrs)
    asset.content_blobs.clear
    multi_attrs.each do |attrs|
      asset.content_blobs.create attrs
    end
  end

  def assert_neither_download_nor_link_button(path, _human_name)
    get path
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a', text: 'Download', count: 0
      assert_select 'a', text: 'External Link', count: 0
    end
  end

  def assert_link_button(path)
    assert_action_button path, 'External Link'
  end

  def assert_download_button(path, _human_name)
    assert_action_button path, 'Download'
  end

  def assert_action_button(path, text)
    get path
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a', { text: text }, "Couldn't find '#{text}' button at #{path}"
    end
  end
end
