unit CoreAudio;

interface

uses
  Windows, ActiveX, MMSystem, Messages,
  MMDevAPI;

const
  CLSCTX_ALL = $17; // Combine all access rights

type
  TMSLLHookStruct = record
    pt: TPoint;           // The x and y screen coordinates of the mouse cursor
    mouseData: DWORD;     // Additional information about the mouse event (e.g., wheel data)
    flags: DWORD;         // Event-specific flags
    time: DWORD;          // The timestamp of the event
    dwExtraInfo: ULONG_PTR; // Additional information associated with the event
  end;
  PMSLLHookStruct = ^TMSLLHookStruct;

procedure InstallHook;
procedure UninstallHook;

var
  hMouseHook: HHOOK;
  endpointVolume: IAudioEndpointVolume;

implementation

function GetTaskbarRect: TRect;
var
  taskbarHandle: HWND;
  taskbarRect: TRect;
begin
  taskbarHandle := FindWindow('Shell_TrayWnd', nil);
  if taskbarHandle <> 0 then begin
    GetWindowRect(taskbarHandle, result);
  end else
    Result := TRect.Empty;
end;

function Trim(s, min, max: single): single;
begin
  if s<min then
    result := min
  else if s>max then
    result := max
  else
    result := s;
end;

procedure SetVolume(Delta: Single);
var
  VolumeControl: IAudioEndpointVolume;
  CurrentVolume: Single;
begin
    // Create the device enumerator
    VolumeControl := endpointVolume;
    VolumeControl.GetMasterVolumeLevelScaler(CurrentVolume);
    // Set the new volume level (between 0.0 and 1.0)
    VolumeControl.SetMasterVolumeLevelScalar(Trim(CurrentVolume+Delta, 0, 1), nil);
end;

function MouseHookProc(nCode: Integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  pMouse: PMSLLHookStruct;
  TaskbarRect: TRect;
begin
  result := 0;
  if (nCode = HC_ACTION) then
  begin
    if LoWord(wParam)=WM_MOUSEWHEEL then begin
      pMouse := PMSLLHookStruct(lParam);
      TaskbarRect := GetTaskbarRect;
      // Check if the cursor is over the taskbar
      if TaskbarRect.Contains(pMouse.pt) then begin
        var WHeelDelta :=  SmallInt(HIWORD(pMouse.mouseData));
       // Adjust volume based on scroll direction
        if WheelDelta > 0 then
          SetVolume(0.05)  // Scroll up, increase volume
        else if WheelDelta < 0 then
          SetVolume(-0.05);  // Scroll down, decrease volume
        nCode := -1;
        result := -1;
      end;
    end;
  end;
  if result=0 then
    result := CallNextHookEx(hMouseHook, nCode, wParam, lParam);
end;

procedure InstallHook;
begin
  hMouseHook := SetWindowsHookEx(WH_MOUSE_LL, @MouseHookProc, 0, 0);
end;

procedure UninstallHook;
begin
  if hMouseHook <> 0 then
  begin
    UnhookWindowsHookEx(hMouseHook);
    hMouseHook := 0;
  end;
end;

var
  deviceEnumerator: IMMDeviceEnumerator;
  defaultDevice: IMMDevice;

initialization
  EndpointVolume:=nil;
  CoCreateInstance(CLASS_IMMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER, IID_IMMDeviceEnumerator, deviceEnumerator);
  deviceEnumerator.GetDefaultAudioEndpoint(eRender, eConsole, defaultDevice);
  defaultDevice.Activate(IID_IAudioEndpointVolume, CLSCTX_INPROC_SERVER, nil, endpointVolume);


end.

