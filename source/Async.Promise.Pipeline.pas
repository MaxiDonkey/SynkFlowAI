/// <summary>
/// The <c>Async.Promise.Pipeline</c> unit defines core components for managing asynchronous
/// processing pipelines using a structured chain-of-thought model.
/// </summary>
/// <remarks>
/// <para>- This unit introduces the <c>TChainProcessor</c> class, which orchestrates the flow of
/// asynchronous steps in a pipeline, handling both sequential and parallel operations.</para>
/// <para>- It supports aggregation of intermediate results in both JSON and plain-text formats,
/// and allows dynamic configuration of each step using a shared prototype of parameters.</para>
/// <para>- The unit is especially suited for scenarios involving multi-step reasoning, prompt chaining,
/// and intelligent composition of data-driven responses using AI services.</para>
/// </remarks>
unit Async.Promise.Pipeline;

interface

uses
  System.SysUtils, ASync.Promise, ASync.Promise.Params, Async.Promise.Manager, Manager.Intf;

type
  TChainProcessor = class;

  /// <summary>
  /// Represents a delegate procedure that defines a processing step within a chain-of-thought pipeline.
  /// </summary>
  /// <param name="Value">
  /// The <c>TChainProcessor</c> instance that manages and provides access to the current processing pipeline state.
  /// </param>
  /// <param name="CoTStep">
  /// A string that specifies the content or identifier for the current chain-of-thought step, which can serve as a prompt or configuration data.
  /// </param>
  TChainStepFunction = reference to procedure(const Value: TChainProcessor; const CoTStep: string);

  /// <summary>
  /// The <c>TChainProcessor</c> class manages the chain-of-thought processing within
  /// the asynchronous pipeline. It aggregates outputs (both JSON and text) generated
  /// by each step and prepares parameters for subsequent asynchronous operations.
  /// </summary>
  TChainProcessor = class
  private
    FChainOfThought: TChainOfThoughts;
    FPipeline: TPipeline;
    FPrototype: TPromiseParams;
    FJsonOutPut: string;
    FOutPutType: TOutputType;
    FTextOutput: string;
    function GetPipeline: TPipeline;
    procedure SetPipeline(const Value: TPipeline);
    function GetTextOutput: string;
    procedure SetTextOutput(const Value: string);
    function GetJsonOutPut: string;
    procedure SetJsonOutPut(const Value: string);
  public
    constructor Create;
    /// <summary>
    /// Aggregates the pipeline output according to the selected <c>TOutputType</c>,
    /// updates the internal prototype with the latest state, and clears the pipeline.
    /// </summary>
    /// <returns>
    /// A <c>TPromiseParams</c> instance (the prototype) ready to be used for the next step.
    /// </returns>
    function Update: TPromiseParams;
    /// <summary>
    /// Completes the setup of the thought chain using a predefined set of steps.
    /// For each step, the prototype is cloned, indexed, and passed to the provided
    /// <paramref name="Events"/> callback to configure step-specific behavior.
    /// </summary>
    /// <param name="AChainOfThought">The list of steps representing the reasoning process.</param>
    /// <param name="Events">A callback used to configure each step's <c>TPromiseParams</c>.</param>
    /// <param name="AOutputType">The desired output type (e.g., 'json' or 'none').</param>
    /// <remarks>
    /// Only for sequential processing of pipeline methods
    /// </remarks>
    procedure Complete(const AChainOfThought: TChainOfThoughts;
      const Events: TProc<TPromiseParams>;
      const AOutputType: string = 'none'); overload;
    /// <summary>
    /// Completes the setup for a single-step pipeline using a custom prompt.
    /// This method is typically used for parallel or direct invocation scenarios.
    /// </summary>
    /// <param name="Prompts">The raw input prompt to be used in the step.</param>
    /// <param name="Events">A callback to configure the execution parameters for the step.</param>
    /// <param name="AOutputType">The desired output type (default is 'none').</param>
    /// <remarks>
    /// Only for parallel processing of pipeline methods
    /// </remarks>
    procedure Complete(const Prompts: string;
      const Events: TProc<TPromiseParams>;
      const AOutputType: string = 'none'); overload;
    /// <summary>
    /// Gets or sets the aggregated JSON-formatted output from the pipeline.
    /// </summary>
    property JsonOutPut: string read GetJsonOutPut write SetJsonOutPut;
    /// <summary>
    /// Gets or sets the collection of chain-of-thought steps that define the reasoning flow.
    /// </summary>
    property ChainOfThought: TChainOfThoughts read FChainOfThought write FChainOfThought;
    /// <summary>
    /// Gets or sets the output type used for formatting and aggregation logic.
    /// </summary>
    property OutPutType: TOutputType read FOutPutType write FOutPutType;
    /// <summary>
    /// Gets or sets the pipeline that contains all asynchronous steps to be executed.
    /// </summary>
    property Pipeline: TPipeline read GetPipeline write SetPipeline;
    /// <summary>
    /// Gets or sets the prototype used to clone base configuration for each pipeline step.
    /// </summary>
    property Prototype: TPromiseParams read FPrototype write FPrototype;
    /// <summary>
    /// Gets or sets the final aggregated plain-text output of the pipeline.
    /// </summary>
    property TextOutPut: string read GetTextOutput write SetTextOutput;
  end;

implementation

{ TChainProcessor }

procedure TChainProcessor.Complete(const AChainOfThought: TChainOfThoughts;
  const Events: TProc<TPromiseParams>; const AOutputType: string);
begin
  if not Assigned(Events) then
    raise Exception.Create('Promise events can be null.');

  FChainOfThought := AChainOfThought;
  FOutPutType := TOutputType.Create(AOutputType);

  for var i := 0 to FChainOfThought.Count - 1 do
  begin
    var Data := Prototype
       .CloneWithIndex(i)
       .OutputType(FOutPutType.ToString)
       .ChainSteps(FChainOfThought)
       .Pipeline(FPipeline);
    Events(Data);
    Pipeline.Add(Data);
  end;
end;

procedure TChainProcessor.Complete(const Prompts: string;
  const Events: TProc<TPromiseParams>; const AOutputType: string);
begin
  if not Assigned(Events) then
    raise Exception.Create('Promise events can be null.');

  FOutPutType := TOutputType.Create('none');
  {--- Enable parallel mode }
  var Data := Prototype
       .CloneWithIndex(0)
       .OutputType(FOutPutType.ToString)
       .ChainSteps(FChainOfThought)
       .Pipeline(FPipeline)
       .Input(Prompts);
  Events(Data);
  Pipeline.Add(Data);
end;

constructor TChainProcessor.Create;
begin
  inherited Create;
  PromiseDataTrash.Add(Self);
  FPipeline := TPipeline.Create;
  FPrototype := TPromiseParams.Create;
end;

function TChainProcessor.GetJsonOutPut: string;
begin
  Result := FJsonOutPut;
end;

function TChainProcessor.GetPipeline: TPipeline;
begin
  Result := FPipeline;
end;

function TChainProcessor.GetTextOutput: string;
begin
  Result := FTextOutput;
end;

procedure TChainProcessor.SetJsonOutPut(const Value: string);
begin
  FJsonOutPut := Value;
end;

procedure TChainProcessor.SetPipeline(const Value: TPipeline);
begin
  FPipeline := Value;
end;

procedure TChainProcessor.SetTextOutput(const Value: string);
begin
  FTextOutput := Value;
end;

function TChainProcessor.Update: TPromiseParams;
begin
  case FOutPutType of
    TOutputType.json:
      FJsonOutPut := FJsonOutPut + Pipeline.AggregatedOutput(FJsonOutPut.IsEmpty);
    TOutputType.none:
      FTextOutput := Pipeline.AggregatedOutput(False)
                      .Replace(sLineBreak,'\n\n')
                      .Replace(#10,'\n\n')
                      .Replace(#13,'\n\n');
  end;

  FPipeline.Clear;
  Result := FPrototype;
end;

end.
