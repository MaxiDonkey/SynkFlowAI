/// <summary>
/// The <c>ASync.Promise.Scheduler</c> unit defines the <c>TAsyncScheduler</c> class,
/// which orchestrates the execution of asynchronous pipelines using a promise-based approach.
/// </summary>
/// <remarks>
/// <para>
/// This unit provides an implementation of a scheduler that processes a series of scripts
/// organized within a <c>TPipeline</c>. The <c>TAsyncScheduler</c> class sequentially executes
/// each script and handles errors via a delegate callback mechanism.
/// </para>
/// <para>
/// The scheduler supports executing the pipeline either with an explicitly provided error
/// delegate or by using a previously set delegate. It returns a <c>TPromise&lt;string&gt;</c>
/// that resolves with the final output once all scripts in the pipeline have been processed.
/// </para>
/// </remarks>
unit ASync.Promise.Scheduler;

interface

uses
  System.SysUtils, ASync.Promise, Async.Promise.Manager, Manager.Intf;

type
  /// <summary>
  /// The <c>TAsyncScheduler</c> class orchestrates the execution of a series of asynchronous tasks
  /// defined within a <c>TPipeline</c>. It manages the sequential execution of steps and handles error
  /// reporting through a delegate callback.
  /// </summary>
  /// <remarks>
  /// <para>
  /// TAsyncScheduler implements the <c>IAsyncScheduler</c> interface and is responsible for executing
  /// each script (or step) in the pipeline in order. If an error occurs during execution, the scheduler
  /// invokes the assigned error delegate to handle the error message.
  /// </para>
  /// <para>
  /// Two overloaded <c>Execute</c> methods are provided: one that accepts an explicit error delegate and
  /// another that uses the previously set delegate. In case the pipeline contains no scripts, an exception
  /// is raised.
  /// </para>
  /// <code>
  /// var
  ///   Scheduler: IAsyncScheduler;
  ///   Pipeline: TPipeline;
  /// begin
  ///   Scheduler := TAsyncScheduler.Create;
  ///   Scheduler.SetDelegateError(
  ///     procedure(ErrorMsg: string)
  ///     begin
  ///       // Handle the error (e.g., display the error message)
  ///     end);
  ///
  ///   // Configure the Pipeline with the desired scripts/steps here
  ///
  ///   Scheduler.Execute(Pipeline)
  ///     .&Then(
  ///       procedure(ResultText: string)
  ///       begin
  ///         // Process the final output
  ///       end)
  ///     .&Catch(
  ///       procedure(E: Exception)
  ///       begin
  ///         // Additional error handling if needed
  ///       end);
  /// end;
  /// </code>
  /// </remarks>
  TAsyncScheduler = class(TInterfacedObject, IAsyncScheduler)
  private
    FError: TDelegateError;
    function Execute(Scripts: TPipeline; Index: Integer): TPromise<string>; overload;
  public
    /// <summary>
    /// Sets the error delegate that will be invoked if any error occurs during the execution of the pipeline.
    /// </summary>
    /// <param name="Value">
    /// A procedure of type <c>TDelegateError</c> that processes error messages.
    /// </param>
    procedure SetDelegateError(const Value: TDelegateError);
    /// <summary>
    /// Executes the asynchronous pipeline using a specified error delegate.
    /// </summary>
    /// <param name="Scripts">
    /// The <c>TPipeline</c> containing the sequence of scripts to execute.
    /// </param>
    /// <param name="OnError">
    /// A delegate to be invoked if an error occurs during execution.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the output of the final script in the pipeline.
    /// </returns>
    function Execute(Scripts: TPipeline; const OnError: TDelegateError): TPromise<string>; overload;
    /// <summary>
    /// Executes the asynchronous pipeline using the previously set error delegate.
    /// </summary>
    /// <param name="Scripts">
    /// The <c>TPipeline</c> containing the sequence of scripts to execute.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the output of the final script in the pipeline.
    /// </returns>
    function Execute(Scripts: TPipeline): TPromise<string>; overload;
  end;

implementation

{ TAsyncScheduler }

function TAsyncScheduler.Execute(Scripts: TPipeline;
  const OnError: TDelegateError): TPromise<string>;
begin
  if Scripts.Count = 0 then
    raise Exception.Create('Error: No script defined.');

  SetDelegateError(OnError);
  Result := Execute(Scripts, 0)
    .&Catch(
      procedure(E: Exception)
      begin
        try
          if Assigned(FError) then
            FError(E.Message);
        finally
          E.Free;
        end;
      end);
end;

function TAsyncScheduler.Execute(Scripts: TPipeline): TPromise<string>;
begin
  Result := Execute(Scripts, FError);
end;

procedure TAsyncScheduler.SetDelegateError(const Value: TDelegateError);
begin
  FError := Value;
end;

function TAsyncScheduler.Execute(Scripts: TPipeline;
  Index: Integer): TPromise<string>;
begin
  {--- Base case: we have completed all the scripts }
  if Index >= Scripts.Count then
    begin
      {--- We return a promise that has already been resolved (here we return an empty result or the final accumulated result) }
      Result := TPromise<string>.Create(
        procedure(Resolve: TProc<string>; Reject: TProc<Exception>)
        begin
          Resolve(Scripts[Scripts.Count-1].GetOutput);
        end);
    end
  else
    begin
      Result := Scripts[Index].GetEvents.Execute
        .&Then<string>(
          function(PreviousResult: string): TPromise<string>
          begin
            {--- Here, we can optionally combine PreviousResult with the result of the next step }
            Result := Execute(Scripts, Index + 1);
          end);
    end;
end;

end.
