require 'csv'

module Organizations
  class CreateOrUpdateTaxExemptOrganizationsFromCSV < ApplicationCommand
    BASE_DIR = Rails.root.join('db', 'tax_exempt_organizations')

    required do
      array :files, default: %w(eo1.csv.zip eo2.csv.zip eo3.csv.zip)
    end

    def execute
      ActiveRecord::Base.connection.execute <<-SQL
        DELETE FROM searchable_organizations;
        DROP INDEX IF EXISTS index_searchable_organizations_on_tsv;
        ALTER TABLE searchable_organizations DROP COLUMN IF EXISTS tsv;
      SQL

      puts "Importing searchable organizations from IRS Exempt Organizations Business Master File Extract (EO BMF)"

      files.each do |zipped_csv_file|
        import_searchable_organizations_from_zipped_csv(zipped_csv_file)
      end
      puts "Imported #{SearchableOrganization.count} searchable organizations"

      ActiveRecord::Base.connection.execute <<-SQL
        ALTER TABLE searchable_organizations ADD COLUMN tsv tsvector;
        UPDATE searchable_organizations SET tsv=to_tsvector('pg_catalog.english', coalesce(name,''));
        CREATE INDEX index_searchable_organizations_on_name_tsv ON searchable_organizations USING gin(tsv);
      SQL

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
