class DeveloperSnapshot < ActiveRecord::Base

	def self.optimize
		connection.add_index :developer_snapshots, :dev_id
		connection.add_index :developer_snapshots, :degree
		connection.add_index :developer_shapshots, :participations
		connection.add_index :developer_snapshots, :own_count
		connection.add_index :developer_snapshots, :closeness
		connection.add_index :developer_snapshots, :betweenness
		connection.add_index :developer_snapshots, :sheriff_hrs
		connection.add_index :developer_snapshots, :has_sheriff_hrs		
		connection.add_index :developer_snapshots, :vuln_misses_1yr
		connection.add_index :developer_snapshots, :vuln_misses_6mo
		connection.add_index :developer_snapshots, :vuln_fixes_owned
		connection.add_index :developer_snapshots, :vuln_fixes
		connection.add_index :developer_snapshots, :perc_vuln_misses

		connection.add_index :developer_snapshots, :sec_exp
		connection.add_index :developer_snapshots, :bugsec_exp
		connection.add_index :developer_snapshots, :start_date
		connection.add_index :developer_snapshots, :end_date
		connection.execute 'CLUSTER developer_snapshots USING index_developer_snapshots_on_start'
	end
end
