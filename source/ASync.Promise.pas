unit ASync.Promise;
(*******************************************************************************

      Unit providing a generic implementation of Promises for handling
      asynchronous operations in Delphi.

      The ASync.Promise unit enables structured handling of asynchronous
      tasks using Promises, allowing for a clean and readable
      asynchronous programming model similar to JavaScript Promises.

      Primary components include:

      - TPromise<T>: A generic class representing a promise that can be
        resolved or rejected asynchronously.
      - TPromiseState: An enumeration indicating the state of a promise
        (Pending, Fulfilled, or Rejected).
      - Chained methods for structured handling:
      - &Then<T>: Chains operations to execute after a promise resolves.
      - &Catch: Handles errors occurring within a promise chain.

      These abstractions allow a structured and reusable way to manage
      asynchronous execution without deeply nested callbacks, facilitating
      a cleaner approach to asynchronous programming in Delphi.

  Example Usage:

  ```delphi
  procedure ExampleAsyncProcess;
  begin
    var Promise := TPromise<string>.Create(
      procedure(Resolve: TProc<string>; Reject: TProc<Exception>)
      begin
        TThread.CreateAnonymousThread(
          procedure
          begin
            Sleep(2000); // Simulating asynchronous work
            if Random(2) = 0 then
              Resolve('Operation Successful')
            else
              Reject(Exception.Create('Operation Failed'));
          end
        ).Start;
      end);

    Promise
      .&Then(
        procedure(Value: string)
        begin
          ShowMessage('Success: ' + Value);
        end)
      .&Catch(
        procedure(E: Exception)
        begin
          ShowMessage('Error: ' + E.Message);
        end);
  end;
  ```

      The unit is designed to work seamlessly with other asynchronous
      programming modules, making it a powerful addition to any Delphi
      application requiring structured async execution.

      Github repository: https://github.com/MaxiDonkey/CerebraChainAI
      Visit the repository for documentation and additional examples.

*******************************************************************************)

interface

uses
  System.SysUtils, System.Generics.Collections, System.Classes;

type
  /// <summary>
  /// Represents the state of a Promise.
  /// </summary>
  TPromiseState = (
    /// <summary>
    /// The promise is pending and has not yet been resolved or rejected.
    /// </summary>
    psPending,
    /// <summary>
    /// The promise has been fulfilled with a value.
    /// </summary>
    psFulfilled,
    /// <summary>
    /// The promise has been rejected due to an error.
    /// </summary>
    psRejected
  );

  /// <summary>
  /// A generic class that represents an asynchronous operation that may complete in the future.
  /// </summary>
  /// <typeparam name="T">The type of the value that the promise resolves with.</typeparam>
  TPromise<T> = class
  public
    /// <summary>
    /// Defines the executor procedure type that receives two callbacks: Resolve and Reject.
    /// </summary>
    type
      TExecutor = reference to procedure(Resolve: TProc<T>; Reject: TProc<Exception>);
  private
    FState: TPromiseState;
    FValue: T;
    FError: Exception;
    FThenHandlers: TList<TProc<T>>;
    FCatchHandlers: TList<TProc<Exception>>;

    /// <summary>
    /// Resolves the promise with a given value.
    /// </summary>
    /// <param name="AValue">The value to resolve the promise with.</param>
    procedure Resolve(const AValue: T);
    /// <summary>
    /// Rejects the promise with a given error.
    /// </summary>
    /// <param name="AError">The exception that caused the rejection.</param>
    procedure Reject(AError: Exception);
  public
    /// <summary>
    /// Initializes a new instance of the <see cref="TPromise{T}"/> class and starts the asynchronous operation.
    /// </summary>
    /// <param name="AExecutor">The executor function that starts the asynchronous task.</param>
    constructor Create(AExecutor: TExecutor);

    /// <summary>
    /// Destroys the promise instance and releases any associated resources.
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// Attaches a fulfillment callback that is executed when the promise is resolved.
    /// </summary>
    /// <param name="AOnFulfill">A callback function executed upon fulfillment.</param>
    /// <returns>A new promise to allow method chaining.</returns>
    function &Then(AOnFulfill: TProc): TPromise<T>; overload;

    /// <summary>
    /// Attaches a fulfillment callback that receives the resolved value.
    /// </summary>
    /// <param name="AOnFulfill">A callback function that receives the resolved value.</param>
    /// <returns>A new promise to allow method chaining.</returns>
    function &Then(AOnFulfill: TProc<T>): TPromise<T>; overload;

    //// <summary>
    /// Attaches a fulfillment callback that returns a transformed value of a different type.
    /// </summary>
    /// <typeparam name="TResult">The type of the transformed result.</typeparam>
    /// <param name="AOnFulfill">A function that produces the transformed result.</param>
    /// <returns>A new promise that resolves with the transformed value.</returns>
    function &Then<TResult>(AOnFulfill: TFunc<TResult>): TPromise<TResult>; overload;

    /// <summary>
    /// Attaches a fulfillment callback that returns another promise of a different type.
    /// </summary>
    /// <typeparam name="TResult">The type of the new promise’s result.</typeparam>
    /// <param name="AOnFulfill">A function that returns a new promise.</param>
    /// <returns>A new promise that resolves with the value of the returned promise.</returns>
    function &Then<TResult>(AOnFulfill: TFunc<T, TPromise<TResult>>): TPromise<TResult>; overload;

    /// <summary>
    /// Attaches a fulfillment callback that returns another promise of the same type.
    /// </summary>
    /// <param name="AOnFulfill">A function that returns a new promise of the same type.</param>
    /// <returns>A new promise that resolves with the value of the returned promise.</returns>
    function &Then(AOnFulfill: TFunc<T, TPromise<T>>): TPromise<T>; overload;

    /// <summary>
    /// Attaches a fulfillment callback that transforms the resolved value into another type.
    /// </summary>
    /// <typeparam name="TResult">The type of the transformed value.</typeparam>
    /// <param name="AOnFulfill">A function that transforms the resolved value.</param>
    /// <returns>A new promise that resolves with the transformed value.</returns>
    function &Then<TResult>(AOnFulfill: TFunc<T, TResult>): TPromise<TResult>; overload;

    /// <summary>
    /// Attaches a rejection callback to handle errors if the promise is rejected.
    /// </summary>
    /// <param name="AOnReject">A callback function that handles the error.</param>
    /// <returns>A new promise to allow method chaining.</returns>
    function &Catch(AOnReject: TProc<Exception>): TPromise<T>;
  end;

var
  PromiseList: TObjectList<TObject>;

implementation

{ TPromise<T> }

constructor TPromise<T>.Create(AExecutor: TExecutor);
begin
  inherited Create;
  FState := psPending;
  PromiseList.Add(Self);
  FThenHandlers := TList<TProc<T>>.Create;
  FCatchHandlers := TList<TProc<Exception>>.Create;
  try
    {--- The executor function that starts the asynchronous task. }
    AExecutor(
        procedure(AValue: T)
        begin
          Self.Resolve(AValue);
        end,

        procedure(E: Exception)
        begin
          Self.Reject(E);
        end
    );
  except
    on E: Exception do
      Reject(E);
  end;
end;

destructor TPromise<T>.Destroy;
begin
  FThenHandlers.Free;
  FCatchHandlers.Free;
  inherited;
end;

procedure TPromise<T>.Resolve(const AValue: T);
var
  Handler: TProc<T>;
begin
  if FState <> psPending then
    Exit;

  FState := psFulfilled;
  FValue := AValue;

  {--- Asynchronously call all “then” callbacks }
  for Handler in FThenHandlers do
    TThread.Queue(nil, procedure
      begin
        Handler(FValue);
      end);

  {--- Clear lists to prevent callbacks from being called later }
  FThenHandlers.Clear;
  FCatchHandlers.Clear;
end;

procedure TPromise<T>.Reject(AError: Exception);
begin
  if FState <> psPending then
    Exit;

  FState := psRejected;
  FError := AError;

  TThread.Queue(nil,
    procedure
    var
      Handler: TProc<Exception>;
    begin
      try
        {--- Call all “catch” callbacks }
        for Handler in FCatchHandlers do
          if Assigned(FError) then
            Handler(FError);
      finally
        {--- Clear the list to avoid re-execution }
        FThenHandlers.Clear;
        FCatchHandlers.Clear;
      end;
    end);
end;

function TPromise<T>.&Then(AOnFulfill: TProc<T>): TPromise<T>;
begin
  {--- Version without transformation: we wrap the procedure in a function which returns the unchanged value }
  Result := &Then<T>(
    function(Value: T): T
    begin
      AOnFulfill(Value);
      Result := Value;
    end);
end;

function TPromise<T>.&Then<TResult>(AOnFulfill: TFunc<T, TResult>): TPromise<TResult>;
begin
  {--- Creation of a new promise that will be resolved when this one is resolved }
  Result := TPromise<TResult>.Create(
    procedure(Resolve: TProc<TResult>; Reject: TProc<Exception>)
    begin
      if FState = psFulfilled then
        begin
          try
            Resolve(AOnFulfill(FValue));
          except
            on E: Exception do
              Reject(E);
          end;
        end
      else
      if FState = psRejected then
        begin
          Reject(FError)
        end
      else
        begin
          {--- If the operation is not yet complete, we add callbacks for chaining }
          FThenHandlers.Add(
            procedure(Value: T)
            begin
              try
                Resolve(AOnFulfill(Value));
              except
                on E: Exception do
                  Reject(E);
              end;
            end);
          FCatchHandlers.Add(
            procedure(E: Exception)
            begin
              Reject(E);
            end);
        end;
    end);
end;

function TPromise<T>.&Then(AOnFulfill: TFunc<T, TPromise<T>>): TPromise<T>;
begin
  Result := TPromise<T>.Create(
    procedure(Resolve: TProc<T>; Reject: TProc<Exception>)
    begin
      if FState = psFulfilled then
        begin
          try
            AOnFulfill(FValue)
              .&Then(
                procedure(NewValue: T)
                begin
                  Resolve(NewValue);
                end)
              .&Catch(
                procedure(E: Exception)
                begin
                  Reject(E);
                end);
          except
            on E: Exception do
              Reject(E);
          end;
        end
      else
      if FState = psRejected then
        begin
          Reject(FError)
        end
      else
        begin
          FThenHandlers.Add(
            procedure(Value: T)
            begin
              try
                AOnFulfill(Value)
                  .&Then(
                    procedure(NewValue: T)
                    begin
                      Resolve(NewValue);
                    end)
                  .&Catch(
                  procedure(E: Exception)
                  begin
                    Reject(E);
                  end);
              except
                on E: Exception do
                  Reject(E);
              end;
            end
            );
          FCatchHandlers.Add(
            procedure(E: Exception)
            begin
              Reject(E);
            end);
        end;
    end);
end;

function TPromise<T>.&Then<TResult>(
  AOnFulfill: TFunc<TResult>): TPromise<TResult>;
begin
  Result := TPromise<TResult>.Create(
    procedure(Resolve: TProc<TResult>; Reject: TProc<Exception>)
    begin
      if FState = psFulfilled then
        begin
          try
            {--- Call the action without parameters and resolve with the result }
            Resolve(AOnFulfill());
          except
            on E: Exception do
              Reject(E);
          end;
        end
    else
    if FState = psRejected then
      begin
        Reject(FError);
      end
    else
      begin
        {--- If the promise is pending, we add callbacks }
        FThenHandlers.Add(
          procedure(Value: T)
          begin
            try
              Resolve(AOnFulfill());
            except
              on E: Exception do
                Reject(E);
            end;
          end);
        FCatchHandlers.Add(
          procedure(E: Exception)
          begin
            Reject(E);
          end);
      end;
    end);
end;

function TPromise<T>.&Then<TResult>(
  AOnFulfill: TFunc<T, TPromise<TResult>>): TPromise<TResult>;
begin
  Result := TPromise<TResult>.Create(
    procedure(Resolve: TProc<TResult>; Reject: TProc<Exception>)
    begin
      if FState = psFulfilled then
        begin
          try
            AOnFulfill(FValue)
              .&Then(
                procedure(NewValue: TResult)
                begin
                  Resolve(NewValue);
                end)
              .&Catch(
                procedure(E: Exception)
                begin
                  Reject(E);
                end);
          except
            on E: Exception do
              Reject(E);
          end;
        end
      else
      if FState = psRejected then
        begin
          Reject(FError);
        end
      else
        begin
          FThenHandlers.Add(
            procedure(Value: T)
            begin
              try
                AOnFulfill(Value)
                  .&Then(
                    procedure(NewValue: TResult)
                    begin
                      Resolve(NewValue);
                    end)
                  .&Catch(
                    procedure(E: Exception)
                    begin
                      Reject(E);
                    end);
              except
                on E: Exception do
                  Reject(E);
              end;
            end);
          FCatchHandlers.Add(
            procedure(E: Exception)
            begin
              Reject(E);
            end);
        end;
    end);
end;

function TPromise<T>.&Then(AOnFulfill: TProc): TPromise<T>;
begin
  Result := TPromise<T>.Create(
    procedure(Resolve: TProc<T>; Reject: TProc<Exception>)
    begin
      if FState = psFulfilled then
        begin
          try
            {--- Calling the action without parameters }
            AOnFulfill;
            {--- Pass the initial value after the action is executed }
            Resolve(FValue);
          except
            on E: Exception do
              Reject(E);
          end;
        end
      else
      if FState = psRejected then
        begin
          Reject(FError)
        end
      else
        begin
          {--- If the operation is not yet completed, add callbacks for chaining }
          FThenHandlers.Add(
            procedure(Value: T)
            begin
              try
                AOnFulfill;
                Resolve(Value);
              except
                on E: Exception do
                  Reject(E);
              end;
            end);
          FCatchHandlers.Add(
            procedure(E: Exception)
            begin
              Reject(E);
            end);
        end;
    end);
end;

function TPromise<T>.&Catch(AOnReject: TProc<Exception>): TPromise<T>;
begin
  {--- Create a new promise that passes the value or handles the error with AOnReject }
  Result := TPromise<T>.Create(
    procedure(Resolve: TProc<T>; Reject: TProc<Exception>)
    begin
      if FState = psFulfilled then
        begin
          Resolve(FValue);
        end
      else
      if FState = psRejected then
        begin
          AOnReject(FError);
          Reject(FError);
        end
      else
        begin
          FThenHandlers.Add(
            procedure(Value: T)
            begin
              Resolve(Value);
            end);
          FCatchHandlers.Add(
            procedure(E: Exception)
            begin
              AOnReject(E);
              Reject(E);
            end);
        end;
    end);
end;

initialization
  PromiseList := TObjectList<TObject>.Create(True);
finalization
  PromiseList.Free;
end.

