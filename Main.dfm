object Form1: TForm1
  Left = 0
  Top = 0
  AlphaBlend = True
  AlphaBlendValue = 0
  Caption = 'Proof of concept'
  ClientHeight = 672
  ClientWidth = 1055
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    1055
    672)
  TextHeight = 21
  object EdgeBrowser1: TEdgeBrowser
    Left = 8
    Top = 248
    Width = 33
    Height = 380
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    AllowSingleSignOnUsingOSPrimaryAccount = False
    TargetCompatibleBrowserVersion = '117.0.2045.28'
    UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
  end
  object Memo1: TMemo
    Left = 54
    Top = 248
    Width = 713
    Height = 380
    Anchors = [akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Memo2: TMemo
    Left = 8
    Top = 8
    Width = 759
    Height = 217
    Anchors = [akLeft, akTop, akRight]
    Lines.Strings = (
      '')
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object Button1: TButton
    Left = 692
    Top = 639
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Button1'
    TabOrder = 3
  end
  object Panel1: TPanel
    Left = 773
    Top = 8
    Width = 282
    Height = 620
    Anchors = [akTop, akRight]
    BevelOuter = bvNone
    TabOrder = 4
    DesignSize = (
      282
      620)
    object Label1: TLabel
      Left = 0
      Top = 194
      Width = 273
      Height = 72
      AutoSize = False
      Caption = 
        'Write an article developing a complex chain of reasoning, while ' +
        'incorporating a web search conducted in parallel.'
      Layout = tlCenter
      WordWrap = True
    end
    object Button2: TButton
      Left = 64
      Top = 8
      Width = 210
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Single promise'
      TabOrder = 0
      OnClick = Button2Click
    end
    object Button4: TButton
      Left = 64
      Top = 104
      Width = 210
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Single parallel'
      TabOrder = 1
      OnClick = Button4Click
    end
    object Button3: TButton
      Left = 64
      Top = 272
      Width = 210
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Promises and pipeline'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Button5: TButton
      Left = 64
      Top = 135
      Width = 210
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Single parallel web search'
      TabOrder = 3
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 0
      Top = 8
      Width = 49
      Height = 25
      Caption = 'Txt1'
      TabOrder = 4
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 0
      Top = 104
      Width = 49
      Height = 25
      Caption = 'Txt2'
      TabOrder = 5
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 0
      Top = 135
      Width = 49
      Height = 25
      Caption = 'Txt3'
      TabOrder = 6
      OnClick = Button8Click
    end
    object Button9: TButton
      Left = 0
      Top = 272
      Width = 49
      Height = 25
      Caption = 'Txt4'
      TabOrder = 7
      OnClick = Button9Click
    end
    object Button10: TButton
      Left = 64
      Top = 39
      Width = 210
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Single chain promise'
      TabOrder = 8
      OnClick = Button10Click
    end
  end
end
