unit OpenAI.Promise;

interface

uses
  System.SysUtils, System.Classes, System.JSON, ASync.Promise, Async.Promise.Manager,
  Manager.Intf, GenAI, GenAI.Types;

type
  /// <summary>
  /// The <c>TOpenAIPromise</c> class is an implementation of the <c>IPromisePlugin&lt;TPromiseParams&gt;</c>
  /// interface that provides asynchronous execution of OpenAI prompts using streaming mode.
  /// </summary>
  /// <remarks>
  /// <para>
  /// This class integrates with the OpenAI client and uses streaming APIs to handle prompt execution,
  /// progressive result delivery, and error management. It allows interaction with the OpenAI Chat API
  /// through <c>IGenAI</c> and wraps the full async communication in a Delphi-style <c>TPromise&lt;string&gt;</c>.
  /// </para>
  /// <para>
  /// Each instance uses the <c>TPromiseParams</c> object to configure the input prompt, model,
  /// and execution behavior (e.g., silent mode or live streaming). The promise chain includes
  /// pre-execution setup, streaming response processing, and post-execution cleanup.
  /// </para>
  /// </remarks>
  TOpenAIPromise = class(TInterfacedObject, IPromisePlugin<TPromiseParams>)
  private
    /// <summary>
    /// Executes the OpenAI request with a given prompt from <c>TPromiseParams</c>
    /// and a pre-execution function that returns the user prompt.
    /// </summary>
    /// <param name="Data">
    /// The parameters containing model configuration, input prompt, and display behavior.
    /// </param>
    /// <param name="BeforeExec">
    /// A callback that generates the actual user prompt based on the current context.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the streamed OpenAI result.
    /// </returns>
    function Execute(const Data: TPromiseParams;
      const BeforeExec: TFunc<string>): TPromise<string>; overload;
  public
    /// <summary>
    /// Executes an OpenAI prompt request based on the provided <c>TPromiseParams</c> object.
    /// </summary>
    /// <param name="Data">
    /// The input parameters, including the prompt, model, and client reference.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the OpenAI response string.
    /// </returns>
    function Execute(const Data: TPromiseParams): TPromise<string>; overload;
  end;

implementation

{ TOpenAIPromise }

function TOpenAIPromise.Execute(const Data: TPromiseParams): TPromise<string>;
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

function TOpenAIPromise.Execute(const Data: TPromiseParams;
  const BeforeExec: TFunc<string>): TPromise<string>;
var
  Prompt: string;
begin
  var Client := Data.GetClient<IGenAI>;
  var SilentMode := Data.GetSilentMode;

  if Assigned(BeforeExec) then
    Prompt := BeforeExec else
    Prompt := Data.GetInput;

  Result := TPromise<string>.Create(
    procedure(Resolve: TProc<string>; Reject: TProc<Exception>)
    begin
      Client.Chat.AsynCreateStream(
        procedure(Params: TChatParams)
        begin
          Params.Model(Data.GetModel);
          Params.Messages([
            FromDeveloper(Data.GetOutputType.ToContent),
            FromUser(Prompt)]);
          Params.Stream;
        end,

        function : TAsynChatStream
        begin
          Result.Sender := Data;

          Result.OnStart :=
            procedure (Sender: TObject)
            begin
              Data.StreamBuffer := EmptyStr;
              Cancellation.Reset;
              if not SilentMode then
                EdgeDisplayer.Clear;
            end;

          Result.OnProgress :=
            procedure (Sender: TObject; Chat: TChat)
            begin
              Data.StreamBuffer := Data.StreamBuffer + Chat.Choices[0].Delta.Content;
              if not SilentMode then
                EdgeDisplayer.DisplayStream(Chat.Choices[0].Delta.Content);
            end;

          Result.OnSuccess :=
            procedure (Sender: TObject)
            begin
              Resolve(Data.StreamBuffer);
            end;

          Result.OnError :=
            procedure (Sender: TObject; Error: string)
            begin
              Reject(Exception.Create(Error));
            end;

          Result.OnDoCancel :=
            function : Boolean
            begin
              Result := Cancellation.IsCancelled;
            end;

          Result.OnCancellation :=
            procedure (Sender: TObject)
            begin
              Reject(Exception.Create('Aborted'));
            end;
        end);
    end);
end;

end.
