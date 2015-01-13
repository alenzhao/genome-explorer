class String
  def complement
    self.tr('GATCgatc', 'CTAGctag')
  end
end

class Feature < ActiveRecord::Base
  belongs_to :scaffold
  belongs_to :genome

  has_many :protein_relationships, dependent: :destroy
  has_many :related_features, through: :protein_relationships

  has_many :inverse_protein_relationships, class_name: 'ProteinRelationship',
    foreign_key: :related_feature_id

  has_many :inverse_related_features, through: :inverse_protein_relationships,
    source: :feature

  # for now I am only going to call AAs "weird" if they have gaps
  # xxx this needs to be better defined with some biological background
  # xxx need to verify that the start codon makes sense
  def weird?
    self.protein_sequence[1..-2].include? '*'
  end

  def sequence
    i =  -1 + self.start
    j = -1 + self.stop
    seq =  self.scaffold.sequence[i..j]
    if strand == '-'
      seq = seq.reverse.complement
    end
    seq
  end

  # xxx real slow!
  def protein_sequence
    # create a new nucleotide sequence, translate it.
    # do NOT use 'auto' as it will sometimes mistake nucleotide for
    # amino acid
    Bio::Sequence::NA.new(self.sequence).translate # remove stop codon
  end

  def product
    self.info.match(/product=([^;]*);/)[1] rescue 'NA'
  end

end
