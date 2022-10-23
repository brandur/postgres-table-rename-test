# postgres-table-rename-test

A small demo to show how to safely rename a table in Postgres even while having a live process reading and writing from it the whole time.

1. Raise initial schema:

    ``` sh
    dropdb --if-exists postgres-table-rename-test && createdb postgres-table-rename-test
    bundle exec sequel -m migrations/ -M 1 postgres://localhost:5432/postgres-table-rename-test
    ```

2. Start `app.rb` to insert and read out of the original `chainwheel` table name:

    ``` sh
    TABLE_NAME=chainwheel bundle exec ruby app.rb
    ```

3. Leaving `app.rb` running, run a migration that renames `chainwheel` to `sprocket`, but also creates an insertable view at the original name of `chainwheel`:

    ``` sqh
    bundle exec sequel -m migrations/ -M 2 postgres://localhost:5432/postgres-table-rename-test
    ```

    Renaming the table and creating the view happen atomically in a transaction, so to other processes there's never a moment where the table's been renamed but the new view isn't yet available.

    Note that despite the migration having run, the original `app.rb` has continued inserting to `chainwheel` happily and without issue.

4.  Now start a second process inserting to the new table name `sprocket`:

    ``` sh
    TABLE_NAME=sprocket bundle exec ruby app.rb
    ```

    Both the original `app.rb` and the new one continue without issue.

## Limitations of updatable views

1. Stop both `app.rb` processes from the first section.

2. Run migration that adds a new `NOT NULL` column to `sprocket` called `material`:

    ``` sh
    bundle exec sequel -m migrations/ -M 3 postgres://localhost:5432/postgres-table-rename-test
    ```

3. Run `app.rb` for the `sprocket` table (its new name) with an additional flag to include `material`, and notice that it runs fine:

    ``` sh
    TABLE_NAME=sprocket MATERIAL=steel bundle exec ruby app.rb
    ```

4. However, we can no longer succeed for the old `chainwheel` name because inserting to the view doesn't account for its parent's new `material` field:

    ``` sh
    TABLE_NAME=chainwheel bundle exec ruby app.rb
    ```

    ``` sql
    ERROR:  null value in column "material" of relation "sprocket" violates not-null constraint (PG::NotNullViolation)
    ```

    Trying to include `material` also doesn't work because it's not part of the view:

    ``` sh
    TABLE_NAME=chainwheel MATERIAL=steel bundle exec ruby app.rb
    ```

    ``` sql
    ERROR:  column "material" of relation "chainwheel" does not exist (PG::UndefinedColumn)
    LINE 1: ...NSERT INTO "chainwheel" ("diameter", "num_teeth", "material"...
    ```

The lesson here is that when renaming something, do it quickly, and clean up immediately: rename and create updatable view, restart all processes to use the old name, and drop the view. The longer it's around, the more likely you are to forget about it, and accidentally cause a production error somewhere down the line.