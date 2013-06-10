HAEntity
========

HAEntity is a library written by objective-c to access sqlite database via FMDB


Usage
-------

* Basic usage (ref HAEntityTests/HASampleTest testSample1 )
It is required to initialize `HAEntityManager`, setup database, and then use a class
derived from HABaseEntity.

    HAEntityManager* manager = [HAEntityManager instanceForPath:dbFilePath];

`dbFilePath` is a path for sqlite. You can use existing path or a new path.
`HAEntityManager` is used to access sqlite db via FMDB.

If there is no table, it is required to create a table. If you just want to test
this library, you can use the following quick way to do it.

    HATableEntityMigration* migration = [[HATableEntityMigration alloc]
        initWithVersion:1 entityClasses:[HASampleTestSample1 class], nil];
    [manager addEntityMigrating:migration];
    [manager upToHighestVersion];

`HATableEntityMigration` is used to create table based on a class
which derived from HABaseEntity(`HASampleTestSample1`). In this example,
sample1 table is created and the table have name, dtails, and price columns.
This library doesn't detect any added/removed columns and the table
is created with "IF NOT EXISTS". So, if you add new properties or remove
them, you should change tables.

Once you setup database, you can access the table using the entity class.

    HASampleTestSample1* sample = HASampleTestSample1.new;
    sample.name = @"sample";
    sample.details = @"testSample1 details";
    sample.price = 101;
    [sample save];

When you would like to add a new row to db, create a new instance, set
a new property, and then call `save` method for the instance.
The minimal requirement is

* add `+(NSString*) tableName` and return db's table name
* add properties for each column

If `save` works well, you can get the added column using class methods.

    sample = [HASampleTestSample1 find_first];

You can confirm the returned instance have your saved information.



* License
  Apache 2.0


