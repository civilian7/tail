program tail;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Winapi.Windows;

const
  DEFAULT_POLL_INTERVAL = 100; // ms
  DEFAULT_INITIAL_LINES = 10;

var
  FileName: string;
  LastFileSize: Int64;
  LastReadPos: Int64;
  InitialLines: Integer;
  PollInterval: Integer;
  Running: Boolean;

procedure ShowUsage;
begin
  WriteLn('Usage: tail [options] <filename>');
  WriteLn;
  WriteLn('Watches a file and prints new content to console.');
  WriteLn('Press Ctrl+C to stop.');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  -n <lines>       Number of initial lines to show (default: 10)');
  WriteLn('  -i <ms>          Poll interval in milliseconds (default: 100)');
  WriteLn('  -h, --help       Show this help');
  WriteLn;
  WriteLn('Examples:');
  WriteLn('  tail mylog.txt');
  WriteLn('  tail -n 20 C:\logs\app.log');
  WriteLn('  tail -i 500 mylog.txt');
end;

procedure ParseArguments;
var
  I: Integer;
  Arg: string;
begin
  InitialLines := DEFAULT_INITIAL_LINES;
  PollInterval := DEFAULT_POLL_INTERVAL;
  FileName := '';

  I := 1;
  while I <= ParamCount do
  begin
    Arg := ParamStr(I);

    if Arg = '-n' then
    begin
      Inc(I);
      if I <= ParamCount then
        InitialLines := StrToIntDef(ParamStr(I), DEFAULT_INITIAL_LINES);
    end
    else if Arg = '-i' then
    begin
      Inc(I);
      if I <= ParamCount then
        PollInterval := StrToIntDef(ParamStr(I), DEFAULT_POLL_INTERVAL);
    end
    else if (Arg = '-h') or (Arg = '--help') then
    begin
      ShowUsage;
      Halt(0);
    end
    else if not Arg.StartsWith('-') then
      FileName := Arg;

    Inc(I);
  end;

  if FileName = '' then
  begin
    ShowUsage;
    Halt(1);
  end;

  if not TFile.Exists(FileName) then
  begin
    WriteLn('Error: File not found - ', FileName);
    Halt(1);
  end;
end;

function GetLastNLines(const AFileName: string; N: Integer): TArray<string>;
var
  Lines: TStringList;
  FileStream: TFileStream;
  StartIndex: Integer;
  I: Integer;
begin
  Lines := TStringList.Create;
  try
    FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      Lines.LoadFromStream(FileStream);
    finally
      FileStream.Free;
    end;

    StartIndex := Lines.Count - N;
    if StartIndex < 0 then
      StartIndex := 0;

    SetLength(Result, Lines.Count - StartIndex);
    for I := StartIndex to Lines.Count - 1 do
      Result[I - StartIndex] := Lines[I];
  finally
    Lines.Free;
  end;
end;

procedure ShowInitialContent;
var
  Lines: TArray<string>;
  Line: string;
  FileStream: TFileStream;
begin
  Lines := GetLastNLines(FileName, InitialLines);
  for Line in Lines do
    WriteLn(Line);

  // Set initial read position to end of file
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LastFileSize := FileStream.Size;
    LastReadPos := FileStream.Size;
  finally
    FileStream.Free;
  end;
end;

procedure ReadNewContent;
var
  FileStream: TFileStream;
  Reader: TStreamReader;
  CurrentSize: Int64;
  Line: string;
begin
  if not TFile.Exists(FileName) then
  begin
    WriteLn('[File deleted or moved]');
    Running := False;
    Exit;
  end;

  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    CurrentSize := FileStream.Size;

    // File was truncated (e.g., log rotation)
    if CurrentSize < LastReadPos then
    begin
      WriteLn('[File truncated - reading from beginning]');
      LastReadPos := 0;
    end;

    // New content available
    if CurrentSize > LastReadPos then
    begin
      FileStream.Position := LastReadPos;
      Reader := TStreamReader.Create(FileStream, TEncoding.UTF8, True, 4096);
      try
        while not Reader.EndOfStream do
        begin
          Line := Reader.ReadLine;
          WriteLn(Line);
        end;
        LastReadPos := FileStream.Position;
      finally
        Reader.Free;
      end;
    end;

    LastFileSize := CurrentSize;
  finally
    FileStream.Free;
  end;
end;

function ConsoleCtrlHandler(CtrlType: DWORD): BOOL; stdcall;
begin
  case CtrlType of
    CTRL_C_EVENT,
    CTRL_BREAK_EVENT,
    CTRL_CLOSE_EVENT:
    begin
      Running := False;
      Result := True;
    end;
  else
    Result := False;
  end;
end;

begin
  try
    ParseArguments;

    WriteLn('=== Tail: ', FileName, ' ===');
    WriteLn('(Press Ctrl+C to stop)');
    WriteLn;

    ShowInitialContent;

    Running := True;
    SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);

    while Running do
    begin
      ReadNewContent;
      Sleep(PollInterval);
    end;

    SetConsoleCtrlHandler(@ConsoleCtrlHandler, False);
    WriteLn;
    WriteLn('[Stopped]');

  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
