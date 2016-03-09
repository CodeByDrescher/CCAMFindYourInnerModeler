class SampleType < ActiveRecord::Base
  include SysMODB::SpreadsheetExtractor

  attr_accessible :title, :uuid, :sample_attributes_attributes

  acts_as_uniquely_identifiable

  has_many :samples

  has_many :sample_attributes, order: :pos, inverse_of: :sample_type

  belongs_to :content_blob
  alias_method :template, :content_blob

  validates :title, presence: true
  validate :validate_one_title_attribute_present, :validate_template_file

  accepts_nested_attributes_for :sample_attributes, allow_destroy: true

  def validate_value?(attribute_name, value)
    attribute = sample_attributes.detect { |attr| attr.title == attribute_name }
    fail UnknownAttributeException.new("Unknown attribute #{attribute_name}") if attribute.nil?
    attribute.validate_value?(value)
  end

  def build_from_template
    return unless compatible_template_file?
    sheet = find_sample_sheet
    fail 'no sheet' unless sheet
    fail 'no string attribute type' if default_attribute_type.nil?
    find_sample_column_names(sheet.attributes['index'])
  end

  def compatible_template_file?
    template && template.is_extractable_spreadsheet? && find_sample_sheet
  end

  private

  def clear_xml_cache
    @template_doc=nil
    @template_xml=nil
  end

  def find_sample_column_names(sheet_index)
    cells = template_xml_document.find("//ss:sheet[@index='#{sheet_index}']/ss:rows/ss:row[@index=1]/ss:cell")
    cells.each do |column_cell|
      unless (heading = column_cell.content).blank?
        is_title = sample_attributes.empty?
        column_index = column_cell.attributes['column']
        sample_attributes << SampleAttribute.new(title: heading,
                                                 sample_attribute_type: default_attribute_type,
                                                 is_title: is_title,
                                                 required: is_title,
                                                 template_column_index: column_index)
      end
    end
  end

  def default_attribute_type
    SampleAttributeType.primitive_string_types.first
  end

  def find_sample_sheet
    begin
      template_xml_document.find('//ss:sheet').select do |sheet|
        sheet.attributes['name'] =~ /.*samples.*/i
      end.last
    rescue
      nil
    end
  end

  def template_xml
    @template_xml ||= spreadsheet_to_xml(open(template.filepath))
  end

  def template_xml_document
    unless @template_doc
      @template_doc = LibXML::XML::Parser.string(template_xml).parse
      @template_doc.root.namespaces.default_prefix = 'ss'
    end
    @template_doc
  end

  def validate_one_title_attribute_present
    unless (count = sample_attributes.select(&:is_title).count) == 1
      errors.add(:sample_attributes, "There must be 1 attribute which is the title, currently there are #{count}")
    end
  end

  def validate_template_file
    if template && !compatible_template_file?
      errors.add(:template, "Not a valid template file")
    end
  end

  class UnknownAttributeException < Exception; end
end
