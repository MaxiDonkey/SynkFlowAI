unit OpenAI.ParallelPromise;

interface

uses
  System.SysUtils, System.Classes, System.JSON, ASync.Promise, Async.Promise.Manager,
  Manager.Intf, GenAI, GenAI.Types, Manager.CoT;

type
  /// <summary>
  /// Represents a promise that handles parallel execution of requests to OpenAI.
  /// This class implements the <see cref="IPromisePlugin{TPromiseParams}"/> interface
  /// to handle asynchronous requests for parallel processing using OpenAI's API.
  /// </summary>
  /// <remarks>
  /// The <see cref="TOpenAIParallelPromise"/> class allows parallel execution of multiple
  /// sub-requests, useful for scenarios like parallel web searches or handling multiple
  /// queries at the same time. It communicates with the OpenAI API to handle multiple requests
  /// in parallel and aggregates the results, providing a streamlined experience for parallel processing.
  /// </remarks>
  TOpenAIParallelPromise = class(TInterfacedObject, IPromisePlugin<TPromiseParams>)
  private
    function ToJsonFormat(const Item: TBundleItem; WebRequest: Boolean): string;
    function WebParallelProcess(const Bundle: TBundleList): string;
    function ParallelProcess(const Bundle: TBundleList; OutputType: TOutputType): string;

    /// <summary>
    /// Executes the promise for a given <see cref="TPromiseParams"/> instance.
    /// This method triggers the asynchronous operation with parallel processing
    /// for multiple queries using OpenAI's API.
    /// </summary>
    /// <param name="Data">
    /// The <see cref="TPromiseParams"/> instance containing the parameters
    /// for the promise execution, including input, model, and other settings.
    /// </param>
    /// <returns>
    /// Returns a <see cref="TPromise{string}"/> that resolves when all parallel queries
    /// are completed, returning a combined result of the parallel executions.
    /// </returns>
    /// <exception cref="Exception">
    /// Throws an exception if the parallel execution encounters an error or fails.
    /// </exception>
    function Execute(const Data: TPromiseParams;
      const BeforeExec: TFunc<string>): TPromise<string>; overload;
  public
    /// <summary>
    /// Executes the promise for a given <see cref="TPromiseParams"/> instance, including
    /// a callback function to be executed before the asynchronous operation starts.
    /// </summary>
    /// <param name="Data">
    /// The <see cref="TPromiseParams"/> instance containing the parameters
    /// for the promise execution, including input, model, and other settings.
    /// </param>
    /// <param name="BeforeExec">
    /// A function to execute before the promise starts processing. It can return a string
    /// that will be used as the prompt for the parallel processing operation.
    /// </param>
    /// <returns>
    /// Returns a <see cref="TPromise{string}"/> that resolves when all parallel queries
    /// are completed, returning a combined result of the parallel executions.
    /// </returns>
    /// <exception cref="Exception">
    /// Throws an exception if the parallel execution encounters an error or fails.
    /// </exception>
    function Execute(const Data: TPromiseParams): TPromise<string>; overload;
  end;

implementation

{ TOpenAIParallelPromise }

function TOpenAIParallelPromise.Execute(
  const Data: TPromiseParams): TPromise<string>;
begin
  Result := Execute(Data, Data.GetEvents.BeforeExec)
    .&Then<string>(
      function (Value: string): string
      var
        DoAfter: TFunc<string, string>;
      begin
        DoAfter := Data.GetEvents.AfterExec;
        if Assigned(DoAfter) then
          Result := DoAfter(Value) else
          Result := EmptyStr;
      end);
end;

function TOpenAIParallelPromise.ParallelProcess(const Bundle: TBundleList;
  OutputType: TOutputType): string;
var
  Sep: string;
  Buffer: string;
begin
  case OutputType of
    TOutputType.json :
      Sep := ',' + sLineBreak;
    TOutputType.none :
      Sep := sLineBreak + sLineBreak;
  end;
  for var Item in Bundle.Items do
    begin
      if OutputType = TOutputType.json then
        Buffer := ToJsonFormat(Item, False) else
        Buffer := Item.Response;
      if Result.IsEmpty then
        Result := Buffer else
        Result := Result + Sep + Buffer;
    end;
end;

function TOpenAIParallelPromise.ToJsonFormat(const Item: TBundleItem; WebRequest: Boolean): string;
begin
  if WebRequest then
    begin
      Result := Format('{"sub_question": "%s", "response": "%s"}',
        [Item.Prompt,
         Item.Response
           .Replace(sLineBreak,'\n\n')
           .Replace(#10,'\n\n')
           .Replace(#13,'\n\n')
         ]);
      Exit;
    end;

  if Item.Response.Trim.StartsWith('{') then
    Result := Item.Response.Trim.Substring(1);
  Result := Format('{"Question:", "%s" , %s',
     [Item.Prompt,
      Result.Replace(sLineBreak,'\n\n')
        .Replace(#10,'\n\n')
        .Replace(#13,'\n\n')]);
end;

function TOpenAIParallelPromise.WebParallelProcess(const Bundle: TBundleList): string;
begin
  for var Item in Bundle.Items do
    begin
      var Buffer := ToJsonFormat(Item, True);
      if Result.IsEmpty then
        Result := Buffer else
        Result := Result + ',' + sLineBreak + Buffer;
    end;
end;

function TOpenAIParallelPromise.Execute(const Data: TPromiseParams;
  const BeforeExec: TFunc<string>): TPromise<string>;
begin
  var Client := Data.GetClient<IGenAI>;
  var SilentMode := Data.GetSilentMode;
  var Messages := BeforeExec().Split([#10]);
  var OutPutType := Data.GetOutputType;

  Result := TPromise<string>.Create(
    procedure(Resolve: TProc<string>; Reject: TProc<Exception>)
    begin
      if Length(Messages) = 0 then
        Reject(Exception.Create('Parallel message can''t be null'));

      Client.Chat.CreateParallel(
      procedure (Params: TBundleParams)
      begin
        if OutPutType = TOutputType.json then
          Params.System(OutPutType.ToContent);
        Params.Prompts(Messages);
        Params.Model(Data.GetModel);
      end,
      function : TAsynBundleList
      begin
        Result.Sender := Data;

        Result.OnStart :=
          procedure (Sender: TObject)
          begin
            Data.StreamBuffer := EmptyStr;
            if not SilentMode then
              begin
                EdgeDisplayer.Clear;
                case Data.GetProcessingMode of
                  TProcessingMode.web_parallel :
                    EdgeDisplayer.Display('Web search in progress, please wait...');
                  TProcessingMode.parallel :
                    EdgeDisplayer.Display('Parallel process in progress, please wait...');
                end;
              end;
          end;

        Result.OnSuccess :=
          procedure (Sender: TObject; Bundle: TBundleList)
          begin
            case Data.GetProcessingMode of
              TProcessingMode.web_parallel :
                Data.StreamBuffer := WebParallelProcess(Bundle);
              TProcessingMode.parallel :
                Data.StreamBuffer := ParallelProcess(Bundle, OutPutType);
            end;
            Resolve(Data.StreamBuffer);
          end;

        Result.OnError :=
          procedure (Sender: TObject; Error: string)
          begin
            Reject(Exception.Create(Error));
          end;
      end);

    end);
end;

end.
