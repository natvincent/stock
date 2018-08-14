object StockHistoryForm: TStockHistoryForm
  Left = 0
  Top = 0
  Caption = 'Stock History'
  ClientHeight = 291
  ClientWidth = 298
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    298
    291)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 58
    Height = 13
    Caption = 'Product ID: '
  end
  object ProductIDLabel: TLabel
    Left = 72
    Top = 8
    Width = 57
    Height = 13
    Caption = '(product-id)'
  end
  object Label3: TLabel
    Left = 8
    Top = 31
    Width = 31
    Height = 13
    Caption = 'Name:'
  end
  object NameLabel: TLabel
    Left = 72
    Top = 31
    Width = 34
    Height = 13
    Caption = '(name)'
  end
  object StockLevelTree: TVirtualStringTree
    Left = 8
    Top = 54
    Width = 282
    Height = 195
    Anchors = [akLeft, akTop, akRight, akBottom]
    Header.AutoSizeIndex = 1
    Header.Font.Charset = DEFAULT_CHARSET
    Header.Font.Color = clWindowText
    Header.Font.Height = -11
    Header.Font.Name = 'Tahoma'
    Header.Font.Style = []
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    TabOrder = 0
    TreeOptions.PaintOptions = [toShowDropmark, toShowVertGridLines, toThemeAware, toUseBlendedImages]
    OnBeforeItemErase = StockLevelTreeBeforeItemErase
    OnGetText = StockLevelTreeGetText
    OnInitNode = StockLevelTreeInitNode
    Columns = <
      item
        Position = 0
        Width = 60
        WideText = 'On Hand'
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coSmartResize, coAllowFocus, coEditable]
        Position = 1
        Width = 218
        WideText = 'Date/Time'
      end>
  end
  object CloseButton: TButton
    Left = 215
    Top = 258
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Close'
    Default = True
    ModalResult = 8
    TabOrder = 1
  end
end
