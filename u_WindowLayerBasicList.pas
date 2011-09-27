{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2011, SAS.Planet development team.                      *}
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

unit u_WindowLayerBasicList;

interface

uses
  Classes,
  i_InternalPerformanceCounter,
  u_WindowLayerBasic;

type
  TWindowLayerBasicList = class
  private
    FList: TList;
    FPerfList: IInternalPerformanceCounterList;
    function GetCount: Integer;
  protected
    function Get(AIndex: Integer): TWindowLayerAbstract;
  public
    constructor Create(AParentPerfList: IInternalPerformanceCounterList);
    destructor Destroy; override;
    function Add(AItem: TWindowLayerAbstract): Integer;
    procedure StartThreads;
    procedure SendTerminateToThreads;
    property Items[Index: Integer]: TWindowLayerAbstract read Get; default;
    property Count: Integer read GetCount;
  end;

implementation

uses
  SysUtils;

{ TWindowLayerBasicList }

constructor TWindowLayerBasicList.Create(AParentPerfList: IInternalPerformanceCounterList);
begin
  FList := TList.Create;;
  FPerfList := AParentPerfList.CreateAndAddNewSubList('Layer');
end;

destructor TWindowLayerBasicList.Destroy;
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do begin
    Items[i].Free;
  end;
  FreeAndNil(FList);
  inherited;
end;

function TWindowLayerBasicList.Add(AItem: TWindowLayerAbstract): Integer;
begin
  AItem.PerfList := FPerfList.CreateAndAddNewSubList(AItem.ClassName);
  Result := FList.Add(AItem);
end;

function TWindowLayerBasicList.Get(AIndex: Integer): TWindowLayerAbstract;
begin
  Result := TWindowLayerAbstract(FList.Items[AIndex]);
end;

function TWindowLayerBasicList.GetCount: Integer;
begin
  Result := FList.Count;
end;

procedure TWindowLayerBasicList.SendTerminateToThreads;
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do begin
    Items[i].SendTerminateToThreads;
  end;
end;

procedure TWindowLayerBasicList.StartThreads;
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do begin
    Items[i].StartThreads;
  end;
end;

end.
