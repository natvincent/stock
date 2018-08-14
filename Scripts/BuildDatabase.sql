create table Stock (
  StockItemID integer primary key autoincrement,
  ProductID varchar(80),
  Name varchar(200),
  Description text
);

create table StockLevels (
  StockLevelID integer primary key autoincrement,
  StockItemID integer,
  OnHand integer,
  DateTime varchar(24) default current_timestamp 
);

insert into Stock (
  ProductID,
  Name,
  Description
) values (
  '123456789',
  'Plain Flour',
  'Plain white flour, 1kg'
),
(
  '987654321',
  'Raw Sugar',
  '1kg'
),
(
  '654987321',
  'Pickles',
  '350g jar'
);

insert into StockLevels (
  StockItemID,
  OnHand,
  DateTime
) values (
  1,
  25,
  '2018-08-13T0900'
),
(
  1,
  50,
  '2018-08-13T1000'
),
(
  2,
  37,
  '2018-08-13T0900'
),
(
  2,
  42,
  '2018-08-13T1130'
),
(
  3,
  100,
  '2018-08-13T0900'
),
(
  3,
  84,
  '2018-08-13T0945'
)