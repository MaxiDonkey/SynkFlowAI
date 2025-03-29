/// <summary>
/// The <c>Sample.ChainExecutor</c> unit provides a sample implementation of a chain executor
/// that orchestrates multi-step asynchronous processing using a chain-of-thought approach.
/// </summary>
/// <remarks>
/// <para>
/// This unit contains classes that manage the configuration and execution of a processing pipeline
/// for complex tasks. It includes:
/// </para>
/// <para>
/// - <c>TChainExecutorParams</c>: Extends parameter management for asynchronous operations, allowing
///   for fluent configuration of inputs, models, output types, and client interfaces.
/// </para>
/// <para>
/// - <c>TSampleChainExecutor</c>: Demonstrates how to construct and execute a series of processing steps,
///   including initialization, parallel web searches, synthesis, and final text generation.
///   It coordinates the chain-of-thought process, integrates with an asynchronous scheduler, and
///   manages output aggregation.
/// </para>
/// <para>
/// This unit is designed to illustrate the use of promises, asynchronous scheduling, and dependency
/// injection in a Delphi application, providing a modular and scalable approach to processing complex
/// queries.
/// </para>
/// </remarks>
unit Sample.ChainExecutor;

interface

uses
  System.SysUtils, Async.Promise, Async.Promise.Manager, ASync.Promise.Params,
  Async.Promise.Pipeline, Manager.Intf, Manager.CoT, Sample.SchedulerEvents,
  Sample.ScheduleParallelEvents;

type
  /// <summary>
  /// The <c>TChainExecutorParams</c> class extends <c>TParameters</c> to provide specialized configuration
  /// for chain executor operations in asynchronous workflows.
  /// </summary>
  /// <remarks>
  /// <para>
  /// This class encapsulates all necessary settings for executing a chain of asynchronous processing steps.
  /// It defines constants for common parameter keys such as 'client', 'path', 'defaultModel', 'searchModel',
  /// 'editorModel', and 'prompt', and provides fluent methods for setting these values.
  /// </para>
  /// <para>
  /// In addition to its fluent setter methods (e.g., <c>Client</c>, <c>Path</c>, <c>DefaultModel</c>,
  /// <c>SearchModel</c>, <c>EditorModel</c>, and <c>Prompt</c>), the class includes getter methods that allow
  /// type-safe retrieval of the configured parameters. This ensures consistency and ease of use throughout
  /// the asynchronous execution pipeline.
  /// </para>
  /// </remarks>
  TChainExecutorParams = class(TParameters)
  const
    S_CLIENT = 'client';
    S_PATH = 'path';
    S_DEFAULT_MODEL = 'defaultModel';
    S_SEARCH_MODEL = 'searchModel';
    S_EDITOR_MODEL = 'editorModel';
    S_PROMPT = 'prompt';
  public
    /// <summary>
    /// Sets the client interface for the chain executor.
    /// </summary>
    /// <param name="Value">
    /// The client interface to be associated with the parameters.
    /// </param>
    /// <returns>
    /// The current instance of <c>TChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function Client(const Value: IInterface): TChainExecutorParams;
    /// <summary>
    /// Sets the file path for storing execution results.
    /// </summary>
    /// <param name="Value">
    /// A string representing the file path.
    /// </param>
    /// <returns>
    /// The current instance of <c>TChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function Path(const Value: string): TChainExecutorParams;
    /// <summary>
    /// Sets the default model to be used for the initial processing.
    /// </summary>
    /// <param name="Value">
    /// A string representing the default model name.
    /// </param>
    /// <returns>
    /// The current instance of <c>TChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function DefaultModel(const Value: string): TChainExecutorParams;
    /// <summary>
    /// Sets the search model to be used for parallel web search operations.
    /// </summary>
    /// <param name="Value">
    /// A string representing the search model name.
    /// </param>
    /// <returns>
    /// The current instance of <c>TChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function SearchModel(const Value: string): TChainExecutorParams;
    /// <summary>
    /// Sets the editor model to be used for final text generation.
    /// </summary>
    /// <param name="Value">
    /// A string representing the editor model name.
    /// </param>
    /// <returns>
    /// The current instance of <c>TChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function EditorModel(const Value: string): TChainExecutorParams;
    /// <summary>
    /// Sets the prompt text that will drive the asynchronous processing.
    /// </summary>
    /// <param name="Value">
    /// A string containing the prompt.
    /// </param>
    /// <returns>
    /// The current instance of <c>TChainExecutorParams</c> to allow method chaining.
    /// </returns>
    function Prompt(const Value: string): TChainExecutorParams;

    /// <summary>
    /// Retrieves the client interface associated with the parameters.
    /// </summary>
    /// <returns>
    /// An instance of the client interface, or nil if not set.
    /// </returns>
    function GetClient: IInterface;
    /// <summary>
    /// Retrieves the file path associated with the parameters.
    /// </summary>
    /// <returns>
    /// A string containing the file path.
    /// </returns>
    function GetPath: string;
    /// <summary>
    /// Retrieves the default model name associated with the parameters.
    /// </summary>
    /// <returns>
    /// A string representing the default model name.
    /// </returns>
    function GetDefaultModel: string;
    /// <summary>
    /// Retrieves the search model name associated with the parameters.
    /// </summary>
    /// <returns>
    /// A string representing the search model name.
    /// </returns>
    function GetSearchModel: string;
    /// <summary>
    /// Retrieves the editor model name associated with the parameters.
    /// </summary>
    /// <returns>
    /// A string representing the editor model name.
    /// </returns>
    function GetEditorModel: string;
    /// <summary>
    /// Retrieves the prompt text associated with the parameters.
    /// </summary>
    /// <returns>
    /// A string containing the prompt.
    /// </returns>
    function GetPrompt: string;
  end;

  /// <summary>
  /// The <c>TSampleChainExecutor</c> class orchestrates a multi-step asynchronous processing chain
  /// using a chain-of-thought approach. It allows for the dynamic configuration and execution of
  /// a series of steps (such as initialization, parallel web search, synthesis, and final text generation)
  /// to produce a comprehensive final output.
  /// </summary>
  /// <remarks>
  /// <para>
  /// TSampleChainExecutor integrates with various components of the asynchronous processing framework,
  /// including TChainProcessor, TPromiseParams, and asynchronous schedulers. It provides fluent methods
  /// to add individual processing steps, manage execution flow, and handle errors through delegate callbacks.
  /// </para>
  /// <para>
  /// The class supports both sequential and parallel execution of steps. Each step is configured using
  /// a function of type <c>TChainStepFunction</c>, and the final result is aggregated and returned as a promise.
  /// </para>
  /// <para>
  /// Use the <c>AddStep</c> methods to append processing steps to the executor, then call <c>Execute</c> to
  /// run the entire chain. The properties <c>Prompt</c>, <c>Data</c>, and <c>Text</c> are used to store
  /// intermediate and final results of the execution.
  /// </para>
  /// </remarks>
  TSampleChainExecutor = class
  strict private
    FClient: IInterface;
    FChainProcessor: TChainProcessor;
    FScheduleEvents: TProc<TPromiseParams>;
    FScheduleParallelEvents: TProc<TPromiseParams>;
    FStepActions: TArray<TChainStepFunction>;
    FStepSources: TArray<string>;
    FStepsCount: Integer;
    FCurrentStep: Integer;
    FPath: string;
    FDefaultModel: string;
    FSearchModel: string;
    FEditorModel: string;
  private
    FPrompt: string;
    FData: string;
    FText: string;
  protected
    /// <summary>
    /// Initializes the processing steps by configuring the internal arrays of step actions and sources.
    /// </summary>
    procedure StepsInitialization;
    /// <summary>
    /// Executes the first step of the processing chain.
    /// </summary>
    /// <returns>
    /// A promise that resolves with the output of the first step.
    /// </returns>
    function RunFirstStep: TPromise<string>;
    /// <summary>
    /// Executes the next step in the processing chain.
    /// </summary>
    /// <returns>
    /// A promise that resolves with the output of the current step after processing.
    /// </returns>
    function RunNextStep: TPromise<string>;
    /// <summary>
    /// Executes the final step of the processing chain, aggregates the final output, and triggers file saving if needed.
    /// </summary>
    /// <returns>
    /// A promise that resolves with the final output string.
    /// </returns>
    function RunLastStep: TPromise<string>;
  public
    /// <summary>
    /// Adds a processing step with a specified source string and corresponding step action.
    /// </summary>
    /// <param name="Source">
    /// A string representing the source or predefined content for the step.
    /// </param>
    /// <param name="Value">
    /// The <c>TChainStepFunction</c> that defines the behavior of the step.
    /// </param>
    /// <returns>
    /// The updated instance of <c>TSampleChainExecutor</c> to allow method chaining.
    /// </returns>
    function AddStep(const Source: string; const Value: TChainStepFunction): TSampleChainExecutor; overload;
    /// <summary>
    /// Adds a processing step with only a step action, using an empty source string.
    /// </summary>
    /// <param name="Value">
    /// The <c>TChainStepFunction</c> that defines the behavior of the step.
    /// </param>
    /// <returns>
    /// The updated instance of <c>TSampleChainExecutor</c> to allow method chaining.
    /// </returns>
    function AddStep(const Value: TChainStepFunction): TSampleChainExecutor; overload;
    /// <summary>
    /// Executes the configured chain of processing steps asynchronously.
    /// </summary>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the final aggregated output after all steps have been executed.
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
    /// Gets or sets the final text output produced after processing all steps.
    /// </summary>
    property Text: string read FText write FText;
    /// <summary>
    /// Creates a new instance of <c>TSampleChainExecutor</c> using the specified chain executor parameters.
    /// </summary>
    /// <param name="Params">
    /// An instance of <c>TChainExecutorParams</c> containing configuration settings for the execution.
    /// </param>
    constructor Create(Params: TChainExecutorParams); overload;
    /// <summary>
    /// Creates a new instance of <c>TSampleChainExecutor</c> using a parameter configuration callback.
    /// </summary>
    /// <param name="ParamProc">
    /// A callback that receives a <c>TChainExecutorParams</c> instance for configuration.
    /// </param>
    constructor Create(ParamProc: TProc<TChainExecutorParams>); overload;
  end;

implementation

const
  CHAIN1 =
    '{"step": 1, "title": "Clarify the question and objectives", "instructions": ["What is the language of the question above?", "Clarify the objective and the problem", "What is the general question I want to answer?", "What is the main issue or objective of this question?"]}'+ sLineBreak +
    '{"step": 2, "title": "Identify the dimensions and aspects of the problem", "instructions": ["What are the different aspects (historical, economic, social, technical, etc.) related to the question?", "Are there joint or interdependent aspects that deserve to be explored?"]}'+ sLineBreak +
    '{"step": 3, "title": "Formulate relevant sub-questions", "instructions": ["What sub-questions could arise from each identified aspect?", "How will these sub-questions help deepen and define the problem?"]}'+ sLineBreak +
    '{"step": 4, "title": "Define the research objectives", "instructions": ["What information or data do I need to find to answer each of these sub-questions?", "What sources (articles, reports, studies, testimonials) are likely to provide relevant insights?"]}'+ sLineBreak +
    (*--- the following line must contains {"web_search": "the sub-question"} *)
    '{"step": 5, "title": "Extract the relevant sub-questions", "instructions": ["List the relevant sub-questions", "Display the result as a JSONL without container, with one JSON per line for each sub-question as following {"web_search": "the sub-question"}."]}';

  // CHAIN2 : Dynamic build –-> uses the result from Step 5 to perform a parallel web search

  CHAIN3 =
    '{"step": 6, "title": "Develop a structured outline", "instructions": ["What structure should I use to organize my answer (e.g., introduction, body divided into sub-sections, conclusion)?", "How can I logically connect the ideas and ensure coherence between the parts?"]}'+ sLineBreak +
    '{"step": 7, "title": "Prepare a compelling introduction", "instructions": ["How can I quickly present the issue and grab the reader’s attention?", "What background information or central thesis should I introduce right from the start?"]}'+ sLineBreak +
    '{"step": 8, "title": "Build the main body", "instructions": ["How will each sub-question be addressed and analyzed?", "What transitions should I use to move smoothly from one aspect to another?"]}'+ sLineBreak +
    '{"step": 9, "title": "Craft a relevant conclusion", "instructions": ["How can I summarize all the points covered in the main body?", "What final message or broader perspective will I leave the reader with to strengthen the overall answer?", "The conclusion should broaden the topic."]}'+ sLineBreak +
    '{"step": 10, "title": "Revise and finalize the answer", "instructions": ["Does the answer address all the sub-questions and the initial problem?", "Are the structure, introduction, and conclusion coherent and impactful?", "Are there any redundancies or points that should be expanded or clarified?"]}';

  CHAIN4 = // Writing the final text
    '{"step": 11, "title": "Write an article with a philosophical and pedagogical approach", "instructions": ["Build a highly detailed text to answer the question", "Analyze the JSONs provided above as well as the texts, to deliver the most exhaustive possible answer.", "Adopt a philosophical and educational approach.", "To make the result more human, take a stance and be bold.", "Use an unconventional yet precise tone to captivate the reader.", "Pay close attention to clarity, relevance, originality of writing, and rigor.", "Include a few examples along with their reference URLs."]}';

{ TSampleChainExecutor }

function TSampleChainExecutor.AddStep(const Source: string;
  const Value: TChainStepFunction): TSampleChainExecutor;
begin
  {--- Add chain step function }
  SetLength(FStepActions, FStepsCount + 1);
  FStepActions[FStepsCount] := Value;

  {--- Add chain step source }
  SetLength(FStepSources, FStepsCount + 1);
  FStepSources[FStepsCount] := Source;

  Inc(FStepsCount);
  Result := Self;
end;

function TSampleChainExecutor.AddStep(
  const Value: TChainStepFunction): TSampleChainExecutor;
begin
  Result := AddStep(EmptyStr, Value);
end;

constructor TSampleChainExecutor.Create(ParamProc: TProc<TChainExecutorParams>);
begin
  var Params := TChainExecutorParams.Create;
  ParamProc(Params);
  Create(Params);
end;

constructor TSampleChainExecutor.Create(Params: TChainExecutorParams);
begin
  inherited Create;

  {--- Initialize datas }
  FStepsCount := 0;
  FClient := Params.GetClient;
  FPath := Params.GetPath;
  FDefaultModel := Params.GetDefaultModel;
  FSearchModel := Params.GetSearchModel;
  FEditorModel := Params.GetEditorModel;
  FPrompt := Params.GetPrompt;

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

  {--- Defines the delegate for scheduler parallel events managing }
  FScheduleParallelEvents :=
    procedure (Value: TPromiseParams)
    begin
      TScheduleParallelEvents.Create(Value);
    end;
end;

function TSampleChainExecutor.Execute: TPromise<string>;
begin
  {--- Assign the delegate for each scheduler }
  AsyncScheduler.SetDelegateError(MainDelegateError);

  {--- Create each steps }
  StepsInitialization;

  {--- Step 1 : initialization }
  Result := RunFirstStep
    .&Then(
      function (Value: string): TPromise<string>
      begin
        {--- Step 2 : parallel web search }
        Result := RunNextStep;
      end)
    .&Then(
      function (Value: string): TPromise<string>
      begin
        {--- Step 3 : finalization }
        Result := RunNextStep;
      end)
    .&Then(
      function (Value: string): TPromise<string>
      begin
        {--- Step 4 : writing the final text }
        Result := RunLastStep;
      end)
end;

function TSampleChainExecutor.RunFirstStep: TPromise<string>;
begin
  {--- Initialize the current step }
  FCurrentStep := 0;

  {--- Initlialize the first step }
  FStepActions[FCurrentStep](FChainProcessor, FStepSources[FCurrentStep]);

  Result := RunNextStep;
end;

function TSampleChainExecutor.RunLastStep: TPromise<string>;
begin
  {--- Build the JSON data string }
  FData := FChainProcessor.JsonOutPut + sLineBreak + FChainProcessor.TextOutPut;

  {--- Write the final text }
  Result := RunNextStep
    .&Then<string>(
      function (Value: string): string
      begin
        {--- Set the final text }
        FText := Value;
        Result := Value;
      end)
    .&Then(
      function (Value: string): TPromise<string>
      begin
        {--- Save JSON data and final text }
        Result := FileManager.CreateFileNameAndSave(FPath, Prompt, Data, Text);
      end);
end;

function TSampleChainExecutor.RunNextStep: TPromise<string>;
begin
  Result := AsyncScheduler.Execute(FChainProcessor.Pipeline)
    .&Then<string>(
      function (Value: string): string
      begin
        Inc(FCurrentStep);

        {--- The final stage has been reached }
        if FCurrentStep >= FStepsCount then
          begin
            Exit(Value);
          end;

        {--- if is not web search then the value use the Stepsource }
        if not FStepSources[FCurrentStep].IsEmpty then
          Value := FStepSources[FCurrentStep];

        {--- Prepare next step }
        FStepActions[FCurrentStep](FChainProcessor, Value);

        Result := Value;
      end);
end;

procedure TSampleChainExecutor.StepsInitialization;
begin
  {--- Step 0 : Clear the FStepActions array }
  SetLength(FStepActions, 0);

  AddStep(
      {--- Step 1 : initialization }
      CHAIN1,
      procedure (const ChainProcessor: TChainProcessor; const CoTStep: string)
      begin
        ChainProcessor.Update
          .Client(FClient)
          .Model(FDefaultModel)
          .Input(Prompt);
        ChainProcessor.Complete(TCoTBuiler.LoadFromString(CoTStep), FScheduleEvents, 'json');
      end)
  .AddStep(
      {--- Step 2 : parallel web search }
      procedure (const ChainProcessor: TChainProcessor; const CoTStep: string)
      begin
        ChainProcessor.Update
          .Model(FSearchModel)
          .ProcessingMode(TProcessingMode.web_parallel);
        {--- Run the "ChainProcessor.Complet" parallel method for web search }
        ChainProcessor.Complete(TCoTBuiler.JsonlToArray(CoTStep), FScheduleParallelEvents);
      end)
  .AddStep(
      {--- Step 3 : finalization }
      CHAIN3,
      procedure (const ChainProcessor: TChainProcessor; const CoTStep: string)
      var
        Pattern: string;
      begin
        Pattern := '{"main_question": "%s", "data_reference": "%s", "json_steps": [%s]}';
        ChainProcessor.Update
          .Model(FDefaultModel)
          .Input(Format(Pattern, [Prompt, ChainProcessor.TextOutPut, ChainProcessor.JsonOutPut]));
        ChainProcessor.Complete(TCoTBuiler.LoadFromString(CoTStep), FScheduleEvents, 'json');
      end)
  .AddStep(
      {--- Step 4 : writing the final text }
      CHAIN4,
      procedure (const ChainProcessor: TChainProcessor; const CoTStep: string)
      begin
        ChainProcessor.Update
          .Model(FEditorModel)
          .Input(Prompt + sLineBreak + ChainProcessor.TextOutPut + sLineBreak + ChainProcessor.JsonOutPut);
        ChainProcessor.Complete(TCoTBuiler.LoadFromString(CoTStep), FScheduleEvents);
      end);
end;

{ TChainExecutorParams }

function TChainExecutorParams.Client(
  const Value: IInterface): TChainExecutorParams;
begin
  Result := TChainExecutorParams(Add(S_CLIENT, Value));
end;

function TChainExecutorParams.DefaultModel(
  const Value: string): TChainExecutorParams;
begin
  Result := TChainExecutorParams(Add(S_DEFAULT_MODEL, Value));
end;

function TChainExecutorParams.EditorModel(
  const Value: string): TChainExecutorParams;
begin
  Result := TChainExecutorParams(Add(S_EDITOR_MODEL, Value));
end;

function TChainExecutorParams.GetClient: IInterface;
begin
  Result := GetInterface(S_CLIENT);
end;

function TChainExecutorParams.GetDefaultModel: string;
begin
  Result := GetString(S_DEFAULT_MODEL, 'gpt-4o-mini');
end;

function TChainExecutorParams.GetEditorModel: string;
begin
  Result := GetString(S_EDITOR_MODEL, 'gpt-4o');
end;

function TChainExecutorParams.GetPath: string;
begin
  Result := GetString(S_PATH);
end;

function TChainExecutorParams.GetPrompt: string;
begin
  Result := GetString(S_PROMPT);
end;

function TChainExecutorParams.GetSearchModel: string;
begin
  Result := GetString(S_SEARCH_MODEL, 'gpt-4o-mini-search-preview');
end;

function TChainExecutorParams.Path(const Value: string): TChainExecutorParams;
begin
  Result := TChainExecutorParams(Add(S_PATH, Value));
end;

function TChainExecutorParams.Prompt(const Value: string): TChainExecutorParams;
begin
  Result := TChainExecutorParams(Add(S_PROMPT, Value));
end;

function TChainExecutorParams.SearchModel(
  const Value: string): TChainExecutorParams;
begin
  Result := TChainExecutorParams(Add(S_SEARCH_MODEL, Value));
end;

end.
