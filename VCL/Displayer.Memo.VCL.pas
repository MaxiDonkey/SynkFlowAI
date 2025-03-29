unit Displayer.Memo.VCL;

interface

uses
  System.SysUtils, System.Classes, Winapi.Messages, Winapi.Windows, Vcl.StdCtrls,
  Vcl.Controls, Manager.Intf;

type
  TMemoDisplayerVCL = class(TInterfacedObject, IDisplayer)
  private
    FMemo: TMemo;
    FStreamContent: string;
  protected
    function Display(const AText: string): string;
    function DisplayStream(const AText: string): string;
    procedure ScrollToEnd;
    procedure ScrollToTop;
    procedure Clear;
    procedure ClearStream;
  public
    constructor Create(AMemo: TMemo);
  end;

implementation

{ TMemoDisplayerVCL }

procedure TMemoDisplayerVCL.Clear;
begin
  FMemo.Clear;
  ClearStream;
end;

procedure TMemoDisplayerVCL.ClearStream;
begin
  FStreamContent := EmptyStr;
end;

constructor TMemoDisplayerVCL.Create(AMemo: TMemo);
begin
  inherited Create;
  FMemo := AMemo;
end;

function TMemoDisplayerVCL.Display(const AText: string): string;
begin
  Result := AText;
  if not Assigned(FMemo) then
    Exit;

  var Lines := AText.Split([sLineBreak, #10]);
  if Length(Lines) > 0 then
    begin
      for var L in Lines do
        FMemo.Lines.Add(L);
    end
  else
    begin
      FMemo.Lines.Add(AText);
    end;
  FMemo.Perform(WM_VSCROLL, SB_BOTTOM, 0);
end;

function TMemoDisplayerVCL.DisplayStream(const AText: string): string;
var
  CurrentLine: string;
  Lines: TArray<string>;
  OldSelStart: Integer;
  ShouldScroll: Boolean;
begin
  FStreamContent := FStreamContent + AText;
  Result := FStreamContent;
  if not Assigned(FMemo) then
    Exit;

  OldSelStart := FMemo.SelStart;
  ShouldScroll := (OldSelStart = FMemo.GetTextLen);

  FMemo.Lines.BeginUpdate;
  try
    Lines := AText.Split([sLineBreak, #10]);
    if System.Length(Lines) > 0 then
    begin
      if FMemo.Lines.Count > 0 then
        CurrentLine := FMemo.Lines[FMemo.Lines.Count - 1]
      else
        CurrentLine := '';

      {--- We concatenate the first part on the last line }
      CurrentLine := CurrentLine + Lines[0];
      if FMemo.Lines.Count > 0 then
        FMemo.Lines[FMemo.Lines.Count - 1] := CurrentLine
      else
        FMemo.Lines.Add(CurrentLine);

      {--- Other elements in new lines }
      for var i := 1 to High(Lines) do
        FMemo.Lines.Add(Lines[i]);
    end;
  finally
    FMemo.Lines.EndUpdate;
  end;

  if ShouldScroll then
  begin
    FMemo.SelStart := FMemo.GetTextLen;
    FMemo.SelLength := 0;
    FMemo.Perform(EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TMemoDisplayerVCL.ScrollToEnd;
begin
  FMemo.Perform(WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TMemoDisplayerVCL.ScrollToTop;
begin
  FMemo.Perform(WM_VSCROLL, SB_TOP, 0);
end;

end.
