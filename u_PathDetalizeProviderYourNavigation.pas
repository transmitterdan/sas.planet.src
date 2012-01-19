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

unit u_PathDetalizeProviderYourNavigation;

interface

uses
  t_GeoTypes,
  i_VectorDataLoader,
  i_VectorItemLonLat,
  i_VectorItmesFactory,
  i_LanguageManager,
  i_ProxySettings,
  u_PathDetalizeProviderListEntity;

type
  TPathDetalizeProviderYourNavigation = class(TPathDetalizeProviderListEntity)
  private
    FFactory: IVectorItmesFactory;
    FBaseUrl: string;
    FProxyConfig: IProxyConfig;
    FKmlLoader: IVectorDataLoader;
  protected { IPathDetalizeProvider }
    function GetPath(ASource: ILonLatPath; var AComment: string): ILonLatPath; override;
  public
    constructor Create(
      AGUID: TGUID;
      ALanguageManager: ILanguageManager;
      AProxyConfig: IProxyConfig;
      AFactory: IVectorItmesFactory;
      AKmlLoader: IVectorDataLoader;
      ABaseUrl: string
    );
  end;

type
  TPathDetalizeProviderYourNavigationFastestByCar = class(TPathDetalizeProviderYourNavigation)
  protected
    function GetCaptionTranslated: string; override;
    function GetDescriptionTranslated: string; override;
    function GetMenuItemNameTranslated: string; override;
  public
    constructor Create(
      ALanguageManager: ILanguageManager;
      AProxyConfig: IProxyConfig;
      AFactory: IVectorItmesFactory;
      AKmlLoader: IVectorDataLoader
    );
  end;

type
  TPathDetalizeProviderYourNavigationShortestByCar = class(TPathDetalizeProviderYourNavigation)
  protected
    function GetCaptionTranslated: string; override;
    function GetDescriptionTranslated: string; override;
    function GetMenuItemNameTranslated: string; override;
  public
    constructor Create(
      ALanguageManager: ILanguageManager;
      AProxyConfig: IProxyConfig;
      AFactory: IVectorItmesFactory;
      AKmlLoader: IVectorDataLoader
    );
  end;

type
  TPathDetalizeProviderYourNavigationFastestByBicycle = class(TPathDetalizeProviderYourNavigation)
  protected
    function GetCaptionTranslated: string; override;
    function GetDescriptionTranslated: string; override;
    function GetMenuItemNameTranslated: string; override;
  public
    constructor Create(
      ALanguageManager: ILanguageManager;
      AProxyConfig: IProxyConfig;
      AFactory: IVectorItmesFactory;
      AKmlLoader: IVectorDataLoader
    );
  end;

type
  TPathDetalizeProviderYourNavigationShortestByBicycle = class(TPathDetalizeProviderYourNavigation)
  protected
    function GetCaptionTranslated: string; override;
    function GetDescriptionTranslated: string; override;
    function GetMenuItemNameTranslated: string; override;
  public
    constructor Create(
      ALanguageManager: ILanguageManager;
      AProxyConfig: IProxyConfig;
      AFactory: IVectorItmesFactory;
      AKmlLoader: IVectorDataLoader
    );
  end;

implementation

uses
  Classes,
  SysUtils,
  gnugettext,
  c_PathDetalizeProvidersGUID,
  i_EnumDoublePoint,
  u_GeoToStr,
  i_VectorDataItemSimple,
  u_InetFunc;

{ TPathDetalizeProviderYourNavigation }

constructor TPathDetalizeProviderYourNavigation.Create(
  AGUID: TGUID;
  ALanguageManager: ILanguageManager;
  AProxyConfig: IProxyConfig;
  AFactory: IVectorItmesFactory;
  AKmlLoader: IVectorDataLoader;
  ABaseUrl: string
);
begin
  inherited Create(AGUID, ALanguageManager);
  FBaseUrl := ABaseUrl;
  FProxyConfig := AProxyConfig;
  FFactory := AFactory;
  FKmlLoader := AKmlLoader;
end;

function TPathDetalizeProviderYourNavigation.GetPath(ASource: ILonLatPath; var AComment: string): ILonLatPath;
var
  ms:TMemoryStream;
  url:string;
  kml:IVectorDataItemList;
  s,VPointsCount:integer;
  conerr:boolean;
  add_line_arr_b:TArrayOfDoublePoint;
  VItem: IVectorDataItemLine;
  VPoints: TArrayOfDoublePoint;
  VCurrPoint: TDoublePoint;
  VPrevPoint: TDoublePoint;
  VEnum: IEnumLonLatPoint;
  VLine: ILonLatPathLine;
begin
  AComment := '';
  ms:=TMemoryStream.Create;
  try
    url := FBaseUrl;
    conerr:=false;
    VEnum := ASource.GetEnum;
    if VEnum.Next(VPrevPoint) then begin
      while VEnum.Next(VCurrPoint) do begin
        if conerr then Continue;
        url:=url+'&flat='+R2StrPoint(VPrevPoint.y)+'&flon='+R2StrPoint(VPrevPoint.x)+
            '&tlat='+R2StrPoint(VCurrPoint.y)+'&tlon='+R2StrPoint(VCurrPoint.x);
        if GetStreamFromURL(ms, url, 'text/xml', FProxyConfig.GetStatic)>0 then begin
          FKmlLoader.LoadFromStream(ms, kml);
          if kml <> nil then begin
            ms.SetSize(0);
            if kml.Count > 0 then begin
              if Supports(kml.GetItem(0), IVectorDataItemLine, VItem) then begin
                if VItem.Line.Count > 0 then begin
                  VLine := VItem.Line.Item[0];
                  VPointsCount := Length(VPoints);
                  if VPointsCount > 0 then begin
                    s := Length(add_line_arr_b);
                    SetLength(add_line_arr_b, (s + VLine.Count));
                    Move(VLine.Points^, add_line_arr_b[s], VLine.Count * sizeof(TDoublePoint));
                  end;
                end;
              end;
            end;
          end;
        end else begin
          conerr:=true;
        end;
        VPrevPoint := VCurrPoint;
      end;
    end;
  finally
    ms.Free;
  end;
  if not conerr then begin
    Result := FFactory.CreateLonLatPath(@add_line_arr_b[0], Length(add_line_arr_b));
  end;
end;

{ TPathDetalizeProviderYourNavigationFastestByCar }

constructor TPathDetalizeProviderYourNavigationFastestByCar.Create(
  ALanguageManager: ILanguageManager;
  AProxyConfig: IProxyConfig;
  AFactory: IVectorItmesFactory;
  AKmlLoader: IVectorDataLoader
);
begin
  inherited Create(
    CPathDetalizeProviderYourNavigationFastestByCar,
    ALanguageManager,
    AProxyConfig,
    AFactory,
    AKmlLoader,
    'http://www.yournavigation.org/api/1.0/gosmore.php?format=kml&v=motorcar&fast=1&layer=mapnik'
  );
end;

function TPathDetalizeProviderYourNavigationFastestByCar.GetCaptionTranslated: string;
begin
  Result := _('By car (Fastest) with yournavigation.org');
end;

function TPathDetalizeProviderYourNavigationFastestByCar.GetDescriptionTranslated: string;
begin
  Result := _('Detalize route by car (Fastest) with yournavigation.org');
end;

function TPathDetalizeProviderYourNavigationFastestByCar.GetMenuItemNameTranslated: string;
begin
  Result := _('yournavigation.org (OSM)') + '|0030~\' +  _('By Car (Fastest)') + '|0010';
end;

{ TPathDetalizeProviderYourNavigationShortestByCar }

constructor TPathDetalizeProviderYourNavigationShortestByCar.Create(
  ALanguageManager: ILanguageManager;
  AProxyConfig: IProxyConfig;
  AFactory: IVectorItmesFactory;
  AKmlLoader: IVectorDataLoader
);
begin
  inherited Create(
    CPathDetalizeProviderYourNavigationShortestByCar,
    ALanguageManager,
    AProxyConfig,
    AFactory,
    AKmlLoader,
    'http://www.yournavigation.org/api/1.0/gosmore.php?format=kml&v=motorcar&fast=0&layer=mapnik'
  );
end;

function TPathDetalizeProviderYourNavigationShortestByCar.GetCaptionTranslated: string;
begin
  Result := _('By car (Shortest) with yournavigation.org');
end;

function TPathDetalizeProviderYourNavigationShortestByCar.GetDescriptionTranslated: string;
begin
  Result := _('Detalize route by car (Shortest) with yournavigation.org');
end;

function TPathDetalizeProviderYourNavigationShortestByCar.GetMenuItemNameTranslated: string;
begin
  Result := _('yournavigation.org (OSM)') + '|0030~\' +  _('By Car (Shortest)') + '|0020';
end;

{ TPathDetalizeProviderYourNavigationFastestByBicycle }

constructor TPathDetalizeProviderYourNavigationFastestByBicycle.Create(
  ALanguageManager: ILanguageManager;
  AProxyConfig: IProxyConfig;
  AFactory: IVectorItmesFactory;
  AKmlLoader: IVectorDataLoader
);
begin
  inherited Create(
    CPathDetalizeProviderYourNavigationFastestByBicycle,
    ALanguageManager,
    AProxyConfig,
    AFactory,
    AKmlLoader,
    'http://www.yournavigation.org/api/1.0/gosmore.php?format=kml&v=bicycle&fast=1&layer=mapnik'
  );
end;

function TPathDetalizeProviderYourNavigationFastestByBicycle.GetCaptionTranslated: string;
begin
  Result := _('By bicycle (Fastest) with yournavigation.org');
end;

function TPathDetalizeProviderYourNavigationFastestByBicycle.GetDescriptionTranslated: string;
begin
  Result := _('Detalize route by bicycle (Fastest) with yournavigation.org');
end;

function TPathDetalizeProviderYourNavigationFastestByBicycle.GetMenuItemNameTranslated: string;
begin
  Result := _('yournavigation.org (OSM)') + '|0030~\' +  _('By Bicycle (Fastest)') + '|0030';
end;

{ TPathDetalizeProviderYourNavigationShortestByBicycle }

constructor TPathDetalizeProviderYourNavigationShortestByBicycle.Create(
  ALanguageManager: ILanguageManager;
  AProxyConfig: IProxyConfig;
  AFactory: IVectorItmesFactory;
  AKmlLoader: IVectorDataLoader
);
begin
  inherited Create(
    CPathDetalizeProviderYourNavigationShortestByBicycle,
    ALanguageManager,
    AProxyConfig,
    AFactory,
    AKmlLoader,
    'http://www.yournavigation.org/api/1.0/gosmore.php?format=kml&v=bicycle&fast=0&layer=mapnik'
  );
end;

function TPathDetalizeProviderYourNavigationShortestByBicycle.GetCaptionTranslated: string;
begin
  Result := _('By bicycle (Shortest) with yournavigation.org');
end;

function TPathDetalizeProviderYourNavigationShortestByBicycle.GetDescriptionTranslated: string;
begin
  Result := _('Detalize route by bicycle (Shortest) with yournavigation.org');
end;

function TPathDetalizeProviderYourNavigationShortestByBicycle.GetMenuItemNameTranslated: string;
begin
  Result := _('yournavigation.org (OSM)') + '|0030~\' +  _('By Bicycle (Shortest)') + '|0040';
end;

end.
