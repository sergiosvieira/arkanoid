program Arkanoid;

uses
  Forms,
  UMain in 'UMain.pas' {FmMain};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFmMain, FmMain);
  Application.Run;
end.
