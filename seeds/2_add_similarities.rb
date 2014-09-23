require 'json'

namespace :seed do

  task :similarities do

    @neighbors = App::DB[:similarities]

    p @neighbors

    App::DB.transaction {

      # delete current relations!
      @neighbors.delete
        handle.each do |line|
          dat = JSON.parse(line)
          query = dat["query"]
          dat["hits"].each do |hit|
            
            @neighbors.insert(source_id: query, target_id: hit)
          end
        end
      end

    } # transaction


  end

end
