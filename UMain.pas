{
  GAME OPEN SOURCE
  AUTOR: ANTONIO SERGIO - sergiosvieira@hotmail.com
  COMPONENTES: DELPHIX
  COMPILADO  : DELPHI 3.0
  http://www15.brinkster.com/djddelphi
}
unit UMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  DXClass, DXSprite, DXInput, DXDraws, ExtCtrls, StdCtrls, DXSounds;

type
  TFmMain = class(TDXForm)
    DXDraw1: TDXDraw;
    DXImageList1: TDXImageList;
    DXInput1: TDXInput;
    DXSpriteEngine1: TDXSpriteEngine;
    DXTimer1: TDXTimer;
    Panel1: TPanel;
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    Label2: TLabel;
    DXWaveList1: TDXWaveList;
    DXSound1: TDXSound;
    procedure FormCreate(Sender: TObject);
    procedure DXTimer1Timer(Sender: TObject; LagCount: Integer);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TPlayer = class(TImageSprite)
  protected
    procedure DoCollision(Sprite: TSprite; var Done: Boolean);override;
    procedure DoMove(MoveCount: Integer); override;
  end;
  TBall = class(TImageSprite)
  //(-1{cima},1{baixo},-2{esquerda},2{direita});
    SentidoX,SentidoY: Integer;
    Speed: double;
  protected
    procedure DoCollision(Sprite: TSprite; var Done: Boolean);override;
    procedure DoMove(MoveCount: Integer); override;
  public
    constructor Create(AParent: TSprite); override;
  end;
  TBloco = class(TImageSprite)
  protected
    procedure DoCollision(Sprite: TSprite; var Done: Boolean);override;
    procedure DoMove(MoveCount: Integer); override;
  end;
  TPosition = record
               x,y: integer;
               vivo: boolean;
             end;
type
  TGameScene = (
    gsNone,
    gsLoad,
    gsTitle,
    gsMain,
    gsGameOver
  );

  TVidas = object
    Numero: Integer;
  public
    procedure Aumentar;
    procedure Diminuir;
  end;


const
  N = 58;
  V = 20;

var
  Tempo,TempoAtual: DWord;
  Score: Integer;
  FIM: Boolean;
  Vida: TVidas;
  NB : Integer;
  Stage: Integer;
  FmMain: TFmMain;
  Player: TPlayer;
  Ball  : TBall;
  BackGround: TBackGroundSprite;
  Blocos: array[0..N] of TBloco;
  BlocosPos: array[0..N] of TPosition;
  GameScene: TGameScene;
  Blink,BlinkTime: DWord;
  BL,BG: String;
  PMX,PMY   : Integer; {Ponto Medio da Bola}
  Fase1: array[0..N] of integer = (
                                   1,0,0,0,1,0,0,0,1,-1,
                                   0,1,0,1,0,1,0,1,0,-1,
                                   0,0,1,0,1,0,1,0,0,-1,
                                   0,1,0,1,0,1,0,1,0,-1,
                                   1,0,1,0,1,0,1,0,1,-1,
                                   0,1,0,1,0,1,0,1,0
                                  );
  Fase2: array[0..N] of integer = (
                                   1,1,1,1,1,1,1,1,1,0,
                                   1,0,1,0,0,0,1,0,1,0,
                                   1,0,0,1,0,1,0,0,1,0,
                                   1,0,0,0,1,0,0,0,1,-1,
                                   1,0,0,0,1,0,0,0,1,-1,
                                   1,1,1,1,1,1,1,1,1
                                  );

  Fase3: array[0..N] of integer = (
                                   1,0,0,1,1,1,1,0,1,-1,
                                   0,1,0,0,1,0,1,0,1,-1,
                                   0,0,1,0,0,1,0,0,1,-1,
                                   1,1,0,1,1,0,1,1,0,-1,
                                   1,1,0,1,1,0,1,0,1,-1,
                                   1,1,0,1,0,1,0,1,0
                                  );
  Fase4: array[0..N] of integer = (
                                   1,1,1,1,1,1,1,1,1,-1,
                                   1,1,1,1,1,1,1,1,1,-1,
                                   0,1,0,1,0,1,0,1,0,-1,
                                   1,0,1,0,1,0,1,0,1,-1,
                                   1,1,1,1,1,1,1,1,1,-1,
                                   1,1,1,1,1,1,1,1,1
                                  );
  Fase5: array[0..N] of integer = (
                                   1,1,1,1,1,1,1,1,1,-1,
                                   1,0,1,0,1,0,1,0,1,-1,
                                   1,1,1,1,1,1,1,1,1,-1,
                                   0,1,0,1,0,1,0,1,0,-1,
                                   1,1,1,1,1,1,1,1,1,-1,
                                   1,0,1,0,1,0,1,0,1
                                  );

implementation

{$R *.DFM}

type
  TGame = record
            Fase  : Integer;
            BG,BL : Integer;
          end;

procedure TVidas.Aumentar;
begin
  Inc(Numero);
end;

procedure TVidas.Diminuir;
begin
  Dec(Numero);
end;

procedure CarregarPosFase(fase: array of integer);
var
  i,ii,iii: integer;
begin
  ii:=0;iii:=0;
  NB:= 0;
  for i:= 0 to N do
      begin
        if ii>9 then
           begin
             ii:= 0;
             inc(iii);
           end;
        if Fase[i]=1 then
           begin
             BlocosPos[i].x:= ii  * 35;
             BlocosPos[i].y:= iii * 35;
             BlocosPos[i].vivo:= true;
             Inc(NB);
           end
        else
           BlocosPos[i].vivo:= false;
        if BlocosPos[i].x>320 - 35 then
           BlocosPos[i].vivo:= false;
        inc(ii);
      end;
end;

procedure CarregarFase(f: integer);
begin
  case f of
       1:begin
           CarregarPosFase(Fase1);
           BG:= 'bg1';BL:='bl1';
         end;
       2:begin
           CarregarPosFase(Fase2);
           BG:= 'bg2';BL:='bl2';
         end;
       3:begin
           CarregarPosFase(Fase3);
           BG:= 'bg3';BL:='bl3';
         end;
       4:begin
           CarregarPosFase(Fase4);
           BG:= 'bg4';BL:='bl4';
         end;
       5:begin
           CarregarPosFase(Fase5);
           BG:= 'bg5';BL:='bl5';
         end;
  end;
end;

procedure CriarFase(f:integer);
var
 i: Integer;
begin
  CarregarFase(f);
  for i:= 0 to N  do
       begin
         if BlocosPos[i].vivo then
         begin
         Blocos[i]:= TBloco.Create(FmMain.DXSpriteEngine1.Engine);
         with Blocos[i] do
              begin
                Image:= FmMain.DXImageList1.Items.Find(BL);
                Width := Image.Width;
                Height:= Image.Height;
                Z:= 1;
                X:= BlocosPos[i].x;
                Y:= BlocosPos[i].y;
              end;
         end;
       end;
end;

procedure DestruirFase;
var
  i: integer;
begin
  for i:= 0 to N do
      if BlocosPos[i].vivo then
         try
           Blocos[i].Dead;
         except
         end;
end;

procedure TBloco.DoCollision;
begin
  inherited DoCollision(Sprite,Done);
  //(-1{cima},1{baixo},-2{esquerda},2{direita});
  if (Sprite is TBall) then
     begin
       FmMain.DXWaveList1.Items.Find('tick2').Play(false);
       if (PMX<X) and (PMX<X+Width) then
          begin
            //FmMain.Label2.Caption:= 'esquerda';
            TBall(Sprite).SentidoX:= TBall(Sprite).SentidoX * -1;
          end;
       if (PMX>X) and (PMX>X+Width) then
          begin
            //FmMain.Label2.Caption:= 'direita';
            TBall(Sprite).SentidoX:= TBall(Sprite).SentidoX * -1;
          end;
       if (PMY<Y) and (PMY<Y+Height) then
          begin
            //FmMain.Label2.Caption:= 'cima';
            TBall(Sprite).SentidoY:= TBall(Sprite).SentidoY * -1;
          end;
       if (PMY>Y) and (PMY>Y+Height) then
          begin
            //FmMain.Label2.Caption:= 'baixo';
           TBall(Sprite).SentidoY:= TBall(Sprite).SentidoY * -1;
          end;
       Inc(Score,100);
       Dead;
       Dec(NB);
     end;
end;

procedure TBloco.DoMove;
begin
  inherited;
  Collision;
end;

procedure TPlayer.DoCollision;
begin
  inherited;
end;

procedure TPlayer.DoMove;
begin
  inherited DoMove(MoveCount);
  if isLeft in FmMain.DXInput1.States then
     X:= X - (500/1000)*MoveCount;
  if isRight in FmMain.DXInput1.States then
     X:= X + (500/1000)*MoveCount;
  if X<0 then
     X:= 0;
  if X + Width > FmMain.DXDraw1.Width - 1 then
     X:= FmMain.DXDraw1.Width - Width - 1;
  //Collision;
end;

constructor TBall.Create;
begin
  inherited Create(AParent);
  Image:= FmMain.DXImageList1.Items.Find('Bola');
  Width := Image.Width;
  Height:= Image.Height;
  AnimCount:= Image.PatternCount;
  AnimLooped:= True;
  AnimSpeed:= 0.05;
end;

procedure TBall.DoMove;
begin
  inherited DoMove(MoveCount);
  //(-1{cima},1{baixo},-2{esquerda},2{direita});
  if SentidoY = -1 then
     Y:= Y - (600/1000)*MoveCount*speed;
  if SentidoY = 1 then
     Y:= Y + (600/1000)*MoveCount*speed;
  if SentidoX = -2 then
     X:= X - (600/1000)*MoveCount*speed;
  if SentidoX = 2 then
     X:= X + (600/1000)*MoveCount*speed;

  if X<=1 then
     begin
       SentidoX:= 2;
       //Speed:= 1;
     end;
  if X+Width>=FmMain.DXDraw1.Width - 1 then
     begin
       SentidoX:= -2;
       //Speed:= 1;
     end;
  if Y<=1 then
     SentidoY:= 1;
  if Y>=FmMain.DXDraw1.Height - 1 then
     begin
       Ball.X:= Player.X;
       Ball.Y:= Player.Y - Ball.Height;
       Ball.SentidoX:= -2;
       Ball.SentidoY:= -1;
       Ball.Speed:= 1;
       Vida.Diminuir;
       if Vida.Numero=0 then
          GameScene:= gsGameOver;
     end;
  Collision;
  PMX:= Trunc(X + Width div 2);
  PMY:= Trunc(Y + Height div 2);
end;

procedure TBall.DoCollision;
begin
  inherited DoCollision(Sprite,Done);
  if (Sprite is TPlayer) then
     begin
       FmMain.DXWaveList1.Items.Find('tick').Play(false);
     if (PMY<TPlayer(Sprite).Y) and (PMY<TPlayer(Sprite).Y + TPlayer(Sprite).Height) then
        SentidoY:= -1;
     if (PMX<TPlayer(Sprite).X) and (PMX<TPlayer(Sprite).X + TPlayer(Sprite).Width) then
        begin
          SentidoX:= -2;
          if Speed >= 2.0 then
             Speed:= 2.0
          else
             Speed:= Speed + 0.3;
        end;
     if (PMX>TPlayer(Sprite).X) and (PMX>TPlayer(Sprite).X + TPlayer(Sprite).Width) then
        begin
          SentidoX:= 2;
          if Speed >= 2.0 then
             Speed:= 2.0
          else
             Speed:= Speed + 0.3;
        end;
{
       if SentidoY=-1 then
          SentidoY:= SentidoY * -1
       else
          if SentidoY=1 then
             SentidoY:= SentidoY * -1;;
       if (PMX<Player.X+5) then
          begin
            SentidoX:= SentidoX * -1;
            if Speed >= 2.0 then
               Speed:= 2.0
            else
               Speed:= Speed + 0.3;
          end;
       if (PMX>Player.X+Player.Width-5) then
          begin
            SentidoX:= SentidoX * -1;
            if Speed >= 2.0 then
               Speed:= 2.0
            else
               Speed:= Speed + 0.3;
          end;
          }
     end;
end;

procedure TFmMain.FormCreate(Sender: TObject);
var
  i,ii: Integer;
begin
  Score:= 0;
  Vida.Numero:= 3;
  Label2.Caption:= InttoStr(Vida.Numero);
  Fim:= False;
  Stage:= 1;
  Blink:= 0;
  GameScene:= gsTitle;
  ii:= 0;
  DXImageList1.Items.MakeColorTable;
  DXDraw1.ColorTable:= DXImageList1.Items.ColorTable;
  DXDraw1.DefColorTable:= DXImageList1.Items.ColorTable;
  DXDraw1.UpdatePalette;

  CriarFase(Stage);


  BackGround:= TBackGroundSprite.Create(FmMain.DXSpriteEngine1.Engine);
  with BackGround do
       begin
         SetMapSize(1,1);
         Z:= 0;
         Image:= FmMain.DXImageList1.Items.Find(BG);
         Tile:= True;
       end;


  Player:= TPlayer.Create(DXSpriteEngine1.Engine);
  with Player do
       begin
         Image:= DXImageList1.Items.Find('Player');
         Width := Image.Width;
         Height:= Image.Height;
         Z:= 2;
         X:= 140;
         Y:= FmMain.ClientHeight - Height - 1;
       end;

  Ball:= TBall.Create(DXSpriteEngine1.Engine);
  Ball.Z:= 2;
  Ball.X:= Player.X;
  Ball.Y:= Player.Y - Ball.Height;
  Ball.SentidoX:= -2;
  Ball.SentidoY:= -1;
  Ball.Speed:= 1;
//  Ball.PixelCheck:= True;
end;

procedure TFmMain.DXTimer1Timer(Sender: TObject; LagCount: Integer);
var
  Logo,Press,CopyRight,Completed,GameOver: TPictureCollectionItem;
  W,i: Integer;
begin
  if not DXDraw1.CanDraw then
     Exit;
  if GetTickCount<>TempoAtual then
     begin
       Tempo := Tempo + (GetTickCount-TempoAtual);
       TempoAtual := GetTickCount;
     end;
  Label2.Caption:= inttostr(Vida.Numero);
  Label1.Caption:= inttostr(Score);
  BlinkTime:= GetTickCount;
  TempoAtual:= GetTickCount;
  DXInput1.Update;
  DXDraw1.Surface.Fill(0);
  case GameScene of
  gsLoad :
       begin
             Completed:= DXImageList1.Items.Find('complete');
             Completed.Draw(DXDraw1.Surface,(DXDraw1.Width - Completed.Width) div 2,
                            100,0);
             if (Tempo div 3000=1) then
                begin
                  Fim:= False;
                  CriarFase(Stage);
                  BackGround.Image:= DXImageList1.Items.Find(BG);
                  Ball.Speed:= 1;
                  Ball.X:= Player.X;
                  Ball.Y:= Player.Y - Ball.Height;
                  Ball.SentidoX:= -2;
                  Ball.SentidoY:= -1;
                  GameScene:= gsMain;
                end;
             //DXSpriteEngine1.DXDraw.Initialize;
           end;

  gsTitle:
       begin
         DXDraw1.Surface.Fill(0);

         Logo := DXImageList1.Items.Find('Logo');
         Logo.DrawWaveX(DXDraw1.Surface, 30, 80, Logo.Width, Logo.Height, 0,
           Trunc(16-Cos256(BlinkTime div 60)*16), 32, -BlinkTime div 5);

         Press := DXImageList1.Items.Find('press');
         W:= Press.Width;
         if (Blink div 300) mod 2=0 then
            Press.Draw(DXDraw1.Surface,(DXDraw1.Width - W) div 2,150,0);

         CopyRight := DXImageList1.Items.Find('sergio');
         W:= CopyRight.Width;
         CopyRight.Draw(DXDraw1.Surface,(DXDraw1.Width - W) div 2,300,0);

         if isButton1 in DXInput1.States then
            begin
              GameScene:= gsMain;
            end;
         if GetTickCount<>BlinkTime then
            begin
              Blink := Blink + (GetTickCount-BlinkTime);
              BlinkTime := GetTickCount;
            end;

       end;
  gsMain :
       begin
         //Tempo:= 0;
         DXSpriteEngine1.Engine.Move(5);
         DxSpriteEngine1.Engine.Dead;
           with DXDraw1.Surface.Canvas do
           begin
             Brush.Style := bsClear;
             Font.Color := clWhite;
             Font.Size := 12;
             if NB=0 then
                begin
                  inc(Stage);
                  if Stage>5 then
                     GameScene:= gsGameOver;
                  Tempo:= 0;
                  GameScene:= gsLoad;
                end;
             Release;
           end;
         if GameScene<>gsLoad then
            DXSpriteEngine1.Draw;
       end;
  gsGameOver:
       begin
         Gameover:= DXImageList1.Items.Find('gameover');
         GameOver.Draw(DXDraw1.Surface,(DXDraw1.Width - GameOver.Width) div 2,100,0);
         Press := DXImageList1.Items.Find('press');
         W:= Press.Width;
         Press.Draw(DXDraw1.Surface,(DXDraw1.Width - W) div 2,150,0);
         if isButton1 in DXInput1.States then
            begin
              Score:= 0;
              DestruirFase;

              Vida.Numero:= 3;
              Label2.Caption:= InttoStr(Vida.Numero);
              Fim:= False;
              Stage:= 1;
              Blink:= 0;
              GameScene:= gsTitle;
              CriarFase(Stage);
              BackGround.Image:= DXImageList1.Items.Find('bg1');
              GameScene:= gsTitle;
            end;
       end;
  end;
//  FmMain.Label2.Caption:= inttostr(tempo);
  DXDraw1.Flip;
end;

procedure TFmMain.FormShow(Sender: TObject);
begin
  DXWaveList1.Items.Find('music').Play(false);
end;

end.
