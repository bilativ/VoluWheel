program VoluWheel;

uses
  Vcl.Forms,
  VolumeWheel in 'VolumeWheel.pas' {VolumeWheelFrm},
  CoreAudio in 'CoreAudio.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
   Application.ShowMainForm := False;
  Application.CreateForm(TVolumeWheelFrm, VolumeWheelFrm);
  Application.Run;
end.
