class PullGenomeFromFilesJob

  def initialize id, kwargs = {}
    @id = id
    @genome = Genome.find(@id)
  end

  def perform
    dir = Dir.mktmpdir @genome.assembly_id.to_s
    # change dir in a BLOCK to return to previous working directory
    Dir.chdir dir do
      @genome = Genome.find(@id)
      Genome.transaction {
        self.import_from_files(@genome.gff_file, @genome.fna_file)
        @genome.save!
      }
    end
  end

  def import_from_files gff_path, fna_path
    # has to be loaded before features so that features can reference a
    # scaffold
    read_scaffolds(fna_path).each_slice(10) do |scaffolds|
      scaffolds.map! { |x| x.genome = @genome; x }
      Scaffold.import scaffolds
    end

    # has to be loaded after scaffolds
    read_features(gff_path).each_slice(1_000) do |features|
      features.map! { |x| x.genome = @genome; x }
      Feature.import features
    end
  end

  #
  # Return an array of (unsaved) Scaffolds with sequence and scaffold_names
  #
  def read_scaffolds path
    File.open(path) do |handle|
      Dna.new(handle, format: :fasta).map do |record|
        Scaffold.new(sequence: record.sequence, scaffold_name: record.name.split.first)
      end
    end
  end

  #
  # Return an array of (unsaved) Features with attributes from specified GFF file.
  #
  def read_features path
    # memoize scaffold lookup
    scaffolds = Hash.new { |h,k| h[k] = Scaffold.find_by_scaffold_name(k) }
    File.open(path) do |handle|
      handle.map do |line|
        next if line =~ /^#/
        dat = parse_gff(line)
        scaffold = scaffolds[dat['scaffold_name']]
        Feature.new(dat.slice(*Feature.column_names).merge(scaffold: scaffold))
      end.compact
    end
  end

  #
  # Parse a GFF-formatted line, return a hash with column names as keys
  # and column values as values.
  #
  def parse_gff(line)
    fields = line.strip.split("\t")

    scaffold_name = String fields[0]
    source        = String fields[1]
    feature_type  = String fields[2]
    start         = Integer fields[3] rescue nil
    stop          = Integer fields[4] rescue nil
    score         = Float fields[5] rescue nil
    strand        = String fields[6]
    frame         = Integer fields[7] rescue nil
    info          = String fields[8]

    { 'scaffold_name' => scaffold_name,
      'start'         => start,
      'source'        => source,
      'stop'          => stop,
      'strand'        => strand,
      'score'         => score,
      'feature_type'  => feature_type,
      'info'          => info }

  end

end
