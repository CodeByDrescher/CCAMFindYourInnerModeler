require 'zip'
require 'datacite/acts_as_doi_mintable'

# Investigation "snapshot"
class Snapshot < ActiveRecord::Base

  belongs_to :resource, polymorphic: true
  has_one :content_blob, as: :asset, foreign_key: :asset_id

  before_create :set_snapshot_number

  # Must quack like an asset version to behave with DOI code
  alias_attribute :parent, :resource
  alias_attribute :parent_id, :resource_id
  alias_attribute :version, :snapshot_number

  validates :snapshot_number, :uniqueness => { :scope =>  [:resource_type, :resource_id] }

  acts_as_doi_mintable

  def manifest
    parse_manifest
  end

  def title
    research_object_metadata['title']
  end

  def description
    research_object_metadata['description']
  end

  def contributor
    Person.find(research_object_metadata['contributor']['uri'].match(/people\/([1-9][0-9]*)/)[1])
  end

  def research_object
    ROBundle::File.open(content_blob.filepath) do |ro|
      yield ro if block_given?
    end
  end

  private

  def set_snapshot_number
    self.snapshot_number ||= (resource.snapshots.maximum(:snapshot_number) || 0) + 1
  end

  def doi_resource_type
    resource_type.downcase
  end

  def doi_resource_id
    "#{resource_id}.#{snapshot_number}"
  end

  def doi_target_url
    investigation_snapshot_url(resource, snapshot_number, :host => DataCite::DoiMintable.host)
  end

  def research_object_metadata
    @ro_data ||= parse_manifest
  end

  def parse_manifest
    manifest = {}
    research_object do |ro|
      json = ro.read(File.join(resource.ro_package_path_fragment, 'metadata.json'))
      manifest = JSON.parse(json)
    end
    manifest
  end
end
