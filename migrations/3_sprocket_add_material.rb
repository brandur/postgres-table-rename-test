Sequel.migration do
  up do
    # We want to set this `NOT NULL` and _without_ a `DEFAULT` for purposes of
    # our demo, so this column is raised in three steps: the column is added, we
    # give existing data values, and then finally make it `NOT NULL`.
    run <<~EOS
      ALTER TABLE sprocket
          ADD COLUMN material text;
      UPDATE sprocket SET material = 'steel';
      ALTER TABLE sprocket
          ALTER COLUMN material SET NOT NULL;
    EOS
  end

  down do
    run <<~EOS
      ALTER TABLE sprocket
          DROP COLUMN material;
    EOS
  end
end