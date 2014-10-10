class GenomeRelationshipsController < ApplicationController

  def index

    respond_to do |format|
      format.json do

        @min_related = Integer(params[:min_related] || 0)

        genome_relationships = GenomeRelationship.all
        genomes = Genome.where("(stats -> 'total_proteins')::int > 0")

        genomes_list = []

        nodes = genomes.map do |genome|
          genomes_list << genome.id
          { name: genome.organism, group: genome.organism.split[1] }
        end

        index = Hash[genomes_list.map.with_index.to_a] 

        links = genome_relationships.map do |rel|
          count = rel.related_features_count
          source = index[rel.genome_id]
          target = index[rel.related_genome_id]
          if count < @min_related
            nil
          elsif source.nil? or target.nil?
            nil
          else
            { source: source , target: target, value: count }
          end
        end.compact

        dat = { nodes: nodes, links: links }

        render json: dat
      end
      format.html {}
    end
  end

  def show
    @genome_relationship = GenomeRelationship.first
  end

end
