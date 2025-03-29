program PromiseEx2;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
  OpenAI.Promise in 'OpenAI\OpenAI.Promise.pas',
  ASync.Promise.Scheduler in 'source\ASync.Promise.Scheduler.pas',
  Manager.CoT in 'source\Manager.CoT.pas',
  Async.Promise.Pipeline in 'source\Async.Promise.Pipeline.pas',
  Sample.ChainExecutor in 'Samples\Sample.ChainExecutor.pas',
  OpenAI.FileManager in 'OpenAI\OpenAI.FileManager.pas',
  Sample.SchedulerEvents in 'Samples\Sample.SchedulerEvents.pas',
  OpenAI.ParallelPromise in 'OpenAI\OpenAI.ParallelPromise.pas',
  Sample.ScheduleParallelEvents in 'Samples\Sample.ScheduleParallelEvents.pas',
  Sample.SingleChainExecutor in 'samples\Sample.SingleChainExecutor.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows11 MineShaft');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
