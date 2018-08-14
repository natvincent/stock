unit Stock.DomainQueries;

interface

const

  CStockListItemSelect =
               'select'
    + #13#10 + '  s.StockItemID,'
    + #13#10 + '  s.ProductID,'
    + #13#10 + '  s.Name,'
    + #13#10 + '  s.Description,'
    + #13#10 + '  sl.StockLevelID,'
    + #13#10 + '  sl.OnHand,'
    + #13#10 + '  sl.DateTime as LastChanged'
    + #13#10 + 'from'
    + #13#10 + '  Stock s'
    + #13#10 + '  left join ('
    + #13#10 + '    select'
    + #13#10 + '      StockLevelID,'
    + #13#10 + '      StockItemID,'
    + #13#10 + '      OnHand,'
    + #13#10 + '      DateTime'
    + #13#10 + '    from'
    + #13#10 + '      StockLevels sl1'
    + #13#10 + '      join ('
    + #13#10 + '        select'
    + #13#10 + '          Max(StockLevelID) as MaxStockLevelID'
    + #13#10 + '        from'
    + #13#10 + '          StockLevels'
    + #13#10 + '        group by'
    + #13#10 + '          StockItemID'
    + #13#10 + '      ) sl2 on sl1.StockLevelID = sl2.MaxStockLevelID'
    + #13#10 + '  ) sl on s.StockItemID = sl.StockItemID';

  CStockItemsOnHand =
               'select'
    + #13#10 + '  StockItemID,'
    + #13#10 + '  OnHand'
    + #13#10 + 'from'
    + #13#10 + '  StockLevels sl'
    + #13#10 + '  join ('
    + #13#10 + '    select'
    + #13#10 + '      Max(StockLevelID) as MaxStockLevelID'
    + #13#10 + '    from'
    + #13#10 + '      StockLevels'
    + #13#10 + '    where'
    + #13#10 + '      StockItemID = :StockItemID'
    + #13#10 + '  ) sl1 on sl.StockLevelID = sl1.MaxStockLevelID';

implementation

end.
