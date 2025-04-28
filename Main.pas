unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Threading, System.UITypes,
  Winapi.WebView2, Winapi.ActiveX, Vcl.StdCtrls, Vcl.Edge, Async.Promise.Manager,
  Vcl.ExtCtrls;

const
  OpenAIKey = 'my_openai_key';

type
  TForm1 = class(TForm)
    EdgeBrowser1: TEdgeBrowser;
    Memo1: TMemo;
    Memo2: TMemo;
    Button1: TButton;
    Panel1: TPanel;
    Button2: TButton;
    Button4: TButton;
    Button3: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
  private
    procedure WebView2LoaderChecked;
    procedure WaitUntil(Value: Boolean = True);
    function InProgress: Boolean;
    function CanContinue: Boolean;
  end;

var
  Form1: TForm1;

implementation

uses
  Manager.Intf, OpenAI.Promise, Async.Promise, ASync.Promise.Params, Manager.IoC,
  Displayer.MarkDown, Displayer.Memo.VCL, Displayer.Edge.VCL, Displayer.Cancellation.VCL,
  ASync.Promise.Scheduler, GenAI, Sample.SchedulerEvents, Sample.ChainExecutor,
  Sample.ScheduleParallelEvents, Sample.SingleChainExecutor, OpenAI.FileManager,
  OpenAI.ParallelPromise, Manager.CoT;

{$R *.dfm}

procedure TForm1.Button10Click(Sender: TObject);
(*
Will AI disappear or evolve into artificial life?

Single chain of throught

{"step": 1, "title": "Clarify the question and objectives", "instructions": ["What is the language of the question above?", "Clarify the objective and the problem", "What is the general question I want to answer?", "What is the main issue or objective of this question?"]}
{"step": 2, "title": "Identify the dimensions and aspects of the problem", "instructions": ["What are the different aspects (historical, economic, social, technical, etc.) related to the question?", "Are there joint or interdependent aspects that deserve to be explored?"]}
{"step": 3, "title": "Formulate relevant sub-questions", "instructions": ["What sub-questions could arise from each identified aspect?", "How will these sub-questions help deepen and define the problem?"]}
{"step": 4, "title": "Define the research objectives", "instructions": ["What information or data do I need to find to answer each of these sub-questions?", "What sources (articles, reports, studies, testimonials) are likely to provide relevant insights?"]}

*)
begin
  if not CanContinue then
    Exit;

  TSingleChainExecutor.Create(
    procedure (Params: TSingleChainExecutorParams)
        begin
          Params.Client(IoC.Resolve<IGenAI>);
          Params.Prompt(Memo2.Text);
          Params.OutputType('none');
          Params.Source(
            '{"step": 1, "title": "Clarify the question and objectives", "instructions": ["What is the language of the question above?", "Clarify the objective and the problem", "What is the general question I want to answer?", "What is the main issue or objective of this question?"]}'+ sLineBreak +
            '{"step": 2, "title": "Identify the dimensions and aspects of the problem", "instructions": ["What are the different aspects (historical, economic, social, technical, etc.) related to the question?", "Are there joint or interdependent aspects that deserve to be explored?"]}'+ sLineBreak +
            '{"step": 3, "title": "Formulate relevant sub-questions", "instructions": ["What sub-questions could arise from each identified aspect?", "How will these sub-questions help deepen and define the problem?"]}'+ sLineBreak +
            '{"step": 4, "title": "Define the research objectives", "instructions": ["What information or data do I need to find to answer each of these sub-questions?", "What sources (articles, reports, studies, testimonials) are likely to provide relevant insights?"]}'
          );
        end)
    .Execute
      .&Then<string>(
        function (Value: string): string
        begin
          MemoDisplayer.Clear;
          MemoDisplayer.Display(Value);
          EdgeDisplayer.Clear;
          EdgeDisplayer.Display(Value);
          ShowMessage('Processus ended.');
          {--- Unlock controls }
          WaitUntil(False);
        end);
end;

procedure TForm1.Button2Click(Sender: TObject);
(*
Will AI disappear or evolve into artificial life?
*)
begin
  if not CanContinue then
    Exit;

  {--- Test with a simple promise with no chained processing }
  TScheduleEvents.Create(
      procedure (Params: TPromiseParams)
      begin
        Params.Client(IoC.Resolve<IGenAI>);
        Params.Model('gpt-4o-mini');
        Params.Input(Memo2.Text);
      end)
    .Execute
      .&Then<string>(
        function (Value: string): string
        begin
          ShowMessage('Processus ended.');
          {--- Unlock controls }
          WaitUntil(False);
        end)
      .&Catch(
        procedure(E: Exception)
        begin
          try
            EdgeDisplayer.Display(E.Message);
            WaitUntil(False);
          finally
            E.Free;
          end;
        end);
end;

procedure TForm1.Button3Click(Sender: TObject);
(*
Will AI disappear or evolve into artificial life?
*)
begin
  if not CanContinue then
    Exit;

  {--- Test with a semi-dynamic thought chain }
  TSampleChainExecutor.Create(
        procedure (Params: TChainExecutorParams)
        begin
          Params.Client(IoC.Resolve<IGenAI>);
          Params.Prompt(Memo2.Text);
          Params.Path('Results');
//          Params.DefaultModel('chatgpt-4o-latest');
//          Params.SearchModel('gpt-4o-search-preview');
//          Params.EditorModel('gpt-4.5-preview');
        end)
    .Execute
      .&Then<string>(
        function (Value: string): string
        begin
          ShowMessage('Processus ended.');
          {--- Unlock controls }
          WaitUntil(False);
        end);
end;

procedure TForm1.Button4Click(Sender: TObject);
(*
In one sentence: is artificial intelligence destined to disappear, or to evolve into a form of artificial life?
I have 12 euros in my pocket, after spending 3 euros on a book and getting pickpocketed by Paul yesterday. How much money did I have the day before yesterday?
*)
begin
  if not CanContinue then
    Exit;

  {--- Test with a simple parallel promise with no chained processing }
  TScheduleParallelEvents.Create(
      procedure (Params: TPromiseParams)
      begin
        Params.Client(IoC.Resolve<IGenAI>);
        Params.Model('gpt-4o-mini');
        Params.Input(Memo2.Text);
        Params.ProcessingMode('parallel');
//        Params.OutputType('json');
      end)
    .Execute
      .&Then<string>(
        function (Value: string): string
        begin
          EdgeDisplayer.Display(Value);
          ShowMessage('Processus ended.');
          {--- Unlock controls }
          WaitUntil(False);
        end)
      .&Catch(
        procedure(E: Exception)
        begin
          try
            EdgeDisplayer.Display(E.Message);
            WaitUntil(False);
          finally
            E.Free;
          end;
        end);
end;

procedure TForm1.Button5Click(Sender: TObject);
(*
In one sentence and a hyperlink: what is algebraic topology?
In one sentence and a hyperlink: what is a quantum computer?
*)
begin
  if not CanContinue then
    Exit;

  {--- Test with a simple web parallel promise with no chained processing }
  TScheduleParallelEvents.Create(
      procedure (Params: TPromiseParams)
      begin
        Params.Client(IoC.Resolve<IGenAI>);
        Params.Model('gpt-4o-search-preview');
//        Params.Model('gpt-4o-mini-search-preview');
        Params.Input(Memo2.Text);
        Params.ProcessingMode('web_parallel');
      end)
    .Execute
      .&Then<string>(
        function (Value: string): string
        begin
          EdgeDisplayer.Display(Value);
          ShowMessage('Processus ended.');
          {--- Unlock controls }
          WaitUntil(False);
        end)
      .&Catch(
        procedure(E: Exception)
        begin
          try
            EdgeDisplayer.Display(E.Message);
            WaitUntil(False);
          finally
            E.Free;
          end;
        end);
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Memo2.Text := 'Will AI disappear or evolve into artificial life?';
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  Memo2.Text :=
    'In one sentence: is artificial intelligence destined to disappear, or to evolve into a form of artificial life?' + sLineBreak +
    'I have 12 euros in my pocket, after spending 3 euros on a book and getting pickpocketed by Paul yesterday. How much money did I have the day before yesterday?';
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  Memo2.Text :=
    'In one sentence and a hyperlink: what is algebraic topology?' + sLineBreak +
    'In one sentence and a hyperlink: what is a quantum computer?';
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
  Memo2.Text :=
   'Will AI disappear or evolve into artificial life?';
end;

function TForm1.CanContinue: Boolean;
begin
  {--- Are controls locked or Memo2 text is null }
  Result := InProgress or Trim(Memo2.Text).IsEmpty;

  if not Result then
    {--- Lock controls }
    WaitUntil;

  Result := not Result;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not HttpMonitoring.IsBusy;
  if not CanClose then
    MessageDLG(
      'Requests are still in progress. Please wait for them to complete before closing the application."',
      TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], 0);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := True;

  {--- Control registration }
  IoC.RegisterType<IGenAI>(
    function: IGenAI
    begin
      Result := TGenAIFactory.CreateInstance(OpenAIKey);
    end,
    TLifetime.Transient
  );

  IoC.RegisterType<IMarkDown>(
    function: IMarkDown
    begin
      Result := TMarkDown.Create;
    end,
    TLifetime.Singleton
  );

  IoC.RegisterType<IDisplayer>('browser',
    function: IDisplayer
    begin
      Result := TEdgeDisplayerVCL.Create(EdgeBrowser1, IoC.Resolve<IMarkDown>);
    end,
    TLifetime.Transient
  );

  IoC.RegisterType<IDisplayer>('memo',
    function: IDisplayer
    begin
      Result := TMemoDisplayerVCL.Create(Memo1);
    end,
    TLifetime.Transient
  );

  IoC.RegisterType<ICancellation>(
    function: ICancellation
    begin
      Result := TCancellationVCL.Create(Button1);
    end,
    TLifetime.Singleton
  );

  IoC.RegisterType<IPromisePlugin<TPromiseParams>>('OpenAIPromise',
    function: IPromisePlugin<TPromiseParams>
    begin
      Result := TOpenAIPromise.Create;
    end,
    TLifetime.Transient
  );

  IoC.RegisterType<IPromisePlugin<TPromiseParams>>('OpenAIParallelPromise',
    function: IPromisePlugin<TPromiseParams>
    begin
      Result := TOpenAIParallelPromise.Create;
    end,
    TLifetime.Transient
  );

  IoC.RegisterType<IAsyncScheduler>(
    function: IAsyncScheduler
    begin
      Result := TAsyncScheduler.Create;
    end,
    TLifetime.Transient
  );

  IoC.RegisterType<IPromiseFileManager>(
    function: IPromiseFileManager
    begin
      Result := TPromiseAIFileManager.Create;
    end,
    TLifetime.Singleton
  );

  EdgeDisplayer := IoC.Resolve<IDisplayer>('browser');
  MemoDisplayer := IoC.Resolve<IDisplayer>('memo');
  Cancellation := IoC.Resolve<ICancellation>;
  OpenAIPromise := IoC.Resolve<IPromisePlugin<TPromiseParams>>('OpenAIPromise');
  OpenAIParallelPromise := IoC.Resolve<IPromisePlugin<TPromiseParams>>('OpenAIParallelPromise');
  AsyncScheduler := IoC.Resolve<IAsyncScheduler>;
  FileManager := IoC.Resolve<IPromiseFileManager>;

  {--- Defines the default error handling delegate invoked during ancillary processing
       when an error is encountered. }
  MainDelegateError :=
    procedure (Value: string)
    begin
      EdgeDisplayer.Display(Value);
      {--- Unlock controls }
      WaitUntil(False);
    end;

  Width := 1700;
  Height := 900;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  var Task: ITask := TTask.Create(
    procedure()
    begin
      Sleep(400);
      TThread.Queue(nil,
        procedure
        begin
          EdgeDisplayer.Clear;
          AlphaBlend := False;
          EdgeBrowser1.SetFocus;
          WebView2LoaderChecked;
        end);
    end);
  Task.Start;
end;

function TForm1.InProgress: Boolean;
begin
  Result := Panel1.Enabled = False;
end;

procedure TForm1.WaitUntil(Value: Boolean);
begin
  Panel1.Enabled := not Value;
end;

procedure TForm1.WebView2LoaderChecked;
begin
  if not FileExists('WebView2Loader.dll') then
    begin
      var Information :=
        'To ensure full support for the Edge browser, please copy the "WebView2Loader.dll" file into the executable''s directory.' + sLineBreak +
        'You can find this file in the project''s DLL folder.';
      MessageDLG(Information, TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], 0);
      Close;
    end;
end;

end.
