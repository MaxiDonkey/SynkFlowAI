unit Displayer.Edge.VCL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.JSON,
  Winapi.WebView2, Winapi.ActiveX, Vcl.Edge, Manager.Intf;

type
  TEdgeDisplayerVCL = class(TInterfacedObject, IDisplayer)
  private
    FBrowser: TEdgeBrowser;
    FBrowserInitialized: Boolean;
    FMarkDown: IMarkDown;
    FStreamContent: string;
    function EscapeJSString(const S: string): string;
  protected
    procedure DoNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS); virtual;
  public
    function Display(const AText: string): string;
    function DisplayStream(const AText: string): string;
    procedure ClearStream;
    procedure ScrollToEnd;
    procedure ScrollToTop;
    procedure Clear;
    constructor Create(const ABrowser: TEdgeBrowser; const AMarkDown: IMarkDown);
  end;

implementation

{ TEdgeDisplayerVCL }

procedure TEdgeDisplayerVCL.Clear;
begin
  ClearStream;
  DisplayStream(EmptyStr);
end;

procedure TEdgeDisplayerVCL.ClearStream;
begin
  FStreamContent := EmptyStr;
end;

constructor TEdgeDisplayerVCL.Create(const ABrowser: TEdgeBrowser; const AMarkDown: IMarkDown);
begin
  inherited Create;
  FBrowser := ABrowser;
  FMarkDown := AMarkDown;
  FBrowser.OnNavigationCompleted := DoNavigationCompleted;
  FBrowser.Navigate('about:blank');
end;

function TEdgeDisplayerVCL.Display(const AText: string): string;
begin
  Result := (AText + sLineBreak + sLineBreak).Replace(sLineBreak, '<br>');

  FStreamContent := FStreamContent + Result;

  {--- Process all accumulated content to achieve a consistent rendering }
  var fullContent := FMarkDown.process(Result);

  {--- Properly escape the string to insert it into the JS script }
  var JsonString := EscapeJSString(fullContent);

  {--- Update the entire contents of the "ResponseContent" container }
  var script := Format('document.getElementById("ResponseContent").insertAdjacentHTML("beforeend", %s);', [JsonString]);

  FBrowser.ExecuteScript(script);

  ScrollToEnd;
end;

function TEdgeDisplayerVCL.DisplayStream(const AText: string): string;
begin
  FStreamContent := FStreamContent + AText;
  Result := FStreamContent;

  {--- Process all accumulated content to achieve a consistent rendering }
  var fullContent := FMarkDown.process(Result);

  {--- Properly escape the string to insert it into the JS script }
  var JsonString := EscapeJSString(fullContent);

  {--- Update the entire contents of the "ResponseContent" container }
  var script := Format('document.getElementById("ResponseContent").innerHTML = %s;', [JsonString]);

  FBrowser.ExecuteScript(script);

  ScrollToEnd;
end;

procedure TEdgeDisplayerVCL.ScrollToEnd;
begin
  FBrowser.ExecuteScript('window.scrollTo(0, document.body.scrollHeight);');
end;

procedure TEdgeDisplayerVCL.ScrollToTop;
begin
  FBrowser.ExecuteScript('window.scrollTo(0, 0);');
end;

procedure TEdgeDisplayerVCL.DoNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  if IsSuccess and not FBrowserInitialized then
    begin
      var initialHtml :=
        '<html>' +
          '<head>' +
            '<meta charset="UTF-8">' +
            '<style>' +
              'body { background-color: %s; font-family: "%s"; font-size: %d; color: %s; }' +
            '</style>' +
          '</head>' +
          '<body>' +
            '<div id="ResponseContent"></div>' +
          '</body>' +
        '</html>';
      initialHtml := Format(initialHtml, ['#202020', 'Segoe UI', 16, '#ECECEC']);
      FBrowser.NavigateToString(initialHtml);
      FBrowserInitialized := True;
    end;
end;

function TEdgeDisplayerVCL.EscapeJSString(const S: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '"';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    case c of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
    else
      if (Ord(c) < 32) or (Ord(c) > 126) then
        Result := Result + '\u' + IntToHex(Ord(c), 4)
      else
        Result := Result + c;
    end;
  end;
  Result := Result + '"';
end;

end.
