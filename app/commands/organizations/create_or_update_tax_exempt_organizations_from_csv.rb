require 'csv'

module Organizations
  class CreateOrUpdateTaxExemptOrganizationsFromCSV < ApplicationCommand
    def execute
      delete_sql = "DELETE FROM searchable_organizations;"
      ActiveRecord::Base.connection.execute(delete_sql)

      import_searchable_organizations_from_zipped_csv('db/tax_exempt_organizations/eo1.csv.zip')
      import_searchable_organizations_from_zipped_csv('db/tax_exempt_organizations/eo2.csv.zip')
      import_searchable_organizations_from_zipped_csv('db/tax_exempt_organizations/eo3.csv.zip')

      nil
    end

    private

    def import_searchable_organizations_from_zipped_csv(zipped_csv_file)
      %x{ unzip -o #{zipped_csv_file} -d /tmp }
      unzipped_csv = "/tmp/#{zipped_csv_file.split('/').last.gsub('.zip', '')}"
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
  end
end
