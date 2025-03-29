unit Displayer.Cancellation.VCL;

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.Controls, Manager.Intf;

type
  TCancellationVCL = class(TInterfacedObject, ICancellation)
  private
    FCancelButton: TButton;
    FCancelled: Boolean;
    procedure DoCancelClick(Sender: TObject);
  public
    procedure Cancel;
    function IsCancelled: Boolean;
    procedure Reset;
    constructor Create(ACancelButton: TButton);
  end;

implementation

{ TCancellationVCL }

procedure TCancellationVCL.Cancel;
begin
  FCancelled := True;
  FCancelButton.Visible := False;
end;

constructor TCancellationVCL.Create(ACancelButton: TButton);
begin
  inherited Create;
  FCancelButton := ACancelButton;
  if Assigned(FCancelButton) then
    begin
      FCancelButton.Caption := 'Cancel';
      FCancelButton.OnClick := DoCancelClick;
      FCancelButton.Visible := False;
    end;
end;

procedure TCancellationVCL.DoCancelClick(Sender: TObject);
begin
  Cancel;
end;

function TCancellationVCL.IsCancelled: Boolean;
begin
  Result := FCancelled;
end;

procedure TCancellationVCL.Reset;
begin
  FCancelled := False;
  FCancelButton.Visible := True;
end;

end.
