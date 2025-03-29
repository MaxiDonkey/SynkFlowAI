unit Sample.SchedulerEvents;

interface

uses
  System.SysUtils, Async.Promise, Async.Promise.Manager, ASync.Promise.Params, Manager.Intf;

type
  TScheduleEvents = class(TPromiseEvents)
  public
    function BeforeExec: string; override;
    function AfterExec(Value: string): string; override;
    function Execute: TPromise<string>; override;
  end;

implementation

{ TScheduleEvents }

function TScheduleEvents.AfterExec(Value: string): string;
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

function TScheduleEvents.BeforeExec: string;
begin
  var index := FOwner.GetIndex;
  var ChainSteps := FOwner.GetChainSteps;

  {--- Construct the prompt for the i-th step in the chain of thought }
  Result := FOwner.GetInput;
  if (index > -1) and Assigned(ChainSteps) then
    Result := Result + sLineBreak + FOwner.GetChainSteps[index].Content
end;

function TScheduleEvents.Execute: TPromise<string>;
begin
  {--- Run the i-th step in the chain of thought }
  Result := OpenAIPromise.Execute(FOwner);
end;

end.
