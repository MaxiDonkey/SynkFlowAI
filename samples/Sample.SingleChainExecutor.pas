/// <summary>
/// The <c>Sample.SingleChainExecutor</c> unit provides a streamlined implementation for executing
/// a single-step or concise chain-of-thought (CoT) process asynchronously.
/// </summary>
/// <remarks>
/// <para>
/// This unit is designed to handle reasoning tasks that require only one step or a minimal sequence
/// of structured instructions, expressed as JSON-formatted content.
/// </para>
/// <para>
/// It contains two primary classes. The <c>TSingleChainExecutorParams</c> class offers a fluent interface
/// to configure all necessary parameters such as the client interface, model, input prompt, reasoning source,
/// and desired output format. The <c>TSingleChainExecutor</c> class manages the execution flow, integrating
/// with asynchronous schedulers and collecting the final result.
/// </para>
/// <para>
/// This unit is well-suited for quick, targeted reasoning workflows where a full multi-step pipeline would be
/// excessive, offering a modular and efficient solution within Delphi-based AI applications.
/// </para>
/// </remarks>
unit Sample.SingleChainExecutor;

interface

uses
  System.SysUtils, Async.Promise, Async.Promise.Manager, ASync.Promise.Params,
  Async.Promise.Pipeline, Manager.Intf, Manager.CoT, Sample.SchedulerEvents,
  Sample.ScheduleParallelEvents;

type
  /// <summary>
  /// The <c>TSingleChainExecutorParams</c> class provides a fluent interface for configuring
  /// parameters used by the <c>TSingleChainExecutor</c>.
  /// </summary>
  /// <remarks>
  /// <para>
  /// This class extends <c>TParameters</c> and encapsulates all necessary inputs for executing
  /// a single-step or compact chain-of-thought process asynchronously.
  /// </para>
  /// <para>
  /// It supports fluent setter methods for specifying the client interface, model name,
  /// input prompt, source content (defining the reasoning steps), and output type.
  /// </para>
  /// <para>
  /// Getter methods allow type-safe access to these parameters during execution, ensuring
  /// consistency and readability across the processing workflow.
  /// </para>
  /// <para>
  /// Typical usage involves configuring the parameters via method chaining and passing the
  /// instance to a <c>TSingleChainExecutor</c> constructor.
  /// </para>
  /// </remarks>
  TSingleChainExecutorParams = class(TParameters)
  const
    S_CLIENT = 'client';
    S_MODEL = 'model';
    S_PROMPT = 'prompt';
    S_SOURCE = 'source';
    S_OUTPUTTYPE = 'outputType';
  public
    /// <summary>
    /// Sets the client interface for the chain executor.
    /// </summary>
    /// <param name="Value">
    /// The client interface to be associated with the parameters.
    /// </param>
    /// <returns>
    /// The current instance of <c>TSingleChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function Client(const Value: IInterface): TSingleChainExecutorParams;
    /// <summary>
    /// Sets the model to be used for the initial processing.
    /// </summary>
    /// <param name="Value">
    /// A string representing the model name.
    /// </param>
    /// <returns>
    /// The current instance of <c>TSingleChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function Model(const Value: string): TSingleChainExecutorParams;
    /// <summary>
    /// Sets the output type for the chain execution using a <c>TOutputType</c> instance.
    /// </summary>
    /// <param name="Value">
    /// A <c>TOutputType</c> value that specifies the desired format for the output (e.g., 'json', 'none').
    /// </param>
    /// <returns>
    /// The current instance of <c>TSingleChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function OutputType(const Value: TOutputType): TSingleChainExecutorParams; overload;
    /// <summary>
    /// Sets the output type for the chain execution using a string representation.
    /// </summary>
    /// <param name="Value">
    /// A string that specifies the desired output format (e.g., 'json', 'none').
    /// </param>
    /// <returns>
    /// The current instance of <c>TSingleChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function OutputType(const Value: string): TSingleChainExecutorParams; overload;
    /// <summary>
    /// Sets the prompt text that will drive the asynchronous processing.
    /// </summary>
    /// <param name="Value">
    /// A string containing the prompt.
    /// </param>
    /// <returns>
    /// The current instance of <c>TSingleChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function Prompt(const Value: string): TSingleChainExecutorParams;
    /// <summary>
    /// Sets the source content that defines the "chain of thought" steps for execution.
    /// </summary>
    /// <param name="Value">
    /// A string containing a sequence of JSON-formatted instructions representing each reasoning step.
    /// Typically structured as multiple JSON lines, each describing a step with a title and instructions.
    /// </param>
    /// <returns>
    /// The current instance of <c>TSingleChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function Source(const Value: string): TSingleChainExecutorParams;

    /// <summary>
    /// Retrieves the client interface associated with the parameters.
    /// </summary>
    /// <returns>
    /// An instance of the client interface, or nil if not set.
    /// </returns>
    function GetClient: IInterface;
    /// <summary>
    /// Retrieves the model name associated with the parameters.
    /// </summary>
    /// <returns>
    /// A string representing the model name.
    /// </returns>
    function GetModel: string;
    /// <summary>
    /// Retrieves the configured output type for the chain execution.
    /// </summary>
    /// <returns>
    /// A <c>TOutputType</c> value indicating the desired format of the output (e.g., 'json' or 'none').
    /// </returns>
    function GetOutputType: TOutputType;
    /// <summary>
    /// Retrieves the prompt text associated with the parameters.
    /// </summary>
    /// <returns>
    /// A string containing the prompt.
    /// </returns>
    function GetPrompt: string;
    /// <summary>
    /// Retrieves the source content that defines the "chain of thought" steps used in the execution process.
    /// </summary>
    /// <returns>
    /// A string containing the JSON-formatted instructions previously set via the <c>Source</c> method.
    /// </returns>
    function GetSource: string;
  end;

  /// <summary>
  /// The <c>TSingleChainExecutor</c> class executes a single-step or condensed chain-of-thought processing task
  /// using asynchronous execution and a structured reasoning model.
  /// </summary>
  /// <remarks>
  /// <para>
  /// This class is designed for scenarios where a single "chain of thought" sequence is sufficient to analyze
  /// and generate a result from a given prompt. It supports fluent configuration through <c>TSingleChainExecutorParams</c>,
  /// and integrates seamlessly with asynchronous scheduling and processing components.
  /// </para>
  /// <para>
  /// The chain step is defined as a JSON-formatted string containing a list of reasoning instructions, and is executed
  /// by a configured language model. The result is aggregated and made available via the <c>Data</c> property.
  /// </para>
  /// <para>
  /// Use the <c>Execute</c> method to run the chain and obtain the output asynchronously. The class also provides
  /// constructor overloads for both direct parameter instances and configuration callbacks.
  /// </para>
  /// </remarks>
  TSingleChainExecutor = class
  strict private
    FClient: IInterface;
    FChainProcessor: TChainProcessor;
    FScheduleEvents: TProc<TPromiseParams>;
    FStepAction: TChainStepFunction;
    FStepSource: string;
    FDefaultModel: string;
    FOutputType: TOutputType;
  private
    FPrompt: string;
    FData: string;
  protected
    /// <summary>
    /// Initializes "chain of thought" treatment processing.
    /// </summary>
    procedure Initialize;
  public
    /// <summary>
    /// Executes the configured chain of processing  asynchronously.
    /// </summary>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the final aggregated output when have been executed.
    /// Result output into field nammed "Data".
    /// </returns>
    function Execute: TPromise<string>;
    /// <summary>
    /// Gets or sets the aggregated data output produced by the processing chain.
    /// </summary>
    property Data: string read FData write FData;
    /// <summary>
    /// Gets or sets the initial prompt used to drive the processing chain.
    /// </summary>
    property Prompt: string read FPrompt write FPrompt;
    /// <summary>
    /// Creates a new instance of <c>TSingleChainExecutor</c> using the specified chain executor parameters.
    /// </summary>
    /// <param name="Params">
    /// An instance of <c>TSingleChainExecutor</c> containing configuration settings for the execution.
    /// </param>
    constructor Create(Params: TSingleChainExecutorParams); overload;
    /// <summary>
    /// Creates a new instance of <c>TSingleChainExecutor</c> using a parameter configuration callback.
    /// </summary>
    /// <param name="ParamProc">
    /// A callback that receives a <c>TSingleChainExecutor</c> instance for configuration.
    /// </param>
    constructor Create(ParamProc: TProc<TSingleChainExecutorParams>); overload;
  end;

implementation

{ TSingleChainExecutorParams }

function TSingleChainExecutorParams.Client(
  const Value: IInterface): TSingleChainExecutorParams;
begin
  Result := TSingleChainExecutorParams(Add(S_CLIENT, Value));
end;

function TSingleChainExecutorParams.GetClient: IInterface;
begin
  Result := GetInterface(S_CLIENT);
end;

function TSingleChainExecutorParams.GetModel: string;
begin
  Result := GetString(S_MODEL, 'gpt-4o-mini');
end;

function TSingleChainExecutorParams.GetOutputType: TOutputType;
begin
  Result := TOutputType.Create(GetString(S_OUTPUTTYPE));
end;

function TSingleChainExecutorParams.GetPrompt: string;
begin
  Result := GetString(S_PROMPT);
end;

function TSingleChainExecutorParams.GetSource: string;
begin
  Result := GetString(S_SOURCE);
end;

function TSingleChainExecutorParams.Model(
  const Value: string): TSingleChainExecutorParams;
begin
  Result := TSingleChainExecutorParams(Add(S_MODEL, Value));
end;

function TSingleChainExecutorParams.OutputType(
  const Value: string): TSingleChainExecutorParams;
begin
  Result := TSingleChainExecutorParams(Add(S_OUTPUTTYPE, Value));
end;

function TSingleChainExecutorParams.OutputType(
  const Value: TOutputType): TSingleChainExecutorParams;
begin
  Result := TSingleChainExecutorParams(Add(S_OUTPUTTYPE, Value.ToString));
end;

function TSingleChainExecutorParams.Prompt(
  const Value: string): TSingleChainExecutorParams;
begin
  Result := TSingleChainExecutorParams(Add(S_PROMPT, Value));
end;

function TSingleChainExecutorParams.Source(
  const Value: string): TSingleChainExecutorParams;
begin
  Result := TSingleChainExecutorParams(Add(S_SOURCE, Value));
end;

{ TSingleChainExecutor }

constructor TSingleChainExecutor.Create(
  ParamProc: TProc<TSingleChainExecutorParams>);
begin
  var Params := TSingleChainExecutorParams.Create;
  ParamProc(Params);
  Create(Params);
end;

function TSingleChainExecutor.Execute: TPromise<string>;
begin
   {--- Assign the delegate for each scheduler }
  AsyncScheduler.SetDelegateError(MainDelegateError);

  {--- Create each steps }
  Initialize;

  {--- Initlialize the step }
  FStepAction(FChainProcessor, FStepSource);

  Result := AsyncScheduler.Execute(FChainProcessor.Pipeline)
    .&Then<string>(
      function (Value: string): string
      begin
        {--- Build the JSON data string }
        FData := FChainProcessor.Pipeline.AggregatedOutput(True);

        Result := FData;
      end)
end;

procedure TSingleChainExecutor.Initialize;
begin
  FStepAction :=
      procedure (const ChainProcessor: TChainProcessor; const CoTStep: string)
      begin
        ChainProcessor.Update
          .Client(FClient)
          .Model(FDefaultModel)
          .Input(Prompt);
        ChainProcessor.Complete(TCoTBuiler.LoadFromString(CoTStep), FScheduleEvents, FOutputType.ToString);
      end;
end;

constructor TSingleChainExecutor.Create(Params: TSingleChainExecutorParams);
begin
  inherited Create;

  {--- Initialize datas }
  FClient := Params.GetClient;
  FDefaultModel := Params.GetModel;
  FPrompt := Params.GetPrompt;
  FStepSource := Params.GetSource;
  FOutputType := Params.GetOutputType;

  {--- Create the "chainProcessor" for the pipeline management }
  FChainProcessor := TChainProcessor.Create;

  {--- the instance release will be handled by the garbage collector}
  PromiseDataTrash.Add(Self);

  {--- Defines the delegate for scheduler events managing }
  FScheduleEvents :=
    procedure (Value: TPromiseParams)
    begin
      TScheduleEvents.Create(Value);
    end;
end;

end.
