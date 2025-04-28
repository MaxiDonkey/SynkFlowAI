unit Displayer.Edge.VCL;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.JSON,
  Winapi.WebView2, Winapi.ActiveX, Vcl.Edge, Manager.Intf, VCL.Clipbrd;

type
  TCopyActionType = procedure (Lang, Code: string) of object;

  TEdgeDisplayerVCL = class(TInterfacedObject, IDisplayer)
  private
    FBrowser: TEdgeBrowser;
    FInitialNavigation: Boolean;
    FBrowserInitialized: Boolean;
    FMarkDown: IMarkDown;
    FStreamContent: string;
    FOnCodeCopied: TCopyActionType;
    function EscapeJSString(const S: string): string;
    procedure CodeCopy(Lang, Code: string);
  protected
    procedure DoNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS); virtual;
    procedure DoWebMessageReceived(Sender: TCustomEdgeBrowser;
      Args: TWebMessageReceivedEventArgs);
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

const
  JS_TEMPLATE =
    '(() => {' +
    '  const md   = %s;' +
    '  const html = marked.parse(md);' +
    '  const root = document.getElementById("ResponseContent");' +
    '  root.innerHTML = html;' +

    '  document.querySelectorAll("pre > code[class^=''language-'']").forEach(codeEl => {' +
    '    const pre   = codeEl.parentNode;' +
    '    const lang  = codeEl.className.replace("language-", "");' +

    // Container and header
    '    const container = document.createElement("div");' +
    '    container.className = "code-container";' +

    '    const header = document.createElement("div");' +
    '    header.className  = "code-header";' +
    '    header.textContent = lang.toUpperCase();' +

    // Copy button
    '    const btn = document.createElement("button");' +
    '    btn.className  = "copy-btn";' +
    '    btn.textContent = "Copier";' +
    '    header.appendChild(btn);' +

    // DOM insertion
    '    pre.parentNode.insertBefore(container, pre);' +
    '    container.appendChild(header);' +
    '    container.appendChild(pre);' +

    // Click button management
    '    btn.onclick = () => {' +
    '      if (navigator.clipboard && navigator.clipboard.writeText) {' +
    '        navigator.clipboard.writeText(codeEl.textContent)' +
    '          .catch(() => {' +
    '            const ta = document.createElement(''textarea'');' +
    '            ta.value = codeEl.textContent;' +
    '            document.body.appendChild(ta);' +
    '            ta.select();' +
    '            document.execCommand(''copy'');' +
    '            ta.remove();' +
    '          });' +
    '      } else {' +

    '        const ta = document.createElement(''textarea'');' +
    '        ta.value = codeEl.textContent;' +
    '        document.body.appendChild(ta);' +
    '        ta.select();' +
    '        document.execCommand(''copy'');' +
    '        ta.remove();' +
    '      }' +

    '    window.chrome.webview.postMessage({' +
    '      event: "copy",' +
    '      lang: lang,' +
    '      text: codeEl.textContent' +
    '    });' +
    '  };' +

    // Syntax highlighting specific to this block
    '    if (window.hljs) window.hljs.highlightElement(codeEl);' +
    '  });' +

    '  window.scrollTo(0, document.body.scrollHeight);' +
    '})();';

  INITIAL_HTML =
    '<!DOCTYPE html><html><head><meta charset="utf-8"/>' +

    // marked.js for Markdown
    '<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>' +

    // Highlight.js core + GitHub Dark theme
    '<link rel="stylesheet" ' +
         'href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/github-dark.min.css"/>' +
    '<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"></script>' +
    '<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/languages/delphi.min.js"></script>' +

    // updated CSS styles
    '<style>' +
    '  body{margin:0;padding:1em;font-family:Segoe UI,sans-serif;' +
    '       background:#1e1e1e;color:#ddd;}' +

    // Transparent container + tone-on-tone border (#0d1117 = code background)
    '  .code-container{' +
    '     background:transparent;' +
    '     border:1px solid #0d1117;' +
    '     border-radius:8px;' +
    '     margin:1em 0;' +
    '     overflow:hidden;' +
    '  }' +

    // Dark header unchanged
    '  .code-header{' +
    '     font-family:Consolas,monospace;font-size:.85em;padding:.4em .8em;' +
    '     background:#333;color:#f5f5f5;border-bottom:1px solid #444;' +
    '     display:flex;justify-content:space-between;align-items:center;' +
    '  }' +

    '  .copy-btn{font:inherit;border:none;padding:.2em .6em;border-radius:4px;' +
    '     background:#007acc;color:#fff;cursor:pointer;}' +
    '  .copy-btn:active{transform:scale(.96);}' +

    '  /* le <pre> reste transparent pour laisser le <code.hljs> afficher son propre fond */' +
    '  .code-container pre{' +
    '     margin:0;padding:1em;background:transparent!important;' +
    '     overflow-x:auto;overflow-y:hidden;white-space:pre;' +
    '  }' +

    '</style>' +

    '</head><body>' +
    '  <div id="ResponseContent"></div>' +
    '  <script>window.onload = () => window.chrome.webview.postMessage("ready");</script>' +
    '</body></html>';

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

procedure TEdgeDisplayerVCL.CodeCopy(Lang, Code: string);
begin
  Clipboard.AsText := Code;
end;

constructor TEdgeDisplayerVCL.Create(const ABrowser: TEdgeBrowser; const AMarkDown: IMarkDown);
begin
  inherited Create;
  FBrowser := ABrowser;
  FMarkDown := AMarkDown;
  FInitialNavigation := False;
  FBrowserInitialized := False;
  FOnCodeCopied := CodeCopy;
  FBrowser.OnNavigationCompleted := DoNavigationCompleted;
  FBrowser.OnWebMessageReceived := DoWebMessageReceived;
  FBrowser.Navigate('about:blank');
end;

function TEdgeDisplayerVCL.Display(const AText: string): string;
var
  script: string;
begin
  {--- Accumulate the Markdown stream }
  FStreamContent := FStreamContent + AText + sLineBreak + sLineBreak;
  Result := FStreamContent;

  {--- Do nothing until the component is ready }
  if not FBrowserInitialized then
    Exit;

  {--- Prepare and inject the JS script for Markdown rendering and adding buttons }
  script := Format(JS_TEMPLATE, [EscapeJSString(FStreamContent)]);
  FBrowser.ExecuteScript(script);
end;

function TEdgeDisplayerVCL.DisplayStream(const AText: string): string;
var
  js: string;
begin
  {--- Accumulates the flow }
  FStreamContent := FStreamContent + AText;
  Result := FStreamContent;

  if not FBrowserInitialized then
    Exit;

  {--- Injects the script }
  js := Format(JS_TEMPLATE, [EscapeJSString(FStreamContent)]);
  FBrowser.ExecuteScript(js);
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
  if not IsSuccess then Exit;
  if not FInitialNavigation then
  begin
    Sender.NavigateToString(INITIAL_HTML);
    FInitialNavigation := True;
    Exit;
  end;
end;

procedure TEdgeDisplayerVCL.DoWebMessageReceived(
  Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  WebArgs: ICoreWebView2WebMessageReceivedEventArgs;
  pMsg: PWideChar;
  rawJson: string;
  jsonVal: TJSONValue;
  jo: TJSONObject;
begin
  {--- Retrieves the interface }
  WebArgs := Args as ICoreWebView2WebMessageReceivedEventArgs;

  {--- Calls the Get_WebMessageAsJson method to get the JSON }
  if WebArgs.Get_WebMessageAsJson(pMsg) <> S_OK then
    Exit;
  try
    rawJson := pMsg;
  finally
    CoTaskMemFree(pMsg);
  end;

  {--- Now we can test the "ready" message }
  if SameText(rawJson, '"ready"') then
  begin
    FBrowserInitialized := True;

    {--- Re-injects accumulated content on backspace }
    if FStreamContent <> '' then
      FBrowser.ExecuteScript(
        Format(JS_TEMPLATE, [EscapeJSString(FStreamContent)]));
    Exit;
  end;

  {--- Treat the object directly }
  jsonVal := TJSONObject.ParseJSONValue(rawJson);
  try
    if (jsonVal is TJSONObject) then
    begin
      jo := jsonVal as TJSONObject;
      if jo.GetValue<string>('event') = 'copy' then
      begin
        if Assigned(FOnCodeCopied) then
          FOnCodeCopied(
            jo.GetValue<string>('lang'),
            jo.GetValue<string>('text')
          );
        Exit;
      end;
    end;
  finally
    jsonVal.Free;
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
