Sequel.migration do
  up do
    run <<~EOS
      CREATE TABLE chainwheel (
          id BIGSERIAL PRIMARY KEY,
          diameter integer NOT NULL,
          num_teeth integer NOT NULL
      );
    EOS
  end

  down do
    run <<~EOS
      DROP TABLE chainwheel;
    EOS
  end
end