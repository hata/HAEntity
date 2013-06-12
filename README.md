# HAEntity

HAEntity is a library written by objective-c to access sqlite database via FMDB.

## Introduction

HAEntity is created to support easier access than writing all SQL. The purpose of this library is to help the following things:

- Each column maps to each property
- Reduce writing SQL.
- Map property types to database types.


## Usage

### Basic usage: Save
(ref HAEntityTests/HASampleTest testSample1 )

The basic step to use this library, initialize `HAEntityManager`, setup database,
and then use classes derived from HABaseEntity.

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

* Create a class which derived from HATableEntity.
* Add `+(NSString*) tableName` and return db's table name
* Add properties for each column

If `save` works well, you can get the added column using class methods.

    sample = [HASampleTestSample1 find_first];

You can confirm the returned instance have your saved information.

### Basic usage 2: Query
(ref HAEntityTests/HASampleTest testSample2 )

When query stored data, `[HABaseEntity where: params:]` can use to run query statement. When there are 10 rows and price column starts from 100 to 109.
If you would like to select less than 105, do like this:

    [HASampleTestSample1 where:@"price < ?" params:[NSNumber numberWithInt:105]]

The method returns NSArray instance. Each element is HASampleTestSample1 instance.
Right now, this library uses rowid returned by sqlite. The value can access `HATableEntity.rowid` property. It is a read only property.

`HABaseEntity` class defines class methods to run several queries.

- `[HABaseEntity select:]` creates after SELECT in SQL. You should set query string after "SELECT". If you run `[EntityClass select:@"name, details FROM sample1"]`, the method added "SELECT" before the query. So, it becomes like "SELECT name, details FROM table1".
- `[HABaseEntity where:]`  creates after WHERE in SQL. Like `[EntityClass where:"price = 100"]` is like "SELECT name, details, price FROM sample1 WHERE price = 100".
- `[HABaseEntity order_by:]` creates after ORDER BY in SQL. `[EntityClass order_by:@"price desc"]` becomes like "SELECT name, details, price FROM sample1 ORDER BY price desc".

select, where, and order_by methods may have `params` for query parameters. It can accept object only. So, number like NSInteger should not be set. These values should use NSNumber instead of it. The number of parameter instances should be the same number of '?' in literal. And the last element should be nil.


## License
  Apache 2.0


