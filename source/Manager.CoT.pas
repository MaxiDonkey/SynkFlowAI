unit Manager.CoT;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Async.Promise.Params, Async.Promise.Manager;

type
  TCoTBuiler = record
  private
    class function GetWebSearchValue(const JSON: string): string; static;
    class function JsonCheck(const Value: string): Boolean; static;
    class procedure LoadJsonlFile(const AFileName: string; const Validate: Boolean; const Process: TProc<string>); static;
    class procedure LoadJsonlString(const Jsonl: string; const Validate: Boolean; const Process: TProc<string>); static;
  public
    class function JsonlCheck(const Jsonl: string): string; static;
    class function LoadFromFile(const JsonlFileName: string; const Validate: Boolean = False): TChainOfThoughts; static;
    class function LoadFromString(const Jsonl: string; const Validate: Boolean = False): TChainOfThoughts; static;
    class function JsonlToArray(const Jsonl: string): string; static;
  end;

implementation

{ TCoTBuiler }

class function TCoTBuiler.GetWebSearchValue(const JSON: string): string;
begin
  var JSONObject := TJSONObject.ParseJSONValue(JSON) as TJSONObject;
  try
    if Assigned(JSONObject) then
      begin
        Result := JSONObject.GetValue<string>('web_search');
      end
    else
      raise Exception.Create('JSON filename : Parsing error ');
  finally
    JSONObject.Free;
  end;
end;

class function TCoTBuiler.JsonCheck(const Value: string): Boolean;
begin
  var JSONValue: TJSONValue := nil;
  try
    JSONValue := TJSONObject.ParseJSONValue(Value);
    Result := Assigned(JSONValue);
  finally
    JSONValue.Free;
  end;
end;

class function TCoTBuiler.JsonlCheck(const Jsonl: string): string;
begin
  Result := Jsonl
    .Replace(sLineBreak, '')
    .Replace(#13, '')
    .Replace(#10, '')
    .Replace('} {', '}{')
    .Replace('}  {', '}{')
    .Replace('}{', '}' + sLineBreak + '{');
end;

class function TCoTBuiler.JsonlToArray(const Jsonl: string): string;
var
  Temp: string;
begin
  LoadJsonlString(Jsonl,
    False,
    procedure (Value: string)
    begin
      if Temp.IsEmpty then
        Temp := GetWebSearchValue(Value) else
        Temp := Temp + #10 + GetWebSearchValue(Value);
    end
  );
  Result := Temp;
end;

class function TCoTBuiler.LoadFromFile(
  const JsonlFileName: string; const Validate: Boolean): TChainOfThoughts;
begin
  Result := TChainOfThoughts.Create;
  var Chain := Result;
  LoadJsonlFile(JsonlFileName,
    Validate,
    procedure (Value: string)
    begin
      Chain.Add(TChainOfThought.New( Value ));
    end
  );
end;

class function TCoTBuiler.LoadFromString(
  const Jsonl: string; const Validate: Boolean): TChainOfThoughts;
begin
  Result := TChainOfThoughts.Create;
  var Chain := Result;
  LoadJsonlString(Jsonl,
    Validate,
    procedure (Value: string)
    begin
      Chain.Add(TChainOfThought.New( Value ));
    end
  );
end;

class procedure TCoTBuiler.LoadJsonlFile(const AFileName: string;
  const Validate: Boolean;  const Process: TProc<string>);
begin
  if not Assigned(Process) then
    raise Exception.Create('The lambda can''t be null');

  {--- We open the file in read-only mode }
  var FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    {--- We create the TStreamReader by specifying the desired encoding (here UTF-8) }
    var StreamReader := TStreamReader.Create(FileStream, TEncoding.UTF8);
    try
      LoadJsonlString(StreamReader.ReadToEnd, Validate, Process);
    finally
      StreamReader.Free;
    end;
  finally
    FileStream.Free;
  end;
end;

class procedure TCoTBuiler.LoadJsonlString(const Jsonl: string;
  const Validate: Boolean; const Process: TProc<string>);
var
  Line: string;
begin
  if not Assigned(Process) then
    raise Exception.Create('The lambda can''t be null');

  var StringReader := TStringReader.Create(Jsonl);
  try
    {--- Loop through each row as long as there is data }
    while StringReader.Peek <> -1 do
      begin
        Line := StringReader.ReadLine;
        if Validate and not JsonCheck(Line) then
          {--- WARNING: if JSON is detected in a string then this validation fails! }
          raise Exception.Create('Error: Invalid Json');
        Process(Line);
      end;
  finally
    StringReader.Free;
  end;
end;

end.
