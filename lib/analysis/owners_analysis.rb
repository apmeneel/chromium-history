require 'csv'

class OwnersAnalysis

  def populate_first_owners

    #First commit to directory date
    update_first_commit_date = <<-EOSQL
      UPDATE release_owners r
      SET first_dir_commit_date = own_data.min_date
      FROM  (SELECT ro.dev_id dv_id, ro.directory dir, MIN(c.created_at) min_date
             FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id
                                    INNER JOIN commit_filepaths cf ON cf.filepath LIKE ro.directory || '%' AND  cf.commit_hash = c.commit_hash
             GROUP BY ro.dev_id, ro.directory) own_data
      WHERE dev_id = own_data.dv_id AND directory = own_data.dir
    EOSQL

    update_first_commit_date2 = <<-EOSQL
      UPDATE release_owners r
      SET first_dir_commit_date = own_data.min_date
      FROM  (SELECT ro.dev_id dv_id, ro.directory dir, MIN(c.created_at) min_date
             FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id
                                    INNER JOIN commit_filepaths cf ON cf.filepath LIKE '%' AND  cf.commit_hash = c.commit_hash
             GROUP BY ro.dev_id, ro.directory) own_data
      WHERE dev_id = own_data.dv_id AND directory = './'
    EOSQL

    #First commit to directory hash
    update_first_commit_sha = <<-EOSQL
      UPDATE release_owners r
      SET first_dir_commit_sha = own_data.sha
      FROM  (SELECT ro.dev_id dv_id, ro.directory dir, c.commit_hash sha, c.created_at c_date
             FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id
                                    INNER JOIN commit_filepaths cf ON cf.filepath LIKE ro.directory || '%' AND  cf.commit_hash = c.commit_hash) own_data
      WHERE dev_id = own_data.dv_id AND directory = own_data.dir AND r.first_dir_commit_date = own_data.c_date
    EOSQL

    update_first_commit_sha2 = <<-EOSQL
      UPDATE release_owners r
      SET first_dir_commit_sha = own_data.sha
      FROM  (SELECT ro.dev_id dv_id, ro.directory dir, c.commit_hash sha, c.created_at c_date
             FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id
                                    INNER JOIN commit_filepaths cf ON cf.filepath LIKE '%' AND  cf.commit_hash = c.commit_hash) own_data
      WHERE dev_id = own_data.dv_id AND directory = './' AND r.first_dir_commit_date = own_data.c_date
    EOSQL

    #Number of commits before ownership
    update_commits_to_ownership = <<-EOSQL
      UPDATE release_owners r
      SET dir_commits_to_ownership = (SELECT SUM(case when own_data.c_date < r.first_ownership_date then 1 else 0 end)
                                      FROM  (SELECT ro.dev_id dv_id, ro.directory dir, c.commit_hash sha, c.created_at c_date
                                             FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id
                                                                    INNER JOIN commit_filepaths cf ON cf.filepath LIKE ro.directory || '%' AND  cf.commit_hash = c.commit_hash) own_data
                                      WHERE r.dev_id = own_data.dv_id AND r.directory = own_data.dir
                                      GROUP BY own_data.dv_id, own_data.dir)
    EOSQL

    update_commits_to_ownership2 = <<-EOSQL
      UPDATE release_owners r
      SET dir_commits_to_ownership = (SELECT SUM(case when own_data.c_date < r.first_ownership_date then 1 else 0 end)
                                      FROM  (SELECT ro.dev_id dv_id, ro.directory dir, c.commit_hash sha, c.created_at c_date
                                             FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id
                                                                    INNER JOIN commit_filepaths cf ON cf.filepath LIKE '%' AND  cf.commit_hash = c.commit_hash) own_data
                                      WHERE r.dev_id = own_data.dv_id AND r.directory = own_data.dir AND r.directory = './'
                                      GROUP BY own_data.dv_id, own_data.dir)
      WHERE directory = './'
    EOSQL

    #Number of commits before a release
    update_commits_to_release =  <<-EOSQL
      UPDATE release_owners r
      SET dir_commits_to_release = (SELECT SUM(case when own_data.cdate < own_data.reldate then 1 else 0 end)
                                    FROM  (SELECT ro.dev_id dv_id, ro.directory dir, ro.release ror, c.commit_hash sha, rel.date reldate, c.created_at cdate
                                           FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id
					                          INNER JOIN commit_filepaths cf ON cf.filepath LIKE ro.directory || '%' AND  cf.commit_hash = c.commit_hash
								  INNER JOIN releases rel ON ro.release = rel.name) own_data
                                    WHERE r.dev_id = own_data.dv_id AND r.directory = own_data.dir AND r.release = own_data.ror
                                    GROUP BY own_data.dv_id, own_data.dir, own_data.ror)
    EOSQL

    update_commits_to_release2 =  <<-EOSQL
      UPDATE release_owners r
      SET dir_commits_to_release = (SELECT SUM(case when own_data.cdate < own_data.reldate then 1 else 0 end)
                                    FROM  (SELECT ro.dev_id dv_id, ro.directory dir, ro.release ror, c.commit_hash sha, rel.date reldate, c.created_at cdate
				           FROM release_owners ro INNER JOIN commits c ON c.author_id = ro.dev_id
					                          INNER JOIN commit_filepaths cf ON cf.filepath LIKE '%' AND  cf.commit_hash = c.commit_hash
                                                                  INNER JOIN releases rel ON ro.release = rel.name) own_data
                                    WHERE r.dev_id = own_data.dv_id AND r.directory = own_data.dir AND r.directory = './' AND r.release = own_data.ror
                                    GROUP BY own_data.dv_id, own_data.dir, own_data.ror)
	WHERE directory = './'
    EOSQL


    Benchmark.bm(40) do |x|
      x.report("Executing update_first_commit_date: #{update_first_commit_date}") {ActiveRecord::Base.connection.execute update_first_commit_date}
      x.report("Executing update_first_commit_date2: #{update_first_commit_date2}") {ActiveRecord::Base.connection.execute update_first_commit_date2}
      x.report("Executing update_first_commit_sha: #{update_first_commit_sha}") {ActiveRecord::Base.connection.execute update_first_commit_sha}
      x.report("Executing update_first_commit_sha2: #{update_first_commit_sha2}") {ActiveRecord::Base.connection.execute update_first_commit_sha2}
      x.report("Executing update_commits_to_ownership: #{update_commits_to_ownership}") {ActiveRecord::Base.connection.execute update_commits_to_ownership}
      x.report("Executing update_commits_to_ownership2: #{update_commits_to_ownership2}") {ActiveRecord::Base.connection.execute update_commits_to_ownership2}
      x.report("Executing update_commits_to_release: #{update_commits_to_release}") {ActiveRecord::Base.connection.execute update_commits_to_release}
      x.report("Executing update_commits_to_release2: #{update_commits_to_release2}") {ActiveRecord::Base.connection.execute update_commits_to_release2}
    end

  end
end