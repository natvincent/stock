object EditItemForm: TEditItemForm
  Left = 0
  Top = 0
  Anchors = [akRight, akBottom]
  Caption = 'Edit Item'
  ClientHeight = 214
  ClientWidth = 354
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCloseQuery = FormCloseQuery
  DesignSize = (
    354
    214)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 37
    Width = 31
    Height = 13
    Caption = 'Name:'
  end
  object Label2: TLabel
    Left = 8
    Top = 64
    Width = 57
    Height = 13
    Caption = 'Description:'
  end
  object Label3: TLabel
    Left = 8
    Top = 159
    Width = 46
    Height = 13
    Caption = 'On Hand:'
  end
  object Label5: TLabel
    Left = 8
    Top = 11
    Width = 55
    Height = 13
    Caption = 'Product ID:'
  end
  object NameEdit: TEdit
    Left = 81
    Top = 34
    Width = 265
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    MaxLength = 200
    TabOrder = 1
  end
  object DescriptionMemo: TMemo
    Left = 81
    Top = 61
    Width = 265
    Height = 89
    Anchors = [akLeft, akTop, akRight]
    Lines.Strings = (
      '')
    TabOrder = 2
  end
  object OnHandEdit: TEdit
    Left = 81
    Top = 156
    Width = 82
    Height = 21
    NumbersOnly = True
    TabOrder = 3
  end
  object OKButton: TButton
    Left = 190
    Top = 183
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
    ExplicitTop = 339
  end
  object CancelButton: TButton
    Left = 271
    Top = 183
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
    ExplicitTop = 339
  end
  object ProductIDEdit: TEdit
    Left = 81
    Top = 8
    Width = 265
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    MaxLength = 80
    TabOrder = 0
  end
end
