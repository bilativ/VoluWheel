unit VolumeWheel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.XPMan,
  System.ImageList, Vcl.ImgList, CoreAudio, Vcl.Menus, Registry;

type
  TVolumeWheelFrm = class(TForm)
    TrayIcon1: TTrayIcon;
    ImageList1: TImageList;
    XPManifest1: TXPManifest;
    PopupMenu1: TPopupMenu;
    Close1: TMenuItem;
    AutoRun1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure AutoRun1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
  private
    function GetAutoRun: Boolean;
    procedure SetAutoRun(const Value: Boolean);
    { Private declarations }
  public
    property AutoRun: boolean read GetAutoRun write SetAutoRun;
    { Public declarations }
  end;

var
  VolumeWheelFrm: TVolumeWheelFrm;

const
  AutorunKey = 'Software\Microsoft\Windows\CurrentVersion\Run';
  AppName = 'VoluWheel';

implementation

{$R *.dfm}
function TVolumeWheelFrm.GetAutoRun: Boolean;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    Result := False;
    if Reg.OpenKeyReadOnly(AutorunKey) then
    begin
      Result := Reg.ValueExists(AppName);
    end;
  finally
    Reg.Free;
  end;
end;
procedure TVolumeWheelFrm.PopupMenu1Popup(Sender: TObject);
begin
  PopupMenu1.Items[1].Checked := self.AutoRun;
end;

procedure TVolumeWheelFrm.SetAutoRun(const Value: Boolean);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(AutorunKey, True) then
    begin
      if Value then
      begin
        // Set the application path for autorun
        Reg.WriteString(AppName, ParamStr(0));
      end
      else
      begin
        // Remove the entry to disable autorun
        if Reg.ValueExists(AppName) then
          Reg.DeleteValue(AppName);
      end;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TVolumeWheelFrm.TrayIcon1Click(Sender: TObject);
var
  Point: TPoint;
begin
  GetCursorPos(Point);
  var fPopupMenu := TrayIcon1.PopupMenu;
  if Assigned(FPopupMenu) then
  begin
    SetForegroundWindow(Application.Handle);
    Application.ProcessMessages;
    FPopupMenu.AutoPopup := False;
    FPopupMenu.PopupComponent := Owner;
    FPopupMenu.Popup(Point.x, Point.y);
  end;
end;

procedure TVolumeWheelFrm.FormCreate(Sender: TObject);
begin
  self.Visible := false;
  InstallHook;
end;

procedure TVolumeWheelFrm.FormDestroy(Sender: TObject);
begin
  UninstallHook;
end;

procedure TVolumeWheelFrm.AutoRun1Click(Sender: TObject);
begin
  self.AutoRun := not TMenuItem(Sender).Checked;
end;

procedure TVolumeWheelFrm.Close1Click(Sender: TObject);
begin
  self.Close;
end;

end.
