/// <summary>
/// The <c>ASync.Promise.Params</c> unit provides a generic key-value parameter management system
/// for asynchronous operations. It allows storing and retrieving various types of data including
/// integers, strings, booleans, floating-point numbers, objects, and arrays.
/// </summary>
/// <remarks>
/// <para>
/// This unit defines the <c>TParameters</c> class which offers a fluent interface for setting and
/// retrieving parameters in a type-safe manner. It simplifies the configuration of asynchronous
/// operations by allowing parameters to be managed and passed across different components of the
/// promise-based pipeline.
/// </para>
/// <para>
/// Additionally, specialized extensions such as <c>TPromiseParams</c> are provided to tailor the
/// generic parameter management specifically for asynchronous promise operations. This ensures that
/// configuration data is consistent, easily cloneable, and reusable throughout the asynchronous workflow.
/// </para>
/// </remarks>
unit ASync.Promise.Params;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.TypInfo,
  System.JSON, System.Rtti;

type

  /// <summary>
  /// Represents a generic key-value parameter manager.
  /// </summary>
  /// <remarks>
  /// This class allows storing and retrieving various types of parameters as key-value pairs.
  /// It supports basic types (integers, strings, booleans, floating-point numbers), objects,
  /// as well as arrays of these types.
  ///   <code>
  ///     var Params: TParameters;
  ///     begin
  ///       Params := TParameters.Create;
  ///       Params.Add('Limit', 100)
  ///             .Add('Order', 'Asc')
  ///             .Add('IsEnabled', True);
  ///       if Params.Exists('Limit') then
  ///         ShowMessage(Params.GetInteger('Limit').ToString);
  ///       Params.Free;
  ///     end;
  ///   </code>
  /// </remarks>
  TParameters = class
  protected
    FParams: TDictionary<string, TValue>;
  public
    constructor Create; overload;
    constructor Create(AOwnsObjects: Boolean); overload;
    destructor Destroy; override;
    function Add(const AKey: string; const AValue: Integer): TParameters; overload;
    function Add(const AKey: string; const AValue: Int64): TParameters; overload;
    function Add(const AKey: string; const AValue: string): TParameters; overload;
    function Add(const AKey: string; const AValue: Single): TParameters; overload;
    function Add(const AKey: string; const AValue: Double): TParameters; overload;
    function Add(const AKey: string; const AValue: Boolean): TParameters; overload;
    function Add(const AKey: string; const AValue: TObject): TParameters; overload;
    function Add(const AKey: string; const AValue: TJSONObject): TParameters; overload;
    function Add(const AKey: string; const AValue: IInterface): TParameters; overload;

    function Add(const AKey: string; const AValue: TArray<string>): TParameters; overload;
    function Add(const AKey: string; const AValue: TArray<Integer>): TParameters; overload;
    function Add(const AKey: string; const AValue: TArray<Int64>): TParameters; overload;
    function Add(const AKey: string; const AValue: TArray<Single>): TParameters; overload;
    function Add(const AKey: string; const AValue: TArray<Double>): TParameters; overload;
    function Add(const AKey: string; const AValue: TArray<Boolean>): TParameters; overload;
    function Add(const AKey: string; const AValue: TArray<TObject>): TParameters; overload;
    function Add(const AKey: string; const AValue: TArray<TJSONObject>): TParameters; overload;

    function GetInteger(const AKey: string; const ADefault: Integer = 0): Integer;
    function GetInt64(const AKey: string; const ADefault: Integer = 0): Integer;
    function GetString(const AKey: string; const ADefault: string = ''): string;
    function GetSingle(const AKey: string; const ADefault: Single = 0.0): Double;
    function GetDouble(const AKey: string; const ADefault: Double = 0.0): Double;
    function GetBoolean(const AKey: string; const ADefault: Boolean = False): Boolean;
    function GetObject(const AKey: string): TObject; overload;
    function GetObject<T: class>(const AKey: string): T; overload;
    function GetJSONObject(const AKey: string): TJSONObject;
    function GetInterface<T: IInterface>(const AKey: string): T; overload;
    function GetInterface(const AKey: string): IInterface; overload;

    function GetArrayString(const AKey: string): TArray<string>;
    function GetArrayInteger(const AKey: string): TArray<Integer>;
    function GetArrayInt64(const AKey: string): TArray<Int64>;
    function GetArraySingle(const AKey: string): TArray<Single>;
    function GetArrayDouble(const AKey: string): TArray<Double>;
    function GetArrayBoolean(const AKey: string): TArray<Boolean>;
    function GetArrayObject(const AKey: string): TArray<TObject>;
    function GetArrayJSONObject(const AKey: string): TArray<TJSONObject>;
    function GetJSONArray(const AKey: string): TJSONArray;

    function Exists(const AKey: string): Boolean;
    procedure ProcessParam(const AKey: string; ACallback: TProc<TValue>);
    function Clone(AOwnsObjects: Boolean = True): TParameters;
  end;

var
  PromiseDataTrash: TObjectList<TObject>;

implementation

{ TParameters }

function TParameters.Add(const AKey: string;
  const AValue: Boolean): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, AValue);
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: Double): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, AValue);
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: Integer): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, AValue);
  Result := Self;
end;

function TParameters.Add(const AKey, AValue: string): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, AValue);
  Result := Self;
end;

constructor TParameters.Create;
begin
  Create(True);
end;

function TParameters.Clone(AOwnsObjects: Boolean): TParameters;
var
  Pair: TPair<string, TValue>;
begin
  {--- Create a new instance (choose the AOwnsObjects option depending on the context) }
  Result := TParameters.Create(AOwnsObjects);
  for Pair in FParams do
    {--- Here we perform a shallow copy: simple types are copied, for objects, it is
         the reference that is copied }
    Result.FParams.AddOrSetValue(Pair.Key, Pair.Value);
end;

constructor TParameters.Create(AOwnsObjects: Boolean);
begin
  inherited Create;
  FParams := TDictionary<string, TValue>.Create;
  if AOwnsObjects then
    PromiseDataTrash.Add(Self);
end;

destructor TParameters.Destroy;
begin
  FParams.Free;
  inherited;
end;

function TParameters.Exists(const AKey: string): Boolean;
begin
  Result := FParams.ContainsKey(AKey.ToLower)
end;

function TParameters.GetArrayBoolean(const AKey: string): TArray<Boolean>;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TArray<Boolean>> then
    Result := LValue.AsType<TArray<Boolean>>
  else
    Result := [];
end;

function TParameters.GetArrayDouble(const AKey: string): TArray<Double>;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TArray<Double>> then
    Result := LValue.AsType<TArray<Double>>
  else
    Result := [];
end;

function TParameters.GetArrayInt64(const AKey: string): TArray<Int64>;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TArray<Int64>> then
    Result := LValue.AsType<TArray<Int64>>
  else
    Result := [];
end;

function TParameters.GetArrayInteger(const AKey: string): TArray<Integer>;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TArray<Integer>> then
    Result := LValue.AsType<TArray<Integer>>
  else
    Result := [];
end;

function TParameters.GetArrayJSONObject(
  const AKey: string): TArray<TJSONObject>;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TArray<TJSONObject>> then
    Result := LValue.AsType<TArray<TJSONObject>>
  else
    Result := nil;
end;

function TParameters.GetArrayObject(const AKey: string): TArray<TObject>;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TArray<TObject>> then
    Result := LValue.AsType<TArray<TObject>>
  else
    Result := [];
end;

function TParameters.GetArraySingle(const AKey: string): TArray<Single>;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TArray<Single>> then
    Result := LValue.AsType<TArray<Single>>
  else
    Result := [];
end;

function TParameters.GetArrayString(const AKey: string): TArray<string>;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TArray<string>> then
    Result := LValue.AsType<TArray<string>>
  else
    Result := [];
end;

function TParameters.GetBoolean(const AKey: string;
  const ADefault: Boolean): Boolean;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<Boolean> then
    Result := LValue.AsBoolean
  else
    Result := ADefault;
end;

function TParameters.GetDouble(const AKey: string;
  const ADefault: Double): Double;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<Double> then
    Result := LValue.AsType<Double>
  else
    Result := ADefault;
end;

function TParameters.GetInt64(const AKey: string;
  const ADefault: Integer): Integer;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<Int64> then
    Result := LValue.AsInt64
  else
    Result := ADefault;
end;

function TParameters.GetInteger(const AKey: string;
  const ADefault: Integer): Integer;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<Integer> then
    Result := LValue.AsInteger
  else
    Result := ADefault;
end;

function TParameters.GetInterface(const AKey: string): IInterface;
var
  LValue: TValue;
begin
  Result := nil;
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<IInterface> then
    Result := LValue.AsType<IInterface>;
end;

function TParameters.GetInterface<T>(const AKey: string): T;
var
  LValue: TValue;
begin
  Result := nil;
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<IInterface> then
  begin
    var LIntf := LValue.AsType<IInterface>;
    var LGUID := GetTypeData(TypeInfo(T))^.Guid;
    if not Supports(LIntf, LGUID, Result) then
      Result := nil;
  end;
end;

function TParameters.GetJSONArray(const AKey: string): TJSONArray;
begin
  Result := TJSONArray.Create;
  for var Item in GetArrayJSONObject(AKey) do
    Result.Add(Item);
end;

function TParameters.GetJSONObject(const AKey: string): TJSONObject;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<TJSONObject> then
    Result := LValue.AsType<TJSONObject>
  else
    Result := nil;
end;

function TParameters.GetObject(const AKey: string): TObject;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsObject then
    Result := LValue.AsObject
  else
    Result := nil;
end;

function TParameters.GetObject<T>(const AKey: string): T;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsObject then
    Result := LValue.AsObject as T
  else
    Result := nil;
end;

function TParameters.GetSingle(const AKey: string;
  const ADefault: Single): Double;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<Single> then
    Result := LValue.AsType<Single>
  else
    Result := ADefault;
end;

function TParameters.GetString(const AKey, ADefault: string): string;
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) and LValue.IsType<string> then
    Result := LValue.AsString
  else
    Result := ADefault;
end;

procedure TParameters.ProcessParam(const AKey: string;
  ACallback: TProc<TValue>);
var
  LValue: TValue;
begin
  if FParams.TryGetValue(AKey.ToLower, LValue) then
    ACallback(LValue);
end;

function TParameters.Add(const AKey: string;
  const AValue: TArray<string>): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<TArray<string>>(AValue));
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TArray<Integer>): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<TArray<Integer>>(AValue));
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TArray<Double>): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<TArray<Double>>(AValue));
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TArray<Boolean>): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<TArray<Boolean>>(AValue));
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TObject): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, AValue);
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TArray<Single>): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<TArray<Single>>(AValue));
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: Single): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, AValue);
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TArray<Int64>): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<TArray<Int64>>(AValue));
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: Int64): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, AValue);
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TArray<TObject>): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<TArray<TObject>>(AValue));
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TJSONObject): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, AValue);
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: TArray<TJSONObject>): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<TArray<TJSONObject>>(AValue));
  Result := Self;
end;

function TParameters.Add(const AKey: string;
  const AValue: IInterface): TParameters;
begin
  FParams.AddOrSetValue(AKey.ToLower, TValue.From<IInterface>(IInterface(AValue)));
  Result := Self;
end;

initialization
  PromiseDataTrash := TObjectList<TObject>.Create;
finalization
  PromiseDataTrash.Free;
end.
