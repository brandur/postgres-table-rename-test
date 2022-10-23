Sequel.migration do
  up do
    run <<~EOS
      ALTER TABLE chainwheel 
          RENAME TO sprocket;

      CREATE VIEW chainwheel AS
          SELECT *
          FROM sprocket;
    EOS
  end

  down do
    run <<~EOS
      DROP VIEW chainwheel;

      ALTER TABLE sprocket 
          RENAME TO chainwheel;
    EOS
  end
end