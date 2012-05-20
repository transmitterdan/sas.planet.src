{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2012, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.ru                                                           *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit u_OperationNotifier;

interface

uses
  SysUtils,
  i_JclNotify,
  i_OperationNotifier;

type
  IOperationNotifierInternal = interface(IOperationNotifier)
    procedure NextOperation;
  end;

  TOperationNotifier = class(TInterfacedObject, IOperationNotifier, IOperationNotifierInternal)
  private
    FNotifier: IJclNotifier;
    FCurrentOperationID: Integer;
    FCS: IReadWriteSync;
  protected
    procedure NextOperation;
  protected
    function GetCurrentOperation: Integer; stdcall;
    function IsOperationCanceled(AID: Integer): Boolean; stdcall;

    procedure AddListener(AListener: IJclListener); stdcall;
    procedure RemoveListener(AListener: IJclListener); stdcall;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  u_Synchronizer,
  u_JclNotify;

{ TOperationNotifier }

constructor TOperationNotifier.Create;
begin
  inherited Create;
  FCS := MakeSyncRW_Std(Self, TRUE);
  FNotifier := TJclBaseNotifier.Create;
  FCurrentOperationID := 0;
end;

destructor TOperationNotifier.Destroy;
begin
  FCS := nil;
  inherited Destroy;
end;

procedure TOperationNotifier.AddListener(AListener: IJclListener);
begin
  FCS.BeginRead;
  try
    // sync internally
    FNotifier.Add(AListener);
  finally
    FCS.EndRead;
  end;
end;

function TOperationNotifier.IsOperationCanceled(AID: Integer): Boolean;
begin
  FCS.BeginRead;
  try
    Result := FCurrentOperationID <> AID;
  finally
    FCS.EndRead;
  end;
end;

function TOperationNotifier.GetCurrentOperation: Integer;
begin
  FCS.BeginRead;
  try
    Result := FCurrentOperationID;
  finally
    FCS.EndRead;
  end;
end;

procedure TOperationNotifier.NextOperation;
begin
  FCS.BeginWrite;
  try
    Inc(FCurrentOperationID);
    FNotifier.Notify(nil);
  finally
    FCS.EndWrite;
  end;
end;

procedure TOperationNotifier.RemoveListener(AListener: IJclListener);
begin
  FCS.BeginRead;
  try
    // sync internally
    FNotifier.Remove(AListener);
  finally
    FCS.EndRead;
  end;
end;

end.
