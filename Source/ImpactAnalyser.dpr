program ImpactAnalyser;

uses
  Vcl.Forms,
  FImpactAnalysers in 'FImpactAnalysers.pas' {ImpactAnalyserForm},
  FunctionTreeNodes in 'FunctionTreeNodes.pas',
  FunctionTreeParsers in 'FunctionTreeParsers.pas',
  ClassTreeNodes in 'ClassTreeNodes.pas',
  MethodAttributes in 'MethodAttributes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TImpactAnalyserForm, ImpactAnalyserForm);
  Application.Run;
end.
