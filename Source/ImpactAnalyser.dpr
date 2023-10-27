program ImpactAnalyser;

uses
  Vcl.Forms,
  FImpactAnalysers in 'FImpactAnalysers.pas' {ImpactAnalyserForm},
  MethodTreeNodes in 'MethodTreeNodes.pas',
  TreeParsers in 'TreeParsers.pas',
  ClassTreeNodes in 'ClassTreeNodes.pas',
  MethodAttributes in 'MethodAttributes.pas',
  StatusModals in 'StatusModals.pas' {StatusFormModal};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TImpactAnalyserForm, ImpactAnalyserForm);
  Application.CreateForm(TStatusFormModal, StatusFormModal);
  Application.Run;
end.
