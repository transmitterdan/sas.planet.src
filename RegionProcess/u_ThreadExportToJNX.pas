unit u_ThreadExportToJNX;

interface

uses
  SysUtils,
  Classes,
  JNXlib,
  GR32,
  t_GeoTypes,
  i_VectorItemLonLat,
  i_CoordConverterFactory,
  i_VectorItmesFactory,
  u_MapType,
  u_ResStrings,
  u_ThreadExportAbstract;

type
  TThreadExportToJnx = class(TThreadExportAbstract)
  private
    FMapType: TMapType;
    FTargetFile: string;
    FCoordConverterFactory: ICoordConverterFactory;
    FProjectionFactory: IProjectionInfoFactory;
    FVectorItmesFactory: IVectorItmesFactory;
    FProductName: string; // ��������
    FMapName : string;  // ��� �����
    FJNXversion : byte;  // 3..4
    FZorder : integer;   // ��� 4 ������
    FProductID : integer; // 0,2,3,4,5,6,7,8,9
    FJpgQuality : byte ; // 10..100 TODO
  protected
    procedure ProcessRegion; override;
  public
    constructor Create(
      ACoordConverterFactory: ICoordConverterFactory;
      AProjectionFactory: IProjectionInfoFactory;
      AVectorItmesFactory: IVectorItmesFactory;
      ATargetFile: string;
      APolygon: ILonLatPolygon;
      Azoomarr: array of boolean;
      AMapType: TMapType;
      AProductName : string;
      AMapName : string;
      AJNXVersion : integer;
      AZorder : integer;
      AProductID : integer;
      AJpgQuality : byte
    );
  end;

implementation

uses
  Types,
  c_CoordConverter,
  i_CoordConverter,
  i_TileIterator,
  i_VectorItemProjected,
  i_BitmapTileSaveLoad,
  u_BitmapTileVampyreSaver,
  u_TileIteratorByPolygon;

constructor TThreadExportToJnx.Create(
  ACoordConverterFactory: ICoordConverterFactory;
  AProjectionFactory: IProjectionInfoFactory;
  AVectorItmesFactory: IVectorItmesFactory;
  ATargetFile: string;
  APolygon: ILonLatPolygon;
  Azoomarr: array of boolean;
  AMapType: TMapType;
  AProductName : string;
  AMapName : string;
  AJNXVersion : integer;
  AZorder : integer;
  AProductID : integer;
  AJpgQuality : byte
);
begin
  inherited Create(APolygon, Azoomarr);
  FTargetFile := ATargetFile;
  FMapType := AMapType;
  FCoordConverterFactory := ACoordConverterFactory;
  FProjectionFactory := AProjectionFactory;
  FVectorItmesFactory := AVectorItmesFactory;
  FProductName := AProductName;
  FMapName := AMapName;
  FJNXVersion := AJNXVersion;
  FZorder := AZorder;
  FProductID := AProductID;
  FJpgQuality := AJpgQuality;
end;

procedure TThreadExportToJnx.ProcessRegion;
var
  i: integer;
  VBmp: TCustomBitmap32;
  VZoom: Byte;
  VTile: TPoint;
  VTileIterators: array of ITileIterator;
  VTileIterator: ITileIterator;
  VSaver: IBitmapTileSaver;
  VMemStream: TMemoryStream;
  VGeoConvert: ICoordConverter;
  VStringStream: TStringStream;
  VWriter: TJNXWriter;
  VTileBounds: TJNXRect;
  VTopLeft: TDoublePoint;
  VBottomRight: TDoublePoint;
  VProjectedPolygon: IProjectedPolygon;
begin
  inherited;
  FTilesToProcess := 0;
  VSaver := TVampyreBasicBitmapTileSaverJPG.Create(FJpgQuality);
  VGeoConvert := FCoordConverterFactory.GetCoordConverterByCode(CGELonLatProjectionEPSG, CTileSplitQuadrate256x256);
  SetLength(VTileIterators, Length(FZooms));
  for i := 0 to Length(FZooms) - 1 do begin
    VZoom := FZooms[i];
    VProjectedPolygon :=
      FVectorItmesFactory.CreateProjectedPolygonByLonLatPolygon(
        FProjectionFactory.GetByConverterAndZoom(
          VGeoConvert,
          VZoom
        ),
        PolygLL
      );
    VTileIterators[i] := TTileIteratorByPolygon.Create(VProjectedPolygon);
    FTilesToProcess := FTilesToProcess + VTileIterators[i].TilesTotal;
  end;

  VWriter := TJNXWriter.Create(FTargetFile);
  try
    VWriter.Levels := Length(FZooms);
    for i := 0 to Length(FZooms) - 1 do begin
      VWriter.LevelScale[i] := DigitalGlobeZoomToScale(FZooms[i]);
      VWriter.TileCount[i]  := VTileIterators[i].TilesTotal;
      VWriter.ProductName := FProductName;
      VWriter.MapName :=  FmapName;
      VWriter.Version := FJNXVersion;
      VWriter.ZOrder := FZorder;
      VWriter.LevelCopyright[i] := '(c) '+FMapName+' ['+inttostr(i)+']';
      VWriter.LevelDescription[i] :='Level ['+ inttostr(i)+']';
      VWriter.LevelName[i] := 'Name ['+inttostr(i)+']';
      VWriter.LevelZoom[i] := FZooms[i];
      VWriter.ProductID := FProductID;
    end;

    try
      ProgressFormUpdateCaption(
        SAS_STR_ExportTiles,
        SAS_STR_AllSaves + ' ' + inttostr(FTilesToProcess) + ' ' + SAS_STR_Files
      );
      VMemStream := TMemoryStream.Create;
      VStringStream := TStringStream.Create('');
      VBmp := TCustomBitmap32.Create;
      try
        FTilesProcessed := 0;
        ProgressFormUpdateOnProgress;
        for i := 0 to Length(FZooms) - 1 do begin
          VZoom := FZooms[i];
          VTileIterator := VTileIterators[i];
          while VTileIterator.Next(VTile) do begin
            if CancelNotifier.IsOperationCanceled(OperationID) then begin
              exit;
            end;
            VBmp.Clear;
            if FMapType.LoadTileUni(VBmp, VTile, VZoom, VGeoConvert, False, False, True) then begin
              VMemStream.Clear;
              VMemStream.Position := 0;
              VSaver.SaveToStream(VBmp, VMemStream);

              VTopLeft := VGeoConvert.TilePos2LonLat(Point(VTile.X , VTile.Y + 1), VZoom);
              VBottomRight := VGeoConvert.TilePos2LonLat( Point(VTile.X+1 , VTile.Y), VZoom);

              VTileBounds := JNXRect(
                WGS84CoordToJNX(VBottomRight.Y),
                WGS84CoordToJNX(VBottomRight.X),
                WGS84CoordToJNX(VTopLeft.Y),
                WGS84CoordToJNX(VTopLeft.X)
              );

              VMemStream.Position := 0;
              VStringStream.Size := 0;
              VStringStream.CopyFrom(VMemStream, 0);

              VWriter.WriteTile(
                I,
                256,
                256,
                VTileBounds,
                VStringStream.DataString
              );

            end;
            inc(FTilesProcessed);
            if FTilesProcessed mod 100 = 0 then begin
              ProgressFormUpdateOnProgress;
            end;
          end;
        end;
      finally
        VMemStream.Free;
        VStringStream.Free;
        VBmp.Free;
      end;
    finally
      for i := 0 to Length(FZooms) - 1 do begin
        VTileIterators[i] := nil;
      end;
      VTileIterators := nil;
    end;
    ProgressFormUpdateOnProgress;
  finally
    VWriter.Free;
  end;
end;

end.
