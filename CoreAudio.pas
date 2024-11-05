unit CoreAudio;

interface

uses
  Windows, ActiveX, MMSystem, Messages,
  MMDevAPI;

const
  CLSCTX_ALL = $17; // Combine all access rights

const
  MONITOR_DEFAULTTONULL    = $00000000;
  MONITOR_DEFAULTTOPRIMARY = $00000001;
  MONITOR_DEFAULTTONEAREST = $00000002;
type
  TMonitorInfo = record
    cbSize: DWORD;
    rcMonitor: TRect;
    rcWork: TRect;
    dwFlags: DWORD;
  end;
type
  TMonitorDpiType = (MDT_EFFECTIVE_DPI = 0, MDT_ANGULAR_DPI = 1, MDT_RAW_DPI = 2, MDT_DEFAULT = MDT_EFFECTIVE_DPI);
type
  TMSLLHookStruct = record
    pt: TPoint;           // The x and y screen coordinates of the mouse cursor
    mouseData: DWORD;     // Additional information about the mouse event (e.g., wheel data)
    flags: DWORD;         // Event-specific flags
    time: DWORD;          // The timestamp of the event
    dwExtraInfo: ULONG_PTR; // Additional information associated with the event
  end;
  PMSLLHookStruct = ^TMSLLHookStruct;

function GetDpiForMonitor(hMonitor: HMONITOR; dpiType: TMonitorDpiType; out dpiX: UINT; out dpiY: UINT): HRESULT; stdcall; external 'Shcore.dll';
function MonitorFromWindow(hWnd: HWND; dwFlags: DWORD): HMONITOR; stdcall; external 'User32.dll';

procedure InstallHook;
procedure UninstallHook;

var
  hMouseHook: HHOOK;
  endpointVolume: IAudioEndpointVolume;

implementation

function GetTaskbarHeight: Integer;
var
  taskbarHandle: HWND;
  taskbarRect: TRect;
begin
  taskbarHandle := FindWindow('Shell_TrayWnd', nil);
  if taskbarHandle <> 0 then
  begin
    GetWindowRect(taskbarHandle, taskbarRect);
    Result := taskbarRect.Bottom - taskbarRect.Top;
  end
  else
    Result := 0;
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

function Max(a, b: DWORD): DWORD;
begin
  if a>b then
    result := a
  else
    result := b;
end;

function Min(a, b: DWORD): DWORD;
begin
  if a<b then
    result := a
  else
    result := b;
end;

function GET_WHEEL_DELTA_WPARAM(wParam: DWORD): SmallInt;
begin
  Result := SmallInt(HIWORD(wParam));
end;

function MouseHookProc(nCode: Integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  pMouse: PMSLLHookStruct;
  ScreenHeight: Integer;
  TaskbarHeight: Integer;
  dpix, dpiy: cardinal;
begin
  result := CallNextHookEx(hMouseHook, nCode, wParam, lParam);
  if (nCode = HC_ACTION) then
  begin
    if LoWord(wParam)=WM_MOUSEWHEEL then
    begin
      pMouse := PMSLLHookStruct(lParam);
      var m := MonitorFromWindow(FindWindow('Shell_TrayWnd', nil), 0);
      GetDPIForMonitor(m, MDT_EFFECTIVE_DPI, dpix, dpiy);
      ScreenHeight := GetSystemMetricsForDpi(SM_CYSCREEN, dpiy);

      TaskbarHeight := GetTaskbarHeight;
      var WHeelDelta :=  SmallInt(HIWORD(pMouse.mouseData));
      // Check if the cursor is over the taskbar
      var y := pMouse.pt.y;
      if (pMouse.pt.x>0) and (y > ScreenHeight - TaskbarHeight) then
      begin
        // Adjust volume based on scroll direction
        if WheelDelta > 0 then
          SetVolume(0.05)  // Scroll up, increase volume
        else if WheelDelta < 0 then
          SetVolume(-0.05);  // Scroll down, decrease volume
        result := -1;
      end;
    end;
  end;
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

