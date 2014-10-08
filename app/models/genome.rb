require 'json'
require 'tempfile'
require 'zlib'

class Genome < ActiveRecord::Base
  has_many :scaffolds
  has_many :features

  validates :assembly_id, numericality: { only_integer: true }, presence: true,
    uniqueness: true

  mount_uploader :avatar, AvatarUploader

  after_create do
    self.delay(queue: 'genome building').build
  end

  def build
    CreateGenomeAvatarJob.new(self.id).perform
    UpdateGenomeStatsJob.new(self.id).perform
    PullGenomeFromNCBIJob.new(self.id).perform
  end

  def self.search(search)
    if search
      where [ 'lower(organism) LIKE ?', "%#{search.downcase}%" ]
    else
      all
    end
  end

end
