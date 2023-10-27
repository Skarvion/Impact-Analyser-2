unit StatusModals;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TStatusFormModal = class(TForm)
    Label1: TLabel;
    StatusValueLabel: TLabel;
  private
    { Private declarations }
  public
    procedure SetStatus(Value: String);
  end;

var
  StatusFormModal: TStatusFormModal;

implementation

{$R *.dfm}

procedure TStatusFormModal.SetStatus(Value: String);
begin
  StatusValueLabel.Caption := Value;
end;

end.
