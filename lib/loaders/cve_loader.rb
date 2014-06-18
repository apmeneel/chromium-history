# Downloads and loads the CSV files of vulnerabilities and their associated review numbers

require "csv"
require "google_drive"

class CveLoader
  RESULTS_FILE = "#{Rails.configuration.datadir}/cves/cves.csv"

  def load_cve
    download_csv unless Rails.env == 'development' 
    parse_cves
    copy_to_db
  end
  
  # Sign into Google Docs 
  # username and password specified in credentials.yml
  def login
    google_creds_yml = YAML.load_file("#{Rails.root}/config/credentials.yml")['google-docs']
    GoogleDrive.login(google_creds_yml['user-name'], google_creds_yml['password'])
  end

  #Go out to Google Drive and download the sheet
  def download_csv
    File.delete(RESULTS_FILE) if File.exists?(RESULTS_FILE)
    session = login()
    spreadsheet = session.spreadsheet_by_key(Rails.configuration.google_spreadsheets['key'])
    spreadsheet.export_as_file(RESULTS_FILE, 'csv', Rails.configuration.google_spreadsheets['gid'])
  end

  def parse_cves
    uniqueCve = Set.new
    table = CSV.open "#{Rails.configuration.datadir}/tmp/cvenums.csv", 'w+'
    link = CSV.open "#{Rails.configuration.datadir}/tmp/code_reviews_cvenums.csv", 'w+'
    CSV.foreach(RESULTS_FILE, :headers => true) do | row |
      cve = row[0]
      issues = row[1].scan(/\d+/) #Mutliple code review ids split by non-numeric chars
      $stderr.puts "ERROR: CVE entry occurred twice: #{cve}" unless uniqueCve.add? cve
      $stderr.puts "ERROR: CVE #{cve} has no issues" if issues.empty?
      table << [cve]
      issues.each do |issue| 
        link << [cve, issue]
      end
    end
    table.fsync
    link.fsync
  end

  def copy_to_db
    datadir = File.expand_path(Rails.configuration.datadir)
    ActiveRecord::Base.connection.execute("COPY cvenums FROM '#{datadir}/tmp/cvenums.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute("COPY code_reviews_cvenums FROM '#{datadir}/tmp/code_reviews_cvenums.csv' DELIMITER ',' CSV")
    ActiveRecord::Base.connection.execute <<-EOSQL
      WITH issues AS ((SELECT code_review_id from code_reviews_cvenums) 
                    EXCEPT (SELECT issue FROM code_reviews)) 
          DELETE FROM code_reviews_cvenums 
      WHERE code_review_id IN (SELECT code_review_id FROM issues);
    EOSQL
  end
end
