require 'rails_helper'

describe CreateGenomeAvatarJob do

  let(:genome) { create(:genome) }
  let(:create_genome_avatar_job) { CreateGenomeAvatarJob.new(genome.id) }

  it 'can be created' do
    expect(create_genome_avatar_job).to_not be(nil)
  end
  
  it 'can be run resulting in an avatar' do
    create_genome_avatar_job.perform
    # gotta reload genome after update :)
    expect(genome.reload.avatar.url).to_not be(nil)
  end

  it 'creates an file (image)' do
    create_genome_avatar_job.perform
    expect(File.exists?(genome.reload.avatar.url)).to_not be(false)
  end

  it 'creates an image'

end
