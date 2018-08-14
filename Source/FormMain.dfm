object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Stock'
  ClientHeight = 411
  ClientWidth = 711
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  PixelsPerInch = 96
  TextHeight = 13
  object StockTree: TVirtualStringTree
    Left = 0
    Top = 26
    Width = 711
    Height = 385
    Align = alClient
    Header.AutoSizeIndex = 2
    Header.Font.Charset = DEFAULT_CHARSET
    Header.Font.Color = clWindowText
    Header.Font.Height = -11
    Header.Font.Name = 'Tahoma'
    Header.Font.Style = []
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    PopupMenu = Popup
    TabOrder = 0
    TreeOptions.PaintOptions = [toHideFocusRect, toShowDropmark, toShowRoot, toShowVertGridLines, toThemeAware, toUseBlendedImages, toFullVertGridLines, toUseBlendedSelection]
    TreeOptions.SelectionOptions = [toFullRowSelect, toRightClickSelect]
    OnBeforeItemErase = StockTreeBeforeItemErase
    OnDblClick = EditItemActionExecute
    OnGetText = StockTreeGetText
    OnInitNode = StockTreeInitNode
    ExplicitTop = 23
    ExplicitHeight = 388
    Columns = <
      item
        Position = 0
        Width = 66
        WideText = 'On Hand'
      end
      item
        Position = 1
        Width = 86
        WideText = 'Product ID'
      end
      item
        Position = 2
        Width = 181
        WideText = 'Name'
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coSmartResize, coAllowFocus, coEditable]
        Position = 3
        Width = 374
        WideText = 'Description'
      end>
  end
  object ActionToolBar1: TActionToolBar
    Left = 0
    Top = 0
    Width = 711
    Height = 26
    ActionManager = ActionManager
    Caption = 'ActionToolBar1'
    Color = clMenuBar
    ColorMap.DisabledFontColor = 7171437
    ColorMap.HighlightColor = clWhite
    ColorMap.BtnSelectedFont = clBlack
    ColorMap.UnusedColor = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Spacing = 0
    ExplicitHeight = 23
  end
  object ActionManager: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Action = AddItemAction
            Caption = '&Add Item'
            ImageIndex = 0
          end
          item
            Action = EditItemAction
            Caption = '&Edit Item'
            ImageIndex = 1
          end
          item
            Action = StockHistoryAction
            Caption = '&Stock History'
            ImageIndex = 2
          end>
        ActionBar = ActionToolBar1
      end>
    Images = ButtonImages
    Left = 32
    Top = 48
    StyleName = 'Platform Default'
    object AddItemAction: TAction
      Caption = 'Add Item'
      ImageIndex = 0
      OnExecute = AddItemActionExecute
    end
    object EditItemAction: TAction
      Caption = 'Edit Item'
      ImageIndex = 1
      OnExecute = EditItemActionExecute
      OnUpdate = EditItemActionUpdate
    end
    object StockHistoryAction: TAction
      Caption = 'Stock History'
      ImageIndex = 2
      OnExecute = StockHistoryActionExecute
      OnUpdate = StockHistoryActionUpdate
    end
  end
  object Popup: TPopupActionBar
    Left = 352
    Top = 208
    object AddItem1: TMenuItem
      Action = AddItemAction
    end
    object EditItem1: TMenuItem
      Action = EditItemAction
    end
    object StockHistory1: TMenuItem
      Action = StockHistoryAction
    end
  end
  object ButtonImages: TPngImageList
    PngImages = <
      item
        Background = clWindow
        Name = 'plus'
        PngImage.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000000473424954080808087C086488000000097048597300000EC400000E
          C401952B0E1B0000001974455874536F667477617265007777772E696E6B7363
          6170652E6F72679BEE3C1A000000284944415478DA6364A0103012906F40A347
          0DA0A501B8143840E903B82CA09A01031F06A3065000006C781011EC00A15F00
          00000049454E44AE426082}
      end
      item
        Background = clWindow
        Name = 'edit'
        PngImage.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000000473424954080808087C086488000000097048597300000EC400000E
          C401952B0E1B0000001974455874536F667477617265007777772E696E6B7363
          6170652E6F72679BEE3C1A000000B24944415478DA6364201E3800F12A200E03
          E203304146123577037129B221C418600BC4DB80B80E88FB81D80688D7027124
          10EF23640048F31A206E05E26A98266443F01980EE67149BA15E29C56500CC66
          9862188019D206C455B85C804B330CE441BDE48F2D0C0869C69067A44433B201
          64698619801ECF248509C880AF405C01C4355814A14725033603FE4369F47826
          E42D0C031818B0C4333ECDD80C00019478662000600620836F40EC8DCBCFE800
          00A5053E7FB99D79490000000049454E44AE426082}
      end
      item
        Background = clWindow
        Name = 'history'
        PngImage.Data = {
          89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
          610000000473424954080808087C086488000000097048597300000EC400000E
          C401952B0E1B0000001974455874536F667477617265007777772E696E6B7363
          6170652E6F72679BEE3C1A0000002C4944415478DA6364A0103052CB800620AE
          27516F23481FD55C30EA85512F0C0E2F54433129A01584297601000CED0A1111
          D7A2160000000049454E44AE426082}
      end>
    Left = 504
    Top = 96
    Bitmap = {}
  end
end
