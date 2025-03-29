unit Sample.ScheduleParallelEvents;

interface

uses
  System.SysUtils, Async.Promise, Async.Promise.Manager, ASync.Promise.Params, Manager.Intf;

type
  TScheduleParallelEvents = class(TPromiseEvents)
  public
    function BeforeExec: string; override;
    function AfterExec(Value: string): string; override;
    function Execute: TPromise<string>; override;
  end;

implementation

{ TScheduleParallelEvents }

function TScheduleParallelEvents.AfterExec(Value: string): string;
begin
  {--- Obtain the output from the i-th step of the thought process. }
  FOwner.Output(Value);

  Result := Value;

  {--- If silent mode enabled then exits processing }
  if FOwner.GetSilentMode then
    Exit;

  {--- Clear the TMemo display }
  MemoDisplayer.Clear;

  {--- Display the output from the i-th step of the thought process  }
  MemoDisplayer.Display(Value);
end;

function TScheduleParallelEvents.BeforeExec: string;
begin
  Result := FOwner.GetInput.Trim;
end;

function TScheduleParallelEvents.Execute: TPromise<string>;
begin
  {--- Parallel run the i-th step in the chain of thought }
  Result := OpenAIParallelPromise.Execute(FOwner);
end;

end.
