require 'marples/model_action_broadcast'

class WholeEdition

  include Mongoid::Document
  include Mongoid::Timestamps
  include Marples::ModelActionBroadcast
  include Workflow
  include Searchable

	field :panopticon_id, :type => Integer
  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  field :overview, :type => String
  field :alternative_title, :type => String
  field :slug, :type => String
  field :section, :type => String
  field :department, :type => String
  field :rejected_count, :type => Integer, default: 0
  field :panopticon_id, :type => Integer
  field :tags, :type => String

  belongs_to :assigned_to, class_name: 'User'

  scope :lined_up,            where(state: 'lined_up')
  scope :draft,               where(state: 'draft')
  scope :amends_needed,       where(state: 'amends_needed')
  scope :in_review,           where(state: 'in_review')
  scope :fact_check,          where(state: 'fact_check')
  scope :fact_check_received, where(state: 'fact_check_received')
  scope :ready,               where(state: 'ready')
  scope :published,           where(state: 'published')
  scope :archived,            where(state: 'archived')
  scope :assigned_to,         lambda { |user| user.nil? ? where(:assigned_to_id.exists => false) : where(:assigned_to_id => user.id) }

  validates :title, presence: true
  validates :version_number, presence: true #, uniqueness: {:scope => :panopticon_id}
  validates :panopticon_id, presence: true

  index "assigned_to_id"
  index "panopticon_id"

  class << self; attr_accessor :fields_to_clone end
  @fields_to_clone = []

  alias_method :admin_list_title, :title

  def series
    WholeEdition.where(:panopticon_id => panopticon_id)
  end

  def siblings
    series.excludes(:id => id)
  end

  def previous_siblings
    siblings.where(:version_number.lt => version_number)
  end

  def subsequent_siblings
    siblings.where(:version_number.gt => version_number)
  end

  def latest_edition?
    subsequent_siblings.empty?
  end

  def published_edition
    series.where(state: 'published').order(version_number: 'desc').first
  end

  def meta_data
    PublicationMetadata.new self
  end

  def fact_check_email_address
    "factcheck+#{Plek.current.environment}-#{id}@alphagov.co.uk"
  end

  def build_clone
    new_edition = self.class.new(title: self.title, version_number: self.version_number + 1)
    real_fields_to_merge = self.class.fields_to_clone + [:panopticon_id, :overview, :alternative_title]

    real_fields_to_merge.each do |attr|
      new_edition.send("#{attr}=", read_attribute(attr))
    end

    new_edition
  end

  def self.create_from_panopticon_data(panopticon_id, importing_user)
    require 'gds_api/panopticon'
    api = GdsApi::Panopticon.new(Plek.current.environment)
    metadata = api.artefact_for_slug(panopticon_id)
    raise "Artefact not found" if metadata.nil?

    existing_publication = Edition.where(panopticon_id: panopticon_id).first
    return existing_publication if existing_publication

    importing_user.create_whole_edition(metadata.kind.to_sym, :panopticon_id => metadata.id, 
      :slug => metadata.slug, :title => metadata.name)
  end

  def self.find_and_identify(slug, edition)
    scope = where(slug: slug)

    if edition.present? and edition == 'latest'
      scope.order_by(:created_at => :desc).first
    elsif edition.present?
      scope.where(version_number: edition).first
    else
      scope.order_by(:created_at => :desc).where(state: 'published').first
    end
  end

  def panopticon_uri
    Plek.current.find("arbiter") + '/artefacts/' + (panopticon_id || slug).to_s
  end

  def format
    self.class.to_s.gsub('Edition', '')
  end

  def has_video?
    false
  end
  
  def safe_to_preview?
    true
  end
end