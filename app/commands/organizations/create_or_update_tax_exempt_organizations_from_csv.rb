require 'csv'

module Organizations
  class CreateOrUpdateTaxExemptOrganizationsFromCSV < ApplicationCommand
    BASE_DIR = Rails.root.join('db', 'tax_exempt_organizations')

    required do
      array :files, default: %w(eo1.csv.zip eo2.csv.zip eo3.csv.zip)
    end

    def execute
      puts "Importing searchable organizations from IRS Exempt Organizations Business Master File Extract (EO BMF)"

      files.each do |zipped_csv_file|
        import_searchable_organizations_from_zipped_csv(zipped_csv_file)
      end
      puts "Imported #{SearchableOrganization.count} searchable organizations"

      SearchableOrganization.reindex
      puts "Indexed #{SearchableOrganization.count} searchable organizations"
      
      nil
    end

    private

    def import_searchable_organizations_from_zipped_csv(zipped_csv_file)
      %x{ unzip -o #{BASE_DIR.join(zipped_csv_file)} -d /tmp }
      unzipped_csv = "/tmp/#{zipped_csv_file.gsub('.zip', '')}"
      import_searchable_organizations_from_csv(unzipped_csv)
    end

    def import_searchable_organizations_from_csv(path)
      File.open(path, 'r') do |io|
        connection = ActiveRecord::Base.connection
        connection.raw_connection.copy_data %{COPY searchable_organizations FROM STDIN CSV HEADER} do
          while line = io.gets do
            next if line.strip.size == 0
            connection.raw_connection.put_copy_data line
          end
        end
      end
    end

    def execute_sql(sql)
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
