class UpdateGenomeRelationshipsPipelineJob
  def perform
    ActiveRecord::Base.transaction {
      # start fresh each time
      ProteinRelationship.destroy_all
      GenomeRelationship.destroy_all
      DumpProteinsToFileJob.new('proteins.fasta').perform
      FindRelatedProteinsJob.new.perform
      FindRelatedGenomesJob.new.peform
    }
  end

  def max_run_time
    60 * 60 * 12 # 12 hours in seconds
  end
end
