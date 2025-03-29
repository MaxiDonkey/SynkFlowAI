unit Displayer.MarkDown;

interface

uses
  System.Classes, Manager.Intf, MarkdownProcessor;

type
  TMarkDown = class(TInterfacedObject, IMarkDown)
  private
    FProcessor: TMarkdownProcessor;
  public
    function Process(const Value: string): string;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TMarkDown }

constructor TMarkDown.Create;
begin
  inherited Create;
  FProcessor := TMarkdownProcessor.createDialect(mdDaringFireball);
  // if mdCommonMark then Allow Unsafe not allowed
  FProcessor.AllowUnsafe := True;
end;

destructor TMarkDown.Destroy;
begin
  FProcessor.Free;
  inherited;
end;

function TMarkDown.Process(const Value: string): string;
begin
  Result := FProcessor.process(Value);
end;

end.
