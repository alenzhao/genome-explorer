class FindRelatedProteinsJob

  def initialize kwargs = {}

    defaults = {
      method: 'usearch',
      ncpu: 24,
      identity: '0.1',
      maxaccepts: 256,
      maxrejects: 512,
      input: 'proteins.fasta'
    }

    opts = defaults.update(kwargs)

    @method     = opts[:method]
    @ncpu       = opts[:ncpu]
    @identity   = opts[:identity]
    @maxaccepts = opts[:maxaccepts]
    @maxrejects = opts[:maxrejects]
    @input      = opts[:input]

  end

  # dump proteins to fasta file
  def perform
    run_usearch
    ProteinRelationship.transaction {
      build_relationships_from_blast_output
    }
  end

  def run_usearch
    # xxx make usearch a configuration item
    system %Q{#{@method}\
        -usearch_local #{@input} \
        -db #{@input} \
        -id #{@identity} \
        -blast6out proteins.blast6.tab \
        -threads #{@ncpu} \
        -maxaccepts #{@maxaccepts} \
        -maxrejects #{@maxrejects}}
  end

  def build_relationships_from_blast_output
    # todo allow for multiple types of proteinrelationships from different
    # sources.
    File.open('proteins.blast6.tab') do |handle|
      pbar = ProgressBar.new 'loading', File.size(handle.path)
      columns = [ :feature_id, :related_feature_id, :identity ]
      read_blast_file(handle).each_slice(10_000) do |values|
        pbar.set handle.pos
        ProteinRelationship.import columns, values, validate: false
      end
      pbar.finish
    end
  end

  def parse_blast_line line
    fields = line.strip.split("\t")
    # query, subject
    [ fields[0], # query id
      fields[1], # subject id
      (100 * Float(fields[2])).to_i # percent identity, rounded
    ]
  end

  def read_blast_file handle
    Enumerator.new do |enum|
      handle.each do |line|
        enum.yield parse_blast_line(line)
      end
    end
  end

  def queue_name
    'big'
  end

end
