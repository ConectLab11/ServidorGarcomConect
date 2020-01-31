unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  IniFiles, uLkJSON,
  System.Win.ScktComp, rcs_sql_mobile, rcs_myclient, rcs_str_mobile, rcs_pr3000_mobile, rcs_objs_mobile, rcs_ident_mobile,
  rcs_cryp_mobile, rcs_estoq_mobile, rcs_print_mobile, rcs_cupom, rcs_sat_ext,
  Vcl.ExtCtrls;

type
    TIAtendente = class
        id,
        cadastro,
        nome:String;
end;

type
    TAtendentes = class
       Users:Array of TIAtendente;

       procedure Add(id,codigo,nome:String);
       function idAtendente(codigo:String):String;
       function codigoAtendente(id:String):String;
end;

type
    TimpGrp = class
      id,
      descricao:String;
      marcado:Boolean;
end;

type
    TimpItem = class
        id,
        descricao,
        porta,
        spooler:String;
        padrao,
        gerenciado:Boolean;
        grupos:String;
        botao_id:String;
        caixa:Boolean;
        gLista:Array of TimpGrp;
        idCfg:String;
        CN:TCISStatus;
        filtros,
        filtrog:TStringList;

    procedure filtraGrupo(id:String);
end;

type
    Timpressoras = class
       lista:Array of TimpItem;

       procedure limpar();
end;

type
    TrcsTerminais = class
    private
        lista:Array of TrcsCnService;
        function Add(cn:TCustomWinSocket):Boolean;
        function Count():Integer;
        procedure Del(cn:TCustomWinSocket);
end;

type
  TConectLabMobile64 = class(TService)
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceBeforeInstall(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    function Init():Boolean;
    procedure OnServerListen(Sender: TObject; Socket: TCustomWinSocket);
    procedure OnServerClientConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure OnServerClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure OnServerClientRead(Sender: TObject;Socket: TCustomWinSocket);
    procedure OnServerClienteError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);

    procedure notificar_todos_terminais(id,cmd:String);
    procedure notificar_terminal(xTCP:TrcsCnService;jsonTxt:String='');

    procedure carregarImp();
    function statusFormato():String;
    procedure respostaHttp(cnTCP:TrcsCnService;Socket:TCustomWinSocket;erro_:Integer;d:String;jsonTxt:String='');
    function posiciona_terminal(id:String):TrcsCnService;
    procedure rcs_iniciar_variaveis_globais();
    procedure imprimir_pre_conta(xTCP:TrcsCnService;id,cUser,cTerminal:String;gDados:WideString);
    function totalizar_produtos_pedidos(id:String;cn:TMyClient):String;
    procedure perfilImpressora(id:String;cn:TMyClient);
    function decifrar(dc:String):string;
    function confereStatus(p:Integer;Log:Boolean=False):Boolean;
    procedure manutencao_impressoras(xTCP:TrcsCnService;nSessao:String);
    procedure imprimir_producao(xTCP:TrcsCnService;id,cUser,cTerminal,nHora,nSessao:String;notifica:Boolean=True);
    function check_duplicidade_producao(id:String;ids:TStringList):Boolean;
    procedure registrar_pedidos_json(xTCP:TrcsCnService;jsonTxt:WideString);


    procedure servico_status(xTCP:TrcsCnService;jsonTxt:WideString);
    procedure servico_mysql(xTCP:TrcsCnService;jsonTxt:WideString);
    procedure servico_login(xTCP:TrcsCnService;jsonTxt:WideString);
    procedure servico_logoff(xTCP:TrcsCnService;jsonTxt:WideString);
    function TokenValido(ntoken:String):Boolean;
    procedure GOERROS(var xtcp:TrcsCnService;xjson:String;var msgJson:WideString;opr_,code_,msg_:String;exc_:String='');

  private
    { Private declarations }

      PASTA_CACHE:String;

      ULTIMAS_PRODUCAO:Array[0..20] of String;

      tempoINI,
      tempoMED,
      tempoEND:Cardinal;

      FLUSHLINK        :Integer;

      BLOQUEIO_AUTOMATICO,
      USUARIO_LOGADO   :Boolean;
      TIMER_LOGADO     :Integer;


      SRV_USER:TrcsTerminais;
      SRV_TCP :TServerSocket;
      CLI_TCP :TClientSocket;

      PED_QTDES,
      PED_VALOR,
      PED_TOTAL:String;

      CEL_USUARIO_POR_VEZ:Boolean;
      LIMITE_CONTAR_PEDIDOS,
      CONTAR_PEDIDOS     :Integer;
      REINICIAR_TUDO     :Word;
      REGIME_TRIB_ICMS:Integer;

      ATENDENTES:TAtendentes;
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

//const


var
  ConectLabMobile64: TConectLabMobile64;

   VERSAO_APP :Integer = 1;
   VERSAO_COMP:Integer = 15;
   VERSAO_DATA:String  = '17/12/2019 20:06';
 {$IFDEF WIN64}
   VERSAO_BITS:String  = '64';
 {$ELSE}
   VERSAO_BITS:String  = '32';
 {$ENDIF}

   ARQINI     :String;
   APP_TIMEOUT,
   LOG_TIMEOUT:Integer;

   COMANDA_RAPIDA       :Boolean = False;
   COMANDA_PEDIDO_BALCAO:Boolean = False;
   COMANDA_DESCRICAO    :String  = 'Mesas';

   LPRINT:TImpressoras;
   SERVICE_MOB_INIT:Integer = 0;

const
   DiaSemana: array[1..7] of string =
   ('Sunday','Monday','Tusday','Wednesday','Thursday','Friday','Saturday');
   DiaMes: array[1..12] of string =
   ('Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro');

// These strings are NOT to be resourced

  Months: array[1..12] of string = (
    'Jan', 'Feb', 'Mar', 'Apr',
    'May', 'Jun', 'Jul', 'Aug',
    'Sep', 'Oct', 'Nov', 'Dec');
  DaysOfWeek: array[1..7] of string = (
    'Sun', 'Mon', 'Tue', 'Wed',
    'Thu', 'Fri', 'Sat');

implementation

{$R *.dfm}

procedure SET_VERSAO(valor1:Integer;valor2:Integer;valor3:String);
begin
     VERSAO_APP :=valor1;
     VERSAO_COMP:=valor2;
     VERSAO_DATA:=valor3;
end;

function GET_VERSAO():String;
begin
     result:=IntToStr(VERSAO_APP) + '.' + IntToStr(VERSAO_COMP) + '.' + VERSAO_DATA;
end;


procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  ConectLabMobile64.Controller(CtrlCode);
end;

function TConectLabMobile64.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TConectLabMobile64.ServiceAfterInstall(Sender: TService);
//var
//  regEdit : TRegistry;
begin
 (*
  regEdit := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    regEdit.RootKey := HKEY_LOCAL_MACHINE;

    if regEdit.OpenKey('\SYSTEM\CurrentControlSet\Services\' + Name,False) then
    begin
      regEdit.WriteString('Description','ConectLab Mobile Server');
      regEdit.CloseKey;
    end;

  finally
    FreeAndNil(regEdit);
  end;
  *)
end;

procedure TConectLabMobile64.ServiceBeforeInstall(Sender: TService);
begin
     Self.DisplayName := 'ConectLab Mobile Server ' + VERSAO_BITS;
end;

procedure TConectLabMobile64.ServiceStart(Sender: TService;
  var Started: Boolean);
begin
     Init();
     Started:=True;
end;

procedure TConectLabMobile64.ServiceStop(Sender: TService; var Stopped: Boolean);
var
   i:Integer;
begin
     try

          SRV_TCP.FreeOnRelease;
          SRV_USER.Free;
          SRV_USER:=nil;

          for i:=0 to high(LPRINT.lista) do
          begin
          //if LPRINT.lista[i].botao <> nil then
          //begin
          //     LPRINT.lista[i].botao.FreeOnRelease;
          //     LPRINT.lista[i].botao:=nil;
          //end;

              if LPRINT.lista[i].CN <> nil then
              begin
                   LPRINT.lista[i].CN.Free;
                   LPRINT.lista[i].CN:=nil;
              end;
          end;

          SetLength(LPRINT.lista,0);

          FreeAndNil(LPRINT);

          kill_all_links(-1);

     except On e:Exception do
            begin
            end;
     end;

     log_sat_service('***  SERVIÇO PARADO',nil,nil);
end;

function TConectLabMobile64.Init():Boolean;
var
   m:String;
   cfg:TIniFile;
   formatSettings:TFormatSettings;
   v1,v2:Currency;

   i,
   srvPorta:Integer;

   tmp:Array[1..6] of String;

begin
     SET_VERSAO(1,15,'17/12/2019 20:06');

     ARQINI:=pathz('\comandas.ini');

     log_sat_service_pasta();

     cfg                  :=TIniFile.Create(ARQINI);
     srvPorta             :=cfg.ReadInteger('servidor','porta'    ,4409);
     SATEXT_DEBUG         :=cfg.ReadInteger('servidor','debug'    ,0) = 1;
     SATEXT_SEM_LOG       :=cfg.ReadInteger('servidor','semLog'   ,0) = 1;
     LIMITE_CONTAR_PEDIDOS:=cfg.ReadInteger('servidor','mem_reset',600);
     APP_TIMEOUT          :=cfg.ReadInteger('servidor','app_timeout',5000);
     LOG_TIMEOUT          :=cfg.ReadInteger('servidor','log_timeout',259200);
     SATEXT_CONEXAO_DB_SRV:=cfg.ReadString('servidor','db','');
     FreeAndNil(cfg);

     SATEXT_IDLOG:='P' + IntToStr(srvPorta);

     if SATEXT_CONEXAO_DB_SRV = '' then
     begin
          cfg:=TIniFile.Create(pathz('\rcs.ini'));
          m  :=cfg.ReadString('db','db0','');
          FreeAndNil(cfg);

          for i:=1 to 6 do
              tmp[i]:=cs(m);

          SATEXT_CONEXAO_DB_SRV:=tmp[1] + '|' +
                                 tmp[2] + '|' +
                                 tmp[3] + '|' +
                                 tmp[4] + '|' +
                                 decrypt_str(tmp[5]) + '|' +
                                 decrypt_str(tmp[6]) + '|';

          SATEXT_CONEXAO_DB_SRV:=encrypt_str(SATEXT_CONEXAO_DB_SRV);

          // CLB  |192.168.88.11|3306|clab  |*DAC491C154|*D4350A45E45D908F43|CONECT|
          // teste|192.168.88.37|3306|hbecia|root       |clabsql            |
     end;

     log_sat_service('Iniciando Suporte Mobile ' + VERSAO_BITS +  ' bit Versao: ' + GET_VERSAO(),nil,nil);

     CONTAR_PEDIDOS   :=0;
     result           :=True;

     // Forms.pas
     // Desativar esta rotina
     // function TApplication.CheckIniChange(var Message: TMessage): Boolean;

     //updateFormatSettings:=False;
     formatSettings.CurrencyString   :='R$';
     formatSettings.CurrencyFormat   :=2;
     formatSettings.NegCurrFormat    :=9;
     formatSettings.ThousandSeparator:='.';
     formatSettings.DecimalSeparator :=',';
     formatSettings.CurrencyDecimals :=2;
     formatSettings.DateSeparator    :='/';
     formatSettings.ShortDateFormat  :='dd/MM/yyyy';
     formatSettings.TimeSeparator    :=':';
     formatSettings.ShortTimeFormat  :='HH:mm:ss';
     formatSettings.LongTimeFormat   :='HH:mm:ss';
     formatSettings.ListSeparator    :=';';

     GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, formatSettings);

     iniciar_variaveis_identificacao();

     FLUSHLINK        :=0;
     USUARIO_LOGADO   :=False;
     TIMER_LOGADO     :=0;
     SATEXT_PROCESSO_OCUPADO :=False;
     SATEXT_PROCESSO_REG_LOG :=False;
     SATEXT_PROCESSO_MEM_LOG :=False;
     SATEXT_PROCESSO_TERM_LOG:=False;

     log_sat_service('Variaveis',nil,nil,True);
     log_sat_service(statusFormato(),nil,nil,True);

     try

        if SERVICE_MOB_INIT = 0 then
        begin
             SRV_TCP:=TServerSocket.Create(Self);

             log_sat_service('TCP Servidor',nil,nil,True);

             SRV_USER:=TrcsTerminais.Create;

             log_sat_service('TCP Cliente',nil,nil,True);

             with SRV_TCP do
             begin
                  Port              :=srvPorta; // 33113; // 3364;
                  ServerType        :=stNonBlocking;
                  OnListen          :=OnServerListen;
                  OnClientRead      :=OnServerClientRead;
                  OnClientConnect   :=OnServerClientConnect;
                  OnClientDisconnect:=OnServerClientDisconnect;
                  OnClientError     :=OnServerClienteError;
                  Active            :=True;
             end;

             m:='Iniciado na porta => ' + inttostr(SRV_TCP.Port);
        end;

        SERVICE_MOB_INIT:=1;

     except on e:exception do
            begin
                 m:='NÃO FOI POSSIVEL INICIAR O SERVIDOR => ' + e.message;
                 result:=False;
            end;
     end;

     v1:=-1254.87;
     v2:=1254.87;

     log_sat_service(m,nil,nil);
     log_sat_service('Formato Valores: ' + picture([v1]) + ' | ' + floattostr(v1) + '|'  + picture([v2]) + ' | ' + floattostr(v2),nil,nil,True);
     log_sat_service('Formato Data   : ' + datetostr(date()) + ' ' + timetostr(time()),nil,nil,True);
     log_sat_service('Flags debug ' + flagtostr(SATEXT_DEBUG) + ' sem log ' + flagtostr(SATEXT_SEM_LOG),nil,nil,True);

     Try

          if not sql_reconectar_banco_dados() then
          begin
               kill_all_links(-1);
               exit;
          end
          else
          begin
               //if SATEXT_USAR_FECHAR then
              // begin

              // end;
          end;

     Except On E:Exception do
            begin
                 log_sat_service('>>>.....>>>>....SEM BANCO DE DADOS',nil,nil);
                 exit;
            end;
     end;

     iniciar_identificacao_computador2();

     log_sat_service('iniciar_identificacao_computador',nil,nil,True);

     //sistema_ajustar_versao(5,1,4806,96);// Nova Versao

     sistema_pegar_perfil();

     log_sat_service('sistema_pegar_perfil',nil,nil,True);

     empresa_carregar_segmentos();

     log_sat_service('empresa_carregar_segmentos',nil,nil,True);

     rcs_iniciar_variaveis_globais();

     log_sat_service('rcs_iniciar_variaveis_globais',nil,nil,True);

     terminal_id();

     log_sat_service('terminal_id',nil,nil,True);

     MESAS_INICIO   :=0;
     MESAS_FINAL    :=0;
     COMANDAS_INICIO:=0;
     COMANDAS_FINAL :=0;

     CEL_USUARIO_POR_VEZ:=False;

     ATENDENTES:=TAtendentes.Create;
     dbw(2,'select * from vendedor order by id');

     for i:=0 to contar_registros_sql(2) do
     begin
          ATENDENTES.Add(dfi(2,i,'id','0'),
                         dfi(2,i,'cadastro','0'),
                         dfi(2,i,'nome'));
     end;

     log_sat_service('Lista de atendentes',nil,nil,True);

     if dbw(2,'select * from set_mult where nome="MOBILE_GERAL_AJUSTES"') > 0 then
        CEL_USUARIO_POR_VEZ:=dfi(2,0,'id_1','0') = 1;

     if CEL_USUARIO_POR_VEZ then
        log_sat_service('usuario por terminal >>>',nil,nil,True);


     if dbw(2,'select * from set_mult where nome="CONTROLE_INTERNO_DE_COMANDAS"') > 0 then
     begin
          MESAS_INICIO   :=dfi(2,0,'id_1' ,'0');
          MESAS_FINAL    :=dfi(2,0,'id_2' ,'0');
          COMANDAS_INICIO:=dfi(2,0,'id_3' ,'0');
          COMANDAS_FINAL :=dfi(2,0,'id_4' ,'0');
     end;

     IMPRESSORA_TCP_TIMEOUT:=0;

     if dbw(2,'select * from set_mult where nome="IMPRESSORA_OPCOES_AVANCADA"') > 0 then
        IMPRESSORA_TCP_TIMEOUT:=dfi(2,0,'id_3','0');

     log_sat_service('mesas_comandas',nil,nil,True);

     if LPRINT = nil then
        LPRINT:=TImpressoras.Create;

     log_sat_service('LPRINT',nil,nil,True);

     carregarImp();

     log_sat_service('carregarImp',nil,nil,True);

     ////////

     CPE_IGNORAR_ESTOQUE        :=objetos_status('produto.ignorar.estoque');
     COMANDA_RAPIDA             :=objetos_status('mesas.comanda.rapida');
     COMANDA_PEDIDO_BALCAO      :=objetos_status('mesas.pedido.balcao');
     PRODUTOS_CONTROLADOS_ATIVO :=objetos_status('produtosdia.produtos.controlados');
     ESTOQUE_POR_PEDIDO         :=objetos_status('produto.estoque.por.pedido'    );
     ESTOQUE_POR_NF             :=objetos_status('produto.estoque.por.notafiscal');
     ESTOQUE_POR_ECF            :=objetos_status('produto.movimenta.estoque.ecf' );
     BLOQUEIO_AUTOMATICO        :=objetos_status('mesas.bloqueio.automatico');

     if COMANDA_RAPIDA then
        COMANDA_DESCRICAO:='Comanda'
     else
        COMANDA_DESCRICAO:='Mesa';

     if COMANDA_PEDIDO_BALCAO then
        COMANDA_DESCRICAO:='Pedido';

     log_sat_service('objetos',nil,nil,True);

     produtos_gerenciamento_de_estoque();

     log_sat_service('produtos_gerenciamento_de_estoque',nil,nil,True);

     m:=OnlyNumber(datetostr(date()));
     m:=copy(m,3,6);

     PASTA_CACHE:=pathz('\cache\' + m + '\');

     testaPasta(PASTA_CACHE);

     SERVICE_MOB_INIT:=2;
     log_sat_service('# status 100%',nil,nil,True);

     REINICIAR_TUDO:=0;

     DB_LINK[1].Close;
     DB_LINK[2].Close;
end;

procedure TConectLabMobile64.carregarImp();
var
   q,y,j,i,p:Integer;
   w:String;
   l:TStringList;
begin
     log_aguardar_disponibilidade();

     SATEXT_PROCESSO_OCUPADO:=True;

     if not sql_reconectar_banco_dados() then
     begin
          SATEXT_PROCESSO_OCUPADO:=False;
          exit;
     end;

   //  Turno_Atual();

     LPRINT.limpar;

     l:=TStringList.Create();

     dbw(1,'select * from printers where ativa=1');

     for i:=0 to contar_registros_sql(1) do
     begin
          p:=high(LPRINT.lista) + 1;
          setlength(LPRINT.lista,p + 1);

          LPRINT.lista[p]:=TimpItem.Create();

          LPRINT.lista[p].id        :=dfi(1,i,'id','0');
          LPRINT.lista[p].idCfg     :=dfi(1,i,'idfonte','0');
          LPRINT.lista[p].descricao :=dfi(1,i,'descricao');
          LPRINT.lista[p].padrao    :=strIgual(dfi(1,i,'modulo'),'padrao');
          LPRINT.lista[p].porta     :=dfi(1,i,'porta');
          LPRINT.lista[p].spooler   :=dfi(1,i,'spooler');
          LPRINT.lista[p].gerenciado:=dfi(1,i,'gerenciado','0') = 1;
          LPRINT.lista[p].grupos    :=dfi(1,i,'grupos');
          LPRINT.lista[p].caixa     :=dfi(1,i,'caixa','0') = 1;
          LPRINT.lista[p].filtros   :=TStringList.Create;
          LPRINT.lista[p].filtros.Clear;
          LPRINT.lista[p].filtrog   :=TStringList.Create;
          LPRINT.lista[p].filtrog.Clear;

          LPRINT.lista[p].CN:=TCISStatus.Create;
          LPRINT.lista[p].CN.cfg(LPRINT.lista[p].porta,9100);

          w:=LPRINT.lista[p].grupos;
          l.Clear;

          while w <> '' do
                l.Add(cs(w,';'));

          dbw(2,'select * from grupo order by id');

          for j:=0 to contar_registros_sql(2) do
          begin
               q:=high(LPRINT.lista[p].gLista) + 1;
               setlength(LPRINT.lista[p].gLista,q + 1);
               LPRINT.lista[p].gLista[q]:=TimpGrp.Create;
               LPRINT.lista[p].gLista[q].marcado:=False;
               LPRINT.lista[p].gLista[q].id:=dfi(2,j,'id','0');
               LPRINT.lista[p].gLista[q].descricao:=dfi(2,j,'descricao');

               for y:=0 to l.Count -1 do
               begin
                    if l[y] = LPRINT.lista[p].gLista[q].id then
                    begin
                         LPRINT.lista[p].gLista[q].marcado:=True;
                         break;
                    end;
               end;
          end;
     end;

     SATEXT_PROCESSO_OCUPADO:=False;

     log_sat_service('LISTA DE IMPRESSORAS CARREGADA ' + IntToStr(High(LPRINT.lista) + 1),nil,nil,True);
end;

procedure TConectLabMobile64.OnServerListen(Sender: TObject;
          Socket: TCustomWinSocket);
begin
     //
end;

procedure TConectLabMobile64.OnServerClientConnect(Sender: TObject;
Socket: TCustomWinSocket);
var
   d:String;
   e:Boolean;
begin
     e:=False;

     log_aguardar_disponibilidade_term();

     SATEXT_PROCESSO_TERM_LOG:=True;

     if SRV_USER.Add(Socket) then
     begin

     end
     else
     begin
          e:=True;
          d:=d + ' : socket erro';
     end;

     SATEXT_PROCESSO_TERM_LOG:=False;

     if e then
        log_sat_service(d,nil,nil);
end;

procedure TConectLabMobile64.OnServerClientDisconnect(Sender: TObject;
Socket: TCustomWinSocket);
var
   i:integer;
   d:string;
begin
     d:='OFF => ' + Socket.RemoteAddress;

     for i:=0 to SRV_USER.Count -1 do
     begin
          if SRV_USER.lista[i].cn = Socket then
          begin
               d:=d + ' removido';
               SRV_USER.lista[i].cn:=nil;
          end;
     end;
end;

procedure TConectLabMobile64.GOERROS(var xtcp:TrcsCnService;xjson:String;var msgJson:WideString;opr_,code_,msg_:String;exc_:String='');
begin
     if xtcp <> nil then
     begin
          xtcp.OK   :=False;
          xtcp.ERRO :=picInt(code_);
          xtcp.DERRO:=msg_;
     end;

     log_sat_service('erro '+ opr_ + ': ' + code_ + '-' + msg_);

     if exc_ <> '' then
        log_sat_service('excecao: ' + exc_);

     xjson  :=StrTrans(xjson,'$code',code_);
     msg_   :=StrTrans(xjson,'$msg' ,msg_);
     msgJson:=msg_;
end;

procedure TConectLabMobile64.OnServerClientRead(Sender: TObject;Socket: TCustomWinSocket);
var
   sucess:Boolean;
   D:String;

   i,j,v,u:integer;


   LDADOS:String;

   XERRO,
   xref,
   xcomanda,
   xmesa,
   erro,
   cImp,
   nUser,
   nPrint,
   cUser,
   termi,
   _INFO,

   s,
   cmd,
   xID,id:String;

   vPeso:Currency;

   IOK:Boolean;
   resp:TStringList;

   tst,xG,lG,cG,iG:TStringlist;

   calcTime,
   temItem:Boolean;

   cnTCP:TrcsCnService;

   ERRO_1,
   ERRO_2:String;


   uPed:TStringList;

   JSON:TlkJSONobject;
   operacao,
   documento,
   usuario,
   terminal,
   token:TlkJSONbase;

   msg:String;

   procedure GOERRO(code_,msg_:String;exc_:String='');
   var
      kmsg:String;
   begin
        if cnTCP <> nil then
        begin
             cnTCP.OK   :=False;
             cnTCP.ERRO :=picInt(code_);
             cnTCP.DERRO:=msg_;
             IOK        :=cnTCP.ERRO = 0;
             ERRO_1     :=IntToStr(cnTCP.ERRO);
             ERRO_2     :=cnTCP.DERRO;
        end;

        log_sat_service('erro ' + cmd + ': ' + code_ + '-' + msg_);

        if exc_ <> '' then
           log_sat_service('excecao: ' + exc_);

        kmsg:=msg;

        kmsg:=StrTrans(kmsg,'$code',code_);
        msg_:=StrTrans(kmsg,'$msg' ,msg_);
        RespostaHttp(nil,Socket,0,'',msg_);

        if uPed <> nil then
           FreeAndNil(uPed);
   end;

begin
     cnTCP   :=nil;
     sucess  :=False;
     D       :=String(Socket.ReceiveText);
     msg     :='{"status":"erro","erro":"$code","aviso":"$msg"}';
     calcTime:=False;
     IOK     :=False;
     tempoINI:=GetTickCount();
     tempoEND:=tempoINI;
     tempoMED:=tempoMED;

     //
     //   Conexão sem dados, cancelar operação
     //
     if Trim(D) = '' then
     begin
          GOERRO('015','Dados invalidos - null');
          exit;
     end;
     //
     //   Modo Debug - Salvar dados recebido
     //
     if SATEXT_DEBUG and (not SATEXT_SEM_LOG)  then
     begin
          s:=pathz('\debug_mob.txt');

          if FileExists(s) then
          begin
               tst:=TStringlist.Create();
               tst.LoadFromFile(s);
               tst.Add('bloco(' + D + ')');
               tst.SaveToFile(s);
          end;
     end;
     //
     //   Se a Inicialização não foi concluida
     //   tentar iniciar todos processos.
     //
     if SERVICE_MOB_INIT <> 2 then
     begin
          log_sat_service('-----> REINICIANDO SERVICO');

          if not Init() then
          begin
               GOERRO('010','Falha na inicializacao do servidor');
               exit;
          end;
     end;

     uPed:=TStringList.Create();
     uPed.Text:=D;
     //
     //   Identificando protocolo http pelo cabeçalho
     //
     cmd:=StrRight(Trim(uPed[0]),8);
     cmd:=Copy(cmd,1,6);

     if cmd = 'HTTP/1' then
        cmd:='> http <' else
     if cmd = 'HTTP/2' then
        cmd:='> http <';
     //
     //   Se não for no padrao http cancela operação
     //
     if cmd <> '> http <' then
     begin
          GOERRO('011','Protocolo de comunicacao invalido > http <');
          exit;
     end;
     //
     //  Separando JSON
     //
     i:=0;
     j:=0;
     while i < uPed.Count do
     begin
          uPed[i]:=Trim(uPed[i]);

          if Copy(uPed[i],1,1) = '{' then
          begin
               u:=1;
               break;
          end
          else
          begin
               uPed.Delete(i);
               i:=0;
               continue;
          end;

          Inc(i);
     end;
     //
     //  Verifica se o JSON foi identificado
     //
     if u = 0 then
     begin
          GOERRO('012','JSON nao identificado');
          exit;
     end;
     //
     //  Load JSON
     //
     JSON:=TlkJSON.ParseText(uPed.Text) as TlkJSONobject;
     //
     //  Se for um JSON invalido
     //
     if JSON = nil then
     begin
          GOERRO('013','Dados do JSON invalido - null');
          exit;
     end;
     //
     //  Pegando dados de identificação do serviço
     //
     operacao:=JSON.Field['operacao'];
     token   :=JSON.Field['token'];

     if operacao = nil then
     begin
          GOERRO('014','Operacao invalida');
          exit;
     end;

     if token = nil then
     begin
          GOERRO('016','Campo token nao informado',uPed.Text);
          exit;
     end;

     if not TokenValido(token.Value) then
     begin
          GOERRO('017','Falha na validacao do token',uPed.Text);
          exit;
     end;

     cmd           :=operacao.Value;
     cnTCP         :=posiciona_terminal(Socket.RemoteAddress);
     cnTCP.ERRO    :=0;
     cnTCP.DERRO   :='';
     cnTCP.OK      :=False;
     cnTCP.http    :=True;
     cnTCP.pendente:=True;
     if token <> nil then
     cnTCP.token   :=token.Value;

     if cmd = 'status' then
     begin
          cnTCP.terminal:='1';
          calcTime      :=True;

          log_aguardar_disponibilidade();

          try

              SATEXT_PROCESSO_OCUPADO:=True;

              if sql_reconectar_banco_dados() then
              begin
                   servico_status(cnTCP,uPed.Text);

                   DB_LINK[1].Close;
                   DB_LINK[2].Close;
              end
              else
                  GOERRO('050',' Falha conexao Banco de dados');

          except on e:exception do
                 begin
                      GOERRO('051','Erro de excecao');
                 end;
          end;

          sucess:=True;
     end;

     if cmd = 'mysql' then
     begin
          calcTime:=True;

          log_aguardar_disponibilidade();

          try

              SATEXT_PROCESSO_OCUPADO:=True;

              if sql_reconectar_banco_dados() then
              begin
                   servico_mysql(cnTCP,uPed.Text);

                   DB_LINK[1].Close;
                   DB_LINK[2].Close;
              end
              else
                  GOERRO('050','Falha conexao Banco de dados');

          except on e:exception do
                 begin
                      GOERRO('051','Erro de excecao');
                 end;
          end;

          sucess:=True;
     end;

     if cmd = 'login' then
     begin
          calcTime:=True;

          log_aguardar_disponibilidade();

          try

              SATEXT_PROCESSO_OCUPADO:=True;

              if sql_reconectar_banco_dados() then
              begin
                   servico_login(cnTCP,uPed.Text);

                   DB_LINK[1].Close;
                   DB_LINK[2].Close;
              end
              else
                  GOERRO('050','Falha conexao Banco de dados');

          except on e:exception do
                 begin
                      GOERRO('051','Erro de excecao');
                 end;
          end;

          sucess:=True;
     end;

     if cmd = 'logoff' then
     begin
          calcTime:=True;

          log_aguardar_disponibilidade();

          try

              SATEXT_PROCESSO_OCUPADO:=True;

              servico_logoff(cnTCP,uPed.Text);

          except on e:exception do
                 begin
                      GOERRO('051','Erro de excecao');
                 end;
          end;

          IOK   :=True;
          ERRO_1:='0';
          ERRO_2:='';

          sucess:=True;
     end;

     if cmd = 'IMP' then
     begin
          log_sat_service('MANUTENCAO DE IMPRESSORA ' + LDADOS,nil,cnTCP,True);

          log_aguardar_disponibilidade();

          calcTime:=True;

          try

              SATEXT_PROCESSO_OCUPADO:=True;

              if sql_reconectar_banco_dados() then
              begin
                   manutencao_impressoras(cnTCP,LDADOS);

                   DB_LINK[1].Close;
                   DB_LINK[2].Close;
              end
              else
              begin
                   cnTCP.OK   :=False;
                   cnTCP.ERRO :=5;
                   cnTCP.DERRO:='IMP - ERRO DE CONEXAO O BANCO DE DADOS';

                   notificar_terminal(cnTCP);
              end;

          except On e:Exception do
                 begin
                      cnTCP.OK   :=False;
                      cnTCP.ERRO :=50;
                      cnTCP.DERRO:='IMP - ERRO NO PROCESSAMENTO DO PEDIDO';

                      notificar_terminal(cnTCP);

                      cnTCP.DERRO:=cnTCP.DERRO + ' - ' + e.Message;
                 end;
          end;

          IOK   :=cnTCP.ERRO = 0;
          ERRO_1:=inttostr(cnTCP.ERRO);
          ERRO_2:=cnTCP.DERRO;

          sucess:=True;
     end;

  // Pedido de impressao da Pre Conta

     if cmd = 'PRE' then
     begin
          //cnTCP      :=posiciona_terminal(Socket.RemoteAddress);
          //cnTCP.ERRO :=0;
          //cnTCP.DERRO:='';
          //cnTCP.http :=pHTTP;
          //cnTCP.pendente:=True;

          log_sat_service('PRE-CONTA SOLICITADA ' + LDADOS,nil,cnTCP,True);

          calcTime:=True;

          if cnTCP.http and (uPed <> nil) then
             LDADOS:=uPed.Text;

          try

              SATEXT_PROCESSO_OCUPADO:=True;

              if sql_reconectar_banco_dados() then
              begin
                   imprimir_pre_conta(cnTCP,id,cUser,termi,LDADOS);

                   DB_LINK[1].Close;
                   DB_LINK[2].Close;
              end
              else
              begin
                   cnTCP.OK   :=False;
                   cnTCP.ERRO :=5;
                   cnTCP.DERRO:='ERRO DE CONEXAO O BANCO DE DADOS';

                   notificar_terminal(cnTCP);
              end;

          except on e:Exception do
                 begin
                      cnTCP.OK   :=False;
                      cnTCP.ERRO :=50;
                      cnTCP.DERRO:='PRE - ERRO NO PROCESSAMENTO DO PEDIDO';

                      notificar_terminal(cnTCP);

                      cnTCP.DERRO:=cnTCP.DERRO + ' - ' + e.Message;
                 end;
          end;

          IOK   :=cnTCP.ERRO = 0;
          ERRO_1:=inttostr(cnTCP.ERRO);
          ERRO_2:=cnTCP.DERRO;
          sucess:=True;
     end;

     if cmd = 'PRD' then
     begin
          //cnTCP         :=posiciona_terminal(Socket.RemoteAddress);
          //cnTCP.http    :=pHTTP;
          //cnTCP.pendente:=True;

          if cnTCP.http and (uPed <> nil) then
             LDADOS:=uped.Text;

          log_sat_service('PRODUCAO SOLICITADA ' + LDADOS,nil,cnTCP,True);

          calcTime:=True;

          try

              SATEXT_PROCESSO_OCUPADO:=True;

              if sql_reconectar_banco_dados() then
              begin
                   imprimir_producao(cnTCP,id,cUser,termi,LDADOS,'');

                   DB_LINK[1].Close;
                   DB_LINK[2].Close;
              end
              else
              begin
                   cnTCP.OK   :=False;
                   cnTCP.ERRO :=5;
                   cnTCP.DERRO:='PRD - ERRO DE CONEXAO O BANCO DE DADOS';

                   notificar_terminal(cnTCP);
              end;

          except on e:Exception do
                 begin
                      cnTCP.OK   :=False;
                      cnTCP.ERRO :=50;
                      cnTCP.DERRO:='PRD - ERRO NO PROCESSAMENTO DO PEDIDO';

                      notificar_terminal(cnTCP);

                      cnTCP.DERRO:=cnTCP.DERRO + ' - ' + e.Message;
                 end;
          end;

          IOK   :=cnTCP.ERRO = 0;
          ERRO_1:=IntToStr(cnTCP.ERRO);
          ERRO_2:=cnTCP.DERRO;
          sucess:=True;
          //STS('');
     end;

     if cmd = 'PIT' then
     begin
          log_sat_service('PEDIDOS SOLICITADO ' + LDADOS,nil,cnTCP,True);

          try

              if sql_reconectar_banco_dados() then
              begin
                   if cnTCP.http and (uPed <> nil) then
                      registrar_pedidos_json(cnTCP,uPed.Text)
                   else
                   begin
                      ////registrar_pedidos(cnTCP,id,user,termi,LDADOS);
                   end;

                   DB_LINK[1].Close;
                   DB_LINK[2].Close;
              end
              else
              begin
                   cnTCP.OK   :=False;
                   cnTCP.ERRO :=5;
                   cnTCP.DERRO:='PIT - ERRO DE CONEXAO O BANCO DE DADOS';

                   notificar_terminal(cnTCP);
              end;

          except On e:Exception do
                 begin
                      cnTCP.OK   :=False;
                      cnTCP.ERRO :=50;
                      cnTCP.DERRO:='PIT - ERRO NO PROCESSAMENTO DO PEDIDO';

                      notificar_terminal(cnTCP);

                      cnTCP.DERRO:=cnTCP.DERRO + ' - ' + e.Message;
                 end;
          end;

          IOK   :=cnTCP.ERRO = 0;
          ERRO_1:=inttostr(cnTCP.ERRO);
          ERRO_2:=cnTCP.DERRO;
          sucess:=True;
     end;
//
//
//   Calculando tempo de resposta do processamento
//
//
     if calcTime then
     begin
          try

              try
                  tempoEnd:=GetTickCount();

                  _INFO:='';

                  if tempoEnd > tempoIni then
                     _INFO:=_INFO + FloatToStr((tempoEnd - tempoIni) / 1000);

                  if not IOK then
                     _INFO:='ERRO => ' + _INFO + ' => ' + ERRO_2 + ' -> ' + ERRO_1
                  else
                     _INFO:=_INFO + ' => OK';

                  if _INFO <> '' then
                     log_sat_service('tempo: ' + _INFO,nil,cnTCP,True);

              except on e:exception do
                     begin
                     end;
              end;

          finally

                SATEXT_PROCESSO_OCUPADO:=False;

          end;
     end;

     if not sucess then
        respostaHttp(nil,Socket,1004,'SOLICITACAO DESCONHECIDA');

     if Assigned(cnTCP) then
     begin
          cnTCP.pendente:=False;
          cnTCP.FecharSQL;
     end;

     if LIMITE_CONTAR_PEDIDOS > 0 then
     begin
          if calcTime then
          begin
               Inc(CONTAR_PEDIDOS);

               if CONTAR_PEDIDOS > LIMITE_CONTAR_PEDIDOS then
               begin
                    CONTAR_PEDIDOS:=0;
                 // Timer1.Enabled:=True;
               end;
          end;
     end;

     FreeAndNil(tst);
     FreeAndNil(uPed);
end;

procedure TConectLabMobile64.OnServerClienteError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
     log_sat_service('Terminal => ' + Socket.RemoteAddress +' / ERRO: ' + inttostr(ErrorCode),nil,nil);
     ErrorCode:=0;
end;

function TConectLabMobile64.statusFormato():String;
begin
     result:='CurrencyString=' + sdb(formatSettings.CurrencyString) +
     ', CurrencyFormat=' + sdb('#' + inttostr(formatSettings.CurrencyFormat)) +
     ', NegCurrFormat=' + sdb('#' + inttostr(formatSettings.NegCurrFormat)) +
     ', ThousandSeparator=' + sdb(formatSettings.ThousandSeparator) +
     ', DecimalSeparator=' + sdb(formatSettings.DecimalSeparator) +
     ', CurrencyDecimals=' + sdb(inttostr(formatSettings.CurrencyDecimals)) +
     ', DateSeparator=' + sdb(formatSettings.DateSeparator) +
     ', ShortDateFormat=' + sdb(formatSettings.ShortDateFormat) +
     ', LongDateFormat=' + sdb(formatSettings.LongDateFormat) +
     ', TimeSeparator=' + sdb(formatSettings.TimeSeparator) +
     ', TimeAMString=' + sdb(formatSettings.TimeAMString) +
     ', TimePMString=' + sdb(formatSettings.TimePMString) +
     ', ShortTimeFormat=' + sdb(formatSettings.ShortTimeFormat) +
     ', LongTimeFormat=' + sdb(formatSettings.LongTimeFormat) +
     ', TwoDigitYearCenturyWindow=' + sdb(inttostr(formatSettings.TwoDigitYearCenturyWindow)) +
     ', ListSeparator=' + sdb(formatSettings.ListSeparator);
end;


procedure TConectLabMobile64.notificar_todos_terminais(id,cmd:String);
var
   i:Integer;
begin
     for i:=0 to SRV_USER.Count -1 do
     begin
          if SRV_USER.lista[i].cn = nil then
             continue;

          try
             if assigned(SRV_USER.lista[i].cn) then
             begin
                  if not SRV_USER.lista[i].cn.Connected then
                  begin
                       SRV_USER.lista[i].cn.Free;
                       SRV_USER.lista[i].cn:=nil
                  end
                  else
                  begin
                       SRV_USER.lista[i].cn.SendText(cmd + ':' + id);
                  end;
             end;
          except on e:Exception do
                 begin
                      SRV_USER.lista[i].cn:=nil;
                      log_sat_service('ERRO: LISTA USER',nil,nil);
                 end;
          end;
     end;
end;

procedure TConectLabMobile64.notificar_terminal(xTCP:TrcsCnService;jsonTxt:String='');
var
   cmd:String;
begin
     if Assigned(xTCP.cn) then
     begin
          if not xTCP.cn.Connected then
          begin
               xTCP.cn.Free;
               xTCP.cn:=nil
          end
          else
          begin
               cmd:='ok';

               if xTCP.ERRO > 0 then
                  cmd:='erro';

               if xTCP.http then
               begin
                    if jsonTxt <> '' then
                       cmd:=jsonTxt
                    else
                       cmd:='{"status":"' + cmd + '",' +
                            '"codigo":"' + inttostr(xTCP.ERRO) + '",' +
                            '"descricao":"' + xTCP.DERRO + '"}';

                    respostaHttp(xTCP,nil,0,cmd)
               end
               else
                   xTCP.cn.SendText(cmd + ':' + xTCP.DERRO);
          end;
     end;
end;

procedure TConectLabMobile64.respostaHttp(cnTCP:TrcsCnService;Socket:TCustomWinSocket;erro_:Integer;d:String;jsonTxt:String='');
var
   h:TStringList;
begin
     h:=TStringList.Create();

     h.Add('HTTP/1.1 200 Ok');

     if cnTCP <> nil then
     begin
          if cnTCP.ERRO > 0 then
          begin
          h.Add('Codigo-Erro: ' + inttostr(cnTCP.ERRO));
          h.Add('Descr-Status: ' + cnTCP.DERRO);
          end;

         if cnTCP.http then
         begin
             // h.Add('Connection: Keep-Alive');
              h.Add('Accept: application/json, text/plain; q=0.9, text/html;q=0.8,');
             //h.Add('Content-type: application/json');
         end;
     end;

     if erro_ > 0 then
     begin
          if cnTCP = nil then
          begin
               h.Add('Codigo-Erro: '  + inttostr(erro_));
               h.Add('Descr-Status: ' + d);
          end;

          d:='{"status":"ERRO",' +
             '"codigo":"' + inttostr(erro_) + '",' +
             '"descricao":"' + d + '"}';
     end;

     if jsonTxt <> '' then
        d:=jsonTxt;

     h.Add('Content-Length: ' + inttostr(length(d)));
     h.Add('cab: break');
     h.Add('');
     h.Add(d);
     h.Add('>body<');

     if cnTCP <> nil then
        cnTCP.cn.SendText(h.Text) else
        Socket.SendText(h.Text);

     FreeAndNil(h);
end;

function TConectLabMobile64.posiciona_terminal(id:String):TrcsCnService;
var
   i:Integer;
begin
     result:=nil;

     for i:=0 to SRV_USER.Count -1 do
     begin
          if SRV_USER.lista[i].cn = nil then
             continue;

          try
             if Assigned(SRV_USER.lista[i].cn) then
             begin
                  if SRV_USER.lista[i].ID = id then
                  begin
                       result:=SRV_USER.lista[i];
                       break;
                  end;
             end;
          except On e:Exception do
                 begin

                 end;
          end;
     end;
end;

procedure TConectLabMobile64.rcs_iniciar_variaveis_globais();
begin
     CPR_PRODUTO_ALTERADO :=0;
     CPR_ESTOQUE_ALTERADO :=0;
     CPR_ULTIMO_CODIGO    :='';
    // DESATIVAR_SONS_WAVE  :=False;
     //RCS_SISTEMA_ENCERRADO:=False;
end;

procedure TimpItem.filtraGrupo(id:String);
var
   i:Integer;
   r:Boolean;
begin
     r:=False;

     for i:=0 to filtrog.Count -1 do
     begin
          if filtrog[i] = id then
          begin
               r:=True;
               break;
          end;
     end;

     if not r then
        filtrog.Add(id);
end;

procedure Timpressoras.limpar();
var
   i,j:Integer;
begin
     for i:=0 to High(lista) do
     begin
          for j:=0 to High(lista[i].gLista) do
          begin
               lista[i].gLista[j].Free;
               lista[i].gLista[j]:=nil;
          end;

          SetLength(lista[i].gLista,0);

          FreeAndNil(lista[i].filtros);
          FreeAndNil(lista[i].filtrog);
          FreeAndNil(lista[i]);
     end;

     SetLength(lista,0);
end;

function TrcsTerminais.Add(cn:TCustomWinSocket):Boolean;
var
   i,p:Integer;
begin
     p:=-1;

     for i:=0 to High(Self.lista) do
     begin
          if Self.lista[i].cn = nil then
          begin
               p:=i;
               break;
          end
          else
          begin
               if cn.RemoteAddress = Self.lista[i].ID then
               begin
                    p:=i;
                    break;
               end;
          end;
     end;

     result:=True;

     if p = -1 then
     begin
          i:=High(Self.lista) + 1;
          SetLength(Self.lista,i + 1);
          Self.lista[i]:=nil;
     end;

     if Self.lista[i] = nil then
     begin
          Self.lista[i]     :=TrcsCnService.Create;
          Self.lista[i].hora:=Now();
     end;

     Self.lista[i].cn      :=cn;
     Self.lista[i].ID      :=cn.RemoteAddress;
     Self.lista[i].pendente:=False;
end;

function TrcsTerminais.Count():Integer;
begin
     result:=High(Self.lista) + 1;
end;

procedure TrcsTerminais.Del(cn:TCustomWinSocket);
var
   i:Integer;
begin
     for i:=0 to High(Self.lista) do
     begin
          if Self.lista[i].cn = nil then
             continue;

           if cn.RemoteAddress = Self.lista[i].ID then
           begin
                Self.lista[i].cn:=nil;
                Self.lista[i].FecharSQL;
                Self.lista[i].Free;
                Self.lista[i]:=nil;
           end;
     end;
end;

procedure TConectLabMobile64.imprimir_pre_conta(xTCP:TrcsCnService;id,cUser,cTerminal:String;gDados:WideString);
var
   i:Integer;

   id_impressora,
   nome_impressora,
   codi_impressora,
   nUser,
   turno,
   referencia,
   comanda,
   infomesa:String;

   aTotal,
   pTotal:Currency;

   pedBloqueado,
   IOK:Boolean;
   E1:Integer;

begin
     //
     //   Iniciar variaveis
     //
     //

     id_impressora  :='';
     nome_impressora:='';
     codi_impressora:='';
     rcsprintporta  :='';
     rcsprintnomewindows:='';
     IOK            :=False;
     E1             :=0;
     xTCP.ERRO      :=0;
     xTCP.DERRO     :='';

     //
     //   Procurar impressora do caixa qual esta configurada para pre-conta
     //

     log_sat_service('Lista das impressoras',nil,xTCP,True);

     for i:=0 to high(LPRINT.lista) do
     begin
          //
          //  Impressora localizada
          //
          if LPRINT.lista[i].caixa then
          begin
               id_impressora  :=LPRINT.lista[i].idCfg;
               rcsprintporta  :=LPRINT.lista[i].porta;
               nome_impressora:=LPRINT.lista[i].descricao;
               codi_impressora:=LPRINT.lista[i].id;
               rcsprintnomewindows:=LPRINT.lista[i].spooler;

               log_sat_service('Id da impressora ' + id_impressora + ' => ' + rcsprintporta,nil,xTCP,True);

               //
               //   Verificar se a impressora esta online na rede
               //
               if not confereStatus(i) then
               begin
                    xTCP.ERRO :=51;
                    xTCP.DERRO:=LPRINT.lista[i].botao_id;
               end;

               break;
          end;
     end;

     //
     //   Caso a impressora não for localizada
     //   Notificar usuário
     //
     if id_impressora = '' then
     begin
          xTCP.ERRO :=52;
          xTCP.DERRO:='IMPRESSORA NAO CONFIGURADA';

          notificar_terminal(xTCP);

          log_sat_service(xTCP.DERRO,nil,xTCP,True);
          exit;
     end;

     try
         //
         //  Conectando ao Banco de Dados
         //

         log_sat_service('ABRIR BANCO DE DADOS',nil,nil,True);

         if xTCP.DB = nil then
         begin
              xTCP.DB         :=TMyClient.Create(nil);
              xTCP.DB.Hostname:=CSQL.Hostname;
              xTCP.DB.Port    :=CSQL.Port;
              xTCP.DB.Database:=CSQL.Database;
              xTCP.DB.Username:=CSQL.Username;
              xTCP.DB.Password:=CSQL.Password;
         end;

         xTCP.DB.Open;

         if xTCP.DB2 = nil then
         begin
              xTCP.DB2         :=TMyClient.Create(nil);
              xTCP.DB2.Hostname:=CSQL.Hostname;
              xTCP.DB2.Port    :=CSQL.Port;
              xTCP.DB2.Database:=CSQL.Database;
              xTCP.DB2.Username:=CSQL.Username;
              xTCP.DB2.Password:=CSQL.Password;
         end;

         xTCP.DB2.Open;

     except On e:Exception do
            begin
                 xTCP.ERRO :=152;
                 xTCP.DERRO:='BANCO DE DADOS OFF-LINE';

                 notificar_terminal(xTCP);
                 log_sat_service('FALHA NA ABERTURA DO BANCO DE DADOS',nil,xTCP,True);

                 xTCP.FecharSQL;

                 exit;
            end;
     end;

     log_sat_service('OK BANCO DE DADOS',nil,nil,True);

     try
          dbx(xTCP.DB2,'select count(id) as id,sum(total) as total,sum(qtde) as qtde from auxiliar where idpedido=' + id);
          aTotal    :=dfx(xTCP.DB2,0,'total','f');

          dbx(xTCP.DB2,'select id,referencia,mesa,infomesa,turno,valor from pedidos where id=' + id);
          referencia:=dfx(xTCP.DB2,0,'referencia');
          comanda   :=dfx(xTCP.DB2,0,'mesa');
          infomesa  :=dfx(xTCP.DB2,0,'infomesa');
          turno     :=dfx(xTCP.DB2,0,'turno','0');
          pTotal    :=dfx(xTCP.DB2,0,'valor','f');

          if aTotal <> pTotal then
          begin
               log_sat_service('TOTALIZANDO PEDIDO ' + id,nil,xTCP,True);

               totalizar_produtos_pedidos(id,xTCP.DB2);
          end;

          log_sat_service('SET IMPRESSORA ' + id_impressora,nil,xTCP,True);

          perfilImpressora(id_impressora,xTCP.DB2);

          if xTCP.ERRO > 0 then
          begin
               log_sat_service('ERRO ' + inttostr(xTCP.ERRO),nil,xTCP);

               notificar_terminal(xTCP);

               E1:=xTCP.ERRO;

               log_sat_service(xTCP.DERRO,nil,xTCP);
          end
          else
          begin
               log_sat_service('ENVIANDO IMPRESSAO',nil,xTCP,True);

               IOK:=cupom_impressao_expert(True,id,'1','pedidos','auxiliar',False,True,False,False,False,False,xTCP.DB,xtcp.DB2);

               if CUPOM_MSG_ERRO <> '' then
                  log_sat_service('ERRO: ' + CUPOM_MSG_ERRO,nil,xTCP);

               tempoMED:=GetTickCount();

               if not IOK then
               begin
                    xTCP.ERRO :=2;
                    xTCP.DERRO:='FALHA NA IMPRESSORA';
                    log_sat_service(xTCP.DERRO,nil,xTCP);
               end
               else
               begin
                    if BLOQUEIO_AUTOMATICO then
                    begin
                         with xTCP.DB2 do
                         begin
                              query.reset;
                              modify.reset;
                              modify.Add('bloqueado','1');
                              modify.PrepareUpdateTask('pedidos',sch('where id=' + id),'',nil,nil);
                              execute;
                         end;
                    end;
               end;
          end;

          if IOK then
          begin
               xTCP.ERRO :=0;
               xTCP.DERRO:='Processado com Sucesso';

               notificar_terminal(xTCP);

               log_sat_service(xTCP.DERRO,nil,xTCP,True);
          end;

          try

               nUser:='N/D';

               if picInt(cUser) = 0 then
                  cUser:='1';

               if dbx(xTCP.DB2,'select * from vendedor where cadastro=' + cUser) > 0 then
                  nUser:=dfx(xTCP.DB2,0,'nome');

               log_sat_service('GRAVANDO REGISTRO PRE',nil,xTCP,True);

               with xTCP.DB2 do
               begin
                    query.reset;
                    modify.reset;
                    modify.add('turno'     ,sch(zedb(turno)));
                    modify.add('tipo'      ,sch(sdb('PRE')));
                    modify.add('pedido'    ,sch(zedb(id)));
                    modify.add('data'      ,sch(datdb(datetostr(date()))));
                    modify.add('hora'      ,sch(sdb(timetostr(time()))));
                    modify.add('usuario'   ,sch(zedb(cUser)));
                    modify.add('nome'      ,sch(sdb(nUser)));
                    modify.add('terminal'  ,sch(zedb(cTerminal)));
                    modify.add('cImp'      ,sch(zedb(codi_impressora)));
                    modify.add('impressora',sch(sdb(nome_impressora)));
                    modify.add('pImp'      ,sch(sdb(rcsprintporta)));
                    modify.add('erro'      ,sch(inttostr(xTCP.ERRO)));
                    modify.add('infoErro'  ,sch(sdb(xTCP.DERRO)));
                    modify.add('comanda'   ,sch(sdb(comanda)));
                    modify.add('mesa'      ,sch(sdb(infomesa)));
                    modify.add('tempo'     ,sch(picdb(floattostr((tempoMED - tempoINI) / 1000))));
                    modify.add('referencia',sch(sdb(referencia)));
                    modify.add('cmd'       ,sch(sdb(arquivos_string_to_hex(gDados))));
                    modify.prepareinserttask('mobisuporte','',nil,nil);
                    execute;
               end;

               log_sat_service('CONCLUIDO',nil,xTCP,True);
          except On e:Exception do
                 begin
                      log_sat_service('FALHA AO REGISTRAR MOB SUPORTE PEDIDO ' + id,nil,xTCP);
                 end;
          end;

     except On e:Exception do
            begin
                 xTCP.ERRO :=3;
                 xTCP.DERRO:='FALHA AO PROCESSAR O PEDIDO' + id;

                 log_sat_service(xTCP.DERRO,nil,xTCP);
            end;
     end;

     if (xTCP.ERRO > 0) and (xTCP.ERRO <> E1) then
         notificar_terminal(xTCP);

     xTCP.FecharSQL;
end;

function TConectLabMobile64.totalizar_produtos_pedidos(id:String;cn:TMyClient):String;
var
   vProd,
   vQtde,
   vDesc,
   vAcre,
   vFrete,
   vTotal:Currency;

   qItems:Integer;
begin
      vProd :=0;
      vQtde :=0;
      qItems:=0;
      vDesc :=0;
      vAcre :=0;
      vFrete:=0;
      vTotal:=0;

      if not testz(id) then
      begin
           dbx(cn,'select count(id) as id,sum(total) as total,sum(qtde) as qtde from auxiliar where idpedido=' + id);
           vProd :=dfx(cn,0,'total','f');
           vQtde :=dfx(cn,0,'qtde' ,'f');
           qItems:=dfx(cn,0,'id'   ,'0');

           dbx(cn,'select id,porcdesc,porcacre,fretes from pedidos where id=' + id);
           vDesc :=dfx(cn,0,'porcdesc','f');
           vAcre :=dfx(cn,0,'porcacre','f');
           vFrete:=dfx(cn,0,'fretes'  ,'f');

           vDesc :=vProd * vDesc / 100;
           vAcre :=vProd * vAcre / 100;

           vTotal:=(vProd + vAcre + vFrete) - vDesc;

           with cn do
           begin
                query.reset;
                modify.reset;
                modify.Add('qtde'     ,sch(picdb(eliminarDecimal(vQtde, -6))));
                modify.Add('valor'    ,sch(picdb(picture([vProd]))));
                modify.add('desconto' ,sch(picdb(picture([vDesc ]))));
                modify.add('acrescimo',sch(picdb(picture([vAcre ]))));
                modify.Add('subtotal' ,sch(picdb(picture([vTotal]))));
                modify.Add('totalped' ,sch(picdb(picture([vTotal]))));
                modify.prepareupdatetask('pedidos', sch('where id=' + zedb(id)), '',nil, nil);
                execute;
           end;
      end;

      PED_QTDES:=eliminarDecimal(vQtde,-6);
      PED_VALOR:=trim(picture([vProd]));
      PED_TOTAL:=trim(picture([vTotal]));

      result:=trim(picture([vProd]));
end;

procedure TConectLabMobile64.perfilImpressora(id:String;cn:TMyClient);
begin
     if testz(id) then
     begin
          if dbx(cn,'select * from printers where modelo=' + sdb('PADRAO')) = 0 then
             dbx(cn,'select * from printers where order by id');

          id:=dfx(cn,0,'idfonte','0');
     end;

     if dbx(cn,'select * from modprint where id=' + id) = 0 then
        dbx(cn,'select * from modprint order by id');

     rcsPrint_ft_reset     :=decifrar( dfx(cn,0,'reset'     ) );
     rcsPrint_ft_resetfont :=decifrar( dfx(cn,0,'resetfont' ) );
     rcsPrint_ft_bold      :=decifrar( dfx(cn,0,'bold'      ) );
     rcsPrint_ft_bold0     :=decifrar( dfx(cn,0,'bold0'     ) );
     rcsPrint_ft_italico   :=decifrar( dfx(cn,0,'italico'   ) );
     rcsPrint_ft_italico0  :=decifrar( dfx(cn,0,'italico0'  ) );
     rcsPrint_ft_underline :=decifrar( dfx(cn,0,'underline' ) );
     rcsPrint_ft_underline0:=decifrar( dfx(cn,0,'underline0') );
     rcsPrint_ft_lpi6      :=decifrar( dfx(cn,0,'lpi6'      ) );
     rcsPrint_ft_lpi8      :=decifrar( dfx(cn,0,'lpi8'      ) );
     rcsPrint_ft_cpi5      :=decifrar( dfx(cn,0,'cpi5'      ) );
     rcsPrint_ft_cpi6      :=decifrar( dfx(cn,0,'cpi6'      ) );
     rcsPrint_ft_cpi8      :=decifrar( dfx(cn,0,'cpi8'      ) );
     rcsPrint_ft_cpi10     :=decifrar( dfx(cn,0,'cpi10'     ) );
     rcsPrint_ft_cpi12     :=decifrar( dfx(cn,0,'cpi12'     ) );
     rcsPrint_ft_cpi17     :=decifrar( dfx(cn,0,'cpi17'     ) );
     rcsPrint_ft_cpi20     :=decifrar( dfx(cn,0,'cpi20'     ) );
     rcsPrint_ft_ejetar    :=decifrar( dfx(cn,0,'ejetar'    ) );
     rcsPrintGuilhotina    :=decifrar( dfx(cn,0,'guilhotina') );
     rcsPrintBip           :=decifrar( dfx(cn,0,'bipe'      ) );
     rcsPrintGaveta        :=decifrar( dfx(cn,0,'gaveta'    ) );
     rcsPrint_Col          :=dfx(cn,0,'colunas','0');
     rcsPrint_ColCpl       :=dfx(cn,0,'colCpl' ,'0');
     rcsPrint_Avancar      :=dfx(cn,0,'avancar','0');
end;

function TConectLabMobile64.decifrar(dc:String):string;
var
   d:tstringlist;
   i:integer;
begin
     d :=tstringlist.Create;
     dc:=strTrans(dc,' ','');

     while dc <> '' do
           d.Add(cs(dc,'#'));

     result:='';

     for i:=0 to d.Count-1 do
     begin
          if d[i] = '' then
             continue;

          if temString(d[i]) then
             result:=result + d[i]
          else
             result:=result + chr(picInt(zedb(d[i])));
     end;

     FreeAndNil(d);
end;

function TConectLabMobile64.confereStatus(p:Integer;Log:Boolean=False):Boolean;
var
   c:String;
   resp:TStringList;
   tempoINI,
   tempoEND:Cardinal;
   i:Integer;
   pSerial,
   st:Boolean;
begin
     result:=False;

     tempoINI:=GetTickCount();

     c:=LPRINT.lista[p].descricao + '|' + LPRINT.lista[p].porta;

     pSerial:=lowercase(Copy(LPRINT.lista[p].porta,1,3)) <> 'tcp';

     LPRINT.lista[p].botao_id:='';

     if pSerial then
     begin
          result:=True;
          // LPRINT.lista[p].porta;
          // cupom_valida_comm(LPRINT.lista[p].porta);
     end
     else
     begin
          for i:=1 to 2 do
          begin
               FreeAndNil(LPRINT.lista[p].CN);

               LPRINT.lista[p].CN:=TCISStatus.Create;
               LPRINT.lista[p].CN.cfg(LPRINT.lista[p].porta,9100);

               st:=LPRINT.lista[p].CN.Open();

               if st then
                  break
               else
                  Sleep(500);
          end;

          if not st then
          begin
               tempoEND:=GetTickCount();

               LPRINT.lista[p].botao_id:='FALHA DA IMPRESSORA t:' + floattostr((tempoEnd - tempoIni) / 1000);
               c:=c + '|' + LPRINT.lista[p].botao_id;
          end
          else
          begin
               LPRINT.lista[p].CN.check();

               if LPRINT.lista[p].CN.erro then
               begin
                    LPRINT.lista[p].botao_id             :=LPRINT.lista[p].CN.Erros;
                    c:=c + '|' + LPRINT.lista[p].botao_id;
               end
               else
               begin
                    result:=True;
               end;

               if Log then
               begin
                    resp:=TStringList.Create();
                    resp.Text:=LPRINT.lista[p].CN.Flags;
                    log_sat_service('status',resp,nil);
                    FreeAndNil(resp);
               end;
          end;

          LPRINT.lista[p].CN.Close;
     end;
end;

procedure TConectLabMobile64.manutencao_impressoras(xTCP:TrcsCnService;nSessao:String);
var
   cmd:String;
begin
     cmd       :=nSessao;
     xTCP.ERRO :=0;
     xTCP.DERRO:='Processado com sucesso';

     notificar_terminal(xTCP);

     carregarImp();
end;

procedure TConectLabMobile64.imprimir_producao(xTCP:TrcsCnService;id,cUser,cTerminal,nHora,nSessao:String;notifica:Boolean=True);
var
   lG,cG:TStringlist;

   i,j,u:Integer;

   pf,
   id_impressora,
   nome_impressora,
   codi_impressora,
   nUser,
   turno,
   referencia,
   comanda,
   infomesa,
   s,w:String;

   IOK,
   temItem:Boolean;

   xErro:WORD;
   cmd,
   ERRO_1,
   ERRO_2:String;

   Idb1,
   Idb2:Boolean;

   JSON:TlkJSONobject;

   tpSpooler:Boolean;
   JOperacao,
   JPedido,
   JSessao,
   JUsuario,
   JTerminal:TlkJSONbase;

   procedure libera();
   begin
        FreeAndNil(lG);
        FreeAndNil(cG);

        JSON:=nil;

        JOperacao:=nil;
        JPedido:=nil;
        JSessao:=nil;
        JUsuario:=nil;
        JTerminal:=nil;
   end;


begin
     cmd            :=nHora;
     id_impressora  :='';
     nome_impressora:='';
     codi_impressora:='';
     rcsprintporta  :='';
     rcsprintnomewindows:='';
     xTCP.ERRO      :=0;
     xTCP.DERRO     :='dispensado a impressao';
     IOK            :=False;
     ERRO_1         :=inttostr(0);
     ERRO_2         :=xTCP.DERRO;
     tpSpooler      :=False;

     if xTCP.http and (nSessao = '') then
     begin
          log_sat_service('PRODUCAO => JSON',nil,xTCP,True);

          //
          //     Abrindo dados JSON
          //
          //
          JSON:=TlkJSON.ParseText(nHora) as TlkJSONobject;

          if JSON = nil then
          begin
               xTCP.ERRO :=300;
               xTCP.DERRO:='DADOS COM FORMATO ERRADO json';
          end
          else
          begin
                //
                //     Pegando dados do JSON
                //
                //
                JOperacao:=JSon.Field['operacao'];
                JPedido  :=JSon.Field['pedido'  ];
                JSessao  :=JSon.Field['sessao'  ];
                JUsuario :=JSon.Field['usuario' ];
                JTerminal:=JSon.Field['terminal'];

                if JOperacao = nil then
                begin
                     xTCP.ERRO :=301;
                     xTCP.DERRO:='DADOS JSON FORMATO ERRADO';
                end;

                if JPedido = nil then
                begin
                     xTCP.ERRO :=302;
                     xTCP.DERRO:='ID PEDIDO FORMATO ERRADO';
                end;

                if JUsuario = nil then
                begin
                     xTCP.ERRO :=303;
                     xTCP.DERRO:='USUARIO INVALIDO';
                end;

                if JTerminal = nil then
                begin
                     xTCP.ERRO :=304;
                     xTCP.DERRO:='TERMINAL INVALIDO';
                end;
          end;

          log_sat_service('PRODUCAO => ERRO ' + INTTOSTR(XTCP.ERRO),nil,xTCP,True);

          //
          //     Se ocorrer algum erro cancelar operação
          //
          //

          if xTCP.ERRO > 0 then
          begin
               //  Enviar erro para o client
               //
               notificar_terminal(xTCP);

               //  Registra log mesmo com dados invalidos
               //
               //registraPIT();

               //  Libera conexão SQL
               //
               //xTCP.DB.Destroy;
               //xTCP.DB:=nil;
               exit;
          end;

          id       :=JPedido.Value;
          cUser    :=JUsuario.Value;
          cTerminal:=JTerminal.Value;
          nHora    :=JSessao.Value;

          log_sat_service('PRODUCAO => ' + ID + ',' + cUSER+ ',' +CTERMINAL + ',' + NHORA  ,nil,xTCP,True);
     end;

     log_sat_service('PRODUCAO => id:' + id + ' user:' + cUser + 'term:' + cTerminal + ' hora:' + nHora + ' sessao:' +nSessao,nil,xTCP,True);

     lG:=TStringlist.Create;
     cG:=TStringlist.Create;

     if Copy(nHora,1,1) = '*' then
     begin
          nSessao:=Copy(nHora,2,Length(nHora));
          nHora  :='';
     end;

     if nSessao <> '' then
     begin
          if XTCP.sessao = nSessao then
          begin
               xTCP.ERRO :=501;
               xTCP.DERRO:='DUPLICIDADE';

               notificar_terminal(xTCP);

               libera();
               exit;
          end;

          XTCP.sessao:=nSessao;
     end;

   try

     Idb1:=xTCP.DB  = nil;
     Idb2:=xTCP.DB2 = nil;

     if Idb1 then
     begin
          xTCP.DB         :=TMyClient.Create(nil);
          xTCP.DB.Hostname:=CSQL.Hostname;
          xTCP.DB.Port    :=CSQL.Port;
          xTCP.DB.Database:=CSQL.Database;
          xTCP.DB.Username:=CSQL.Username;
          xTCP.DB.Password:=CSQL.Password;
     end;

     if not xTCP.DB.conectado then
        xTCP.DB.Open;

     if Idb2 then
     begin
          xTCP.DB2         :=TMyClient.Create(nil);
          xTCP.DB2.Hostname:=CSQL.Hostname;
          xTCP.DB2.Port    :=CSQL.Port;
          xTCP.DB2.Database:=CSQL.Database;
          xTCP.DB2.Username:=CSQL.Username;
          xTCP.DB2.Password:=CSQL.Password;
     end;

     if not xTCP.DB2.conectado then
        xTCP.DB2.Open;

     w:=' and auxiliar.hora=' + sdb(copy(nHora,1,8)) + ' and auxiliar.atendente=' + zedb(cUser);

     if nSessao <> '' then
        w:=' and auxiliar.idtimer=' + sdb(nSessao);

     if (nSessao = '') and (nHora = '') then
         w:='';

     w:='select estoque.grupo,auxiliar.id from auxiliar,estoque where auxiliar.idpedido=' + id +
        ' and auxiliar.producao=0 and estoque.codigo=auxiliar.original' + w + ' order by estoque.grupo,auxiliar.id';

     dbx(xTCP.DB,w);

     lG.Clear;
     cG.Clear;

     s:='GRUPOS:';

     for i:=0 to xTCP.DB.Query.DataCount -1 do
     begin
          lG.Add(dfx(xTCP.DB,i,'grupo','0'));
          cG.Add(dfx(xTCP.DB,i,'id'   ,'0'));

          if SATEXT_DEBUG then
             s:=s + '<' + dfx(xTCP.DB,i,'grupo','0') + ',' + dfx(xTCP.DB,i,'id'   ,'0') + '>';
     end;

     if check_duplicidade_producao(id,cG) then
     begin
           xTCP.ERRO :=98;
           xTCP.DERRO:='DUPLICIDADE DE PEDIDO';

           notificar_terminal(xTCP);

           libera();

           log_sat_service(xTCP.DERRO + ' ' + ID + ' cUser: ' + cUser + '  Terminal: ' + cTerminal,nil,xTCP);

           xTCP.FecharSQL;

           exit;
     end;

     if SATEXT_DEBUG then
     begin
          log_sat_service(w,nil,xTCP);
          log_sat_service(s,nil,xTCP);
     end;

     for i:=0 to High(LPRINT.lista) do
     begin
          LPRINT.lista[i].filtros.Clear;
          LPRINT.lista[i].filtrog.Clear;
     end;

     temItem:=False;

     for i:=0 to High(LPRINT.lista) do
     begin
          if not LPRINT.lista[i].gerenciado then
             continue;

          for j:=0 to High(LPRINT.lista[i].gLista) do
          begin
               for u:=0 to lG.Count -1 do
               begin
                    if LPRINT.lista[i].gLista[j].marcado then
                    begin
                         if lG[u] = LPRINT.lista[i].gLista[j].id then
                         begin
                              LPRINT.lista[i].filtraGrupo(lG[u]);
                              LPRINT.lista[i].filtros.Add(cG[u]);
                              temItem:=True;
                         end;
                    end;
               end;
          end;
     end;

     for i:=0 to High(LPRINT.lista) do
     begin
          if LPRINT.lista[i].filtrog.Count = 0 then
             continue;

          id_impressora  :=LPRINT.lista[i].idCfg;
          rcsprintporta  :=LPRINT.lista[i].porta;
          nome_impressora:=LPRINT.lista[i].descricao;
          codi_impressora:=LPRINT.lista[i].id;
          rcsprintnomewindows:=LPRINT.lista[i].spooler;

          xTCP.ERRO      :=0;
          xTCP.DERRO     :='';

          if not confereStatus(i) then
          begin
               xTCP.ERRO :=50;
               xTCP.DERRO:=LPRINT.lista[i].botao_id;
          end;

          if id_impressora = '' then
          begin
               xTCP.ERRO :=52;
               xTCP.DERRO:='IMPRESSORA NAO CONFIGURADA';
               ERRO_1    :=inttostr(xTCP.ERRO);
               ERRO_2    :=xTCP.DERRO;

               log_sat_service(xTCP.DERRO,nil,xTCP,True);

               if notifica then
                  notificar_terminal(xTCP);

               continue;
          end;

          try
               if pf <> id_impressora then
               begin
                    pf:=id_impressora;
                    perfilImpressora(id_impressora,xTCP.DB2);

                    log_sat_service('PERFIL ' + id_impressora,nil,xTCP,True);
               end;

               if xTCP.ERRO > 0 then
               begin
                    log_sat_service('ERRO ' + inttostr(xTCP.ERRO) ,nil,xTCP,True);

                    ERRO_1:=IntToStr(xTCP.ERRO);
                    ERRO_2:=xTCP.DERRO;

                    log_msg_services('SPOOLER ' + rcsPrintNomeWindows);

                    if rcsPrintNomeWindows <> '' then
                    begin
                         cG.Text:=LPRINT.lista[i].filtros.Text;

                         log_sat_service('tentar spool cupom_impressao_producao(' + id + ',True,"",[],' + cG.Text + ',' + cUser + ');',nil,xTCP,True);

                         try

                             IOK     :=cupom_impressao_producao(id,True,'',[],cG,xErro,cUser,xTCP.DB,xTCP.DB2,True);
                             tempoMED:=GetTickCount();

                         except on e:exception do
                                begin
                                     log_sat_service('SPOOLER STAGE ERRO ' + inttostr(xErro) + ' / funcao ' + e.Message,nil,xTCP,True);
                                end;
                         end;

                         log_sat_service('IOK ' + flagtostr(IOK) + ' STAGE => ' + inttostr(xErro),nil,xTCP,True);

                         if not IOK then
                         begin
                              xTCP.ERRO :=2;
                              xTCP.DERRO:=CUPOM_MSG_ERRO;
                              ERRO_1    :=inttostr(xTCP.ERRO);
                              ERRO_2    :=xTCP.DERRO;
                         end
                         else
                             tpSpooler:=True;
                    end;
               end
               else
               begin
                    cG.Text:=LPRINT.lista[i].filtros.Text;

                    log_sat_service('cupom_impressao_producao(' + id + ',True,"",[],' + cG.Text + ',' + cUser + ');',nil,xTCP,True);

                    try

                        IOK     :=cupom_impressao_producao(id,True,'',[],cG,xErro,cUser,xTCP.DB,xTCP.DB2,False);
                        tempoMED:=GetTickCount();

                    except on e:Exception do
                           begin
                                log_sat_service('STAGE ERRO ' + inttostr(xErro) + ' / funcao ' + e.Message,nil,xTCP,True);
                           end;
                    end;

                    log_sat_service('IOK ' + flagtostr(IOK) + ' STAGE => ' + inttostr(xErro),nil,xTCP,True);

                    if not IOK then
                    begin
                         xTCP.ERRO :=2;
                         xTCP.DERRO:=CUPOM_MSG_ERRO;
                         ERRO_1    :=inttostr(xTCP.ERRO);
                         ERRO_2    :=xTCP.DERRO;
                    end;
               end;

               if IOK then
               begin
                    xTCP.ERRO :=0;
                    xTCP.DERRO:='Processado com Sucesso';

                    if notifica then
                       notificar_terminal(xTCP);

                    for u:=0 to LPRINT.lista[i].filtros.Count -1 do
                    begin
                         with xTCP.DB do
                         begin
                              query.reset;
                              modify.reset;
                              modify.add('producao','1');
                              modify.PrepareUpdateTask('auxiliar',sch('where id=' + LPRINT.lista[i].filtros[u]),'',nil,nil);
                              execute;
                         end;
                    end;
               end;

               nUser:='N/D';

               if dbx(xTCP.DB,'select * from vendedor where cadastro=' + cUser) > 0 then
                  nUser:=dfx(xTCP.DB,0,'nome');

               dbx(xTCP.DB,'select id,referencia,mesa,infomesa,turno from pedidos where id=' + id);
               referencia:=dfx(xTCP.DB,0,'referencia');
               comanda   :=dfx(xTCP.DB,0,'mesa');
               infomesa  :=dfx(xTCP.DB,0,'infomesa');
               turno     :=dfx(xTCP.DB,0,'turno','0');

               with xTCP.DB do
               begin
                    query.reset;
                    modify.reset;
                    modify.add('turno'     ,sch(zedb(turno)));
                    modify.add('tipo'      ,sch(sdb('PRD')));
                    modify.add('pedido'    ,sch(zedb(id)));
                    modify.add('data'      ,sch(datdb(datetostr(date()))));
                    modify.add('hora'      ,sch(sdb(timetostr(time()))));
                    modify.add('usuario'   ,sch(zedb(cUser)));
                    modify.add('nome'      ,sch(sdb(nUser)));
                    modify.add('terminal'  ,sch(zedb(cTerminal)));
                    modify.add('cImp'      ,sch(zedb(codi_impressora)));
                    modify.add('impressora',sch(sdb(nome_impressora)));
                    modify.add('pImp'      ,sch(sdb(rcsprintporta)));
                    modify.add('status'    ,sch(sdb(LPRINT.lista[i].filtrog.Text)));
                    modify.add('obs'       ,sch(sdb(LPRINT.lista[i].filtros.Text)));
                    modify.add('erro'      ,sch(inttostr(xTCP.ERRO)));
                    modify.add('infoErro'  ,sch(sdb(xTCP.DERRO)));
                    modify.add('comanda'   ,sch(sdb(comanda)));
                    modify.add('mesa'      ,sch(sdb(infomesa)));
                    modify.add('referencia',sch(sdb(referencia)));
                    modify.add('tempo'     ,sch(picdb(floattostr((tempoMED - tempoIni) / 1000))));
                    if tpSpooler then
                    modify.add('spooler'   ,'1');
                    modify.add('cmd'       ,sch(sdb(cmd)));
                    modify.prepareinserttask('mobisuporte','',nil,nil);
                    execute;
               end;

          except on E:Exception do
                 begin
                      xTCP.ERRO :=3;
                      xTCP.DERRO:='ERRO NO PROCESSAMENTO DO PEDIDO ' + id + ' / ' + CUPOM_MSG_ERRO;
                      ERRO_1    :=inttostr(xTCP.ERRO);
                      ERRO_2    :=xTCP.DERRO;
                 end;
          end;
     end;

     if not IOK then
     begin
          if notifica then
          begin
               xTCP.ERRO :=picInt(ERRO_1);
               xTCP.DERRO:=ERRO_2;

               notificar_terminal(xTCP);
          end;
     end;

     libera();

     xTCP.FecharSQL;

     xTCP.sessao:='';

   except on e:Exception do
          begin
               xTCP.ERRO :=33;
               xTCP.DERRO:='ERRO GERAL NO PEDIDO ';

               if notifica then
                  notificar_terminal(xTCP);
          end;
   end;
end;

function TConectLabMobile64.check_duplicidade_producao(id:String;ids:TStringList):Boolean;
var
   pd:TStringList;
   a:String;
   i,j:Integer;
begin
     result:=False;

     pd:=TStringList.Create();
     a :=PASTA_CACHE + id + '.log';

     if fileexists(a) then
     begin
          pd.LoadFromFile(a);

          for i:=0 to pd.Count -1 do
          begin
               for j:=0 to ids.Count -1 do
               begin
                    if pd[i] = ids[j] then
                    begin
                         result:=True;
                         break;
                    end;
               end;

               if result then
                  break;
          end;
     end;

     if not result then
     begin
          for i:=0 to ids.Count -1 do
              pd.Add(ids[i]);

          try

              pd.SaveToFile(a);

          except on e:Exception do
                 begin

                 end;
          end;

     end;
end;

procedure TConectLabMobile64.registrar_pedidos_json(xTCP:TrcsCnService;jsonTxt:WideString);
var
   nItems,
   i:Integer;

   nUser,
   referencia,
   comanda,
   infomesa,
   SESSAO:String;
   w,
   param_:String;

   eProducao:Boolean;
   xSize:Currency;

   codigo,
   cRef,
   unidade,
   descricao,
   data,
   hora,
   itemObs,
   opcoes,
   cliente,
   turno,
   vTotal:String;

   qtde,
   preco,
   total,
   adicional:Currency;

   kProdutos:TStringList;

   pedBloque,
   terBloque,
   IOK:Boolean;

   tpINI,
   tpEND:Cardinal;

   id,
   cUser,
   cTerminal:String;

   JSON:TlkJSONobject;

   JPedido,
   JSessao,
   JProd,
   JConf,
   JItems,
   JItem,
   JOperacao,
   JUsuario,
   JTerminal:TlkJSONbase;

   SERRO,
   XERRO:String;

   vTurno,
   vTerminal:String;

   procedure novaConexaoDb_();
   begin
        if xTCP.DB = nil then
        begin
             xTCP.DB         :=TMyClient.Create(nil);
             xTCP.DB.Hostname:=CSQL.Hostname;
             xTCP.DB.Port    :=CSQL.Port;
             xTCP.DB.Database:=CSQL.Database;
             xTCP.DB.Username:=CSQL.Username;
             xTCP.DB.Password:=CSQL.Password;
        end;

        if not xTCP.DB.conectado then
           xTCP.DB.Open;
   end;

   procedure registraPIT();
   begin
        tpEND:=GetTickCount();

        if (not IOK) or SATEXT_DEBUG then
        begin
             if not IOK then
                notificar_terminal(xTCP);

             nUser:='N/D';

             novaConexaoDb_();

             if picInt(cUser) = 0 then
                cUser:='0';

             if dbx(xTCP.DB,'select * from vendedor where cadastro=' + cUser) > 0 then
                nUser:=dfx(xTCP.DB,0,'nome');

             with xTCP.DB do
             begin
                  query.reset;
                  modify.reset;
                  modify.add('turno'     ,sch(zedb(turno)));
                  modify.add('tipo'      ,sch(sdb('PIT')));
                  modify.add('pedido'    ,sch(zedb(id)));
                  modify.add('data'      ,sch(datdb(datetostr(date()))));
                  modify.add('hora'      ,sch(sdb(timetostr(time()))));
                  modify.add('usuario'   ,sch(zedb(cUser)));
                  modify.add('nome'      ,sch(sdb(nUser)));
                  modify.add('terminal'  ,sch(zedb(cTerminal)));
                  modify.add('erro'      ,sch(inttostr(xTCP.ERRO)));
                  modify.add('infoErro'  ,sch(sdb(xTCP.DERRO)));
                  modify.add('comanda'   ,sch(sdb(comanda)));
                  modify.add('mesa'      ,sch(zedb(infomesa)));
                  modify.add('obs'       ,sch(sdb(kProdutos.Text)));
                  modify.add('tempo'     ,sch(picdb(floattostr((tpEND - tpINI) / 1000))));
                  modify.add('cmd'       ,sch(sdb(arquivos_string_to_hex(jsonTxt))));
                  modify.add('referencia',sch(sdb(referencia)));
                  modify.prepareinserttask('mobisuporte','',nil,nil);
                  execute;
             end;
        end;
   end;

begin
     //
     //     Iniciando Variaveis de Controle
     //
     //
     tpINI        :=GetTickCount();
     tpEND        :=tpINI;
     rcsprintporta:='';
     IOK          :=False;
     xTCP.ERRO    :=0;

     //
     //     Abrindo dados JSON
     //
     //
     JSON:=TlkJSON.ParseText(jsonTxt) as TlkJSONobject;

     if JSON = nil then
     begin
          xTCP.ERRO :=300;
          xTCP.DERRO:='DADOS COM FORMATO ERRADO json';
     end
     else
     begin
          //
          //     Pegando dados do JSON
          //
          //
          JSessao  :=JSon.Field['sessao'  ];
          JOperacao:=JSon.Field['operacao'];
          JPedido  :=JSon.Field['pedido'  ];
          JUsuario :=JSon.Field['usuario' ];
          JTerminal:=JSon.Field['terminal'];
          JConf    :=JSon.Field['conf'    ];
          JItems   :=JSon.Field['items'   ];

          if JOperacao = nil then
          begin
               xTCP.ERRO :=301;
               xTCP.DERRO:='DADOS JSON FORMATO ERRADO';
          end;

          if JPedido = nil then
          begin
               xTCP.ERRO :=302;
               xTCP.DERRO:='ID PEDIDO FORMATO ERRADO';
          end;
     end;

     //
     //     Se ocorrer algum erro cancelar operação
     //
     //
     if xTCP.ERRO > 0 then
     begin
          //  Enviar erro para o client
          //
          notificar_terminal(xTCP);

          //  Registra log mesmo com dados invalidos
          //
          registraPIT();

          //  Libera conexão SQL
          //

          xTCP.FecharSQL;

          exit;
     end;

     //
     //     Outros dados
     //
     //
     if JUsuario <> nil then
        cUser:=JUsuario.Value;

     if cUser = '' then
        cUser:='1';

     if JTerminal <> nil then
        cTerminal:=JTerminal.Value;

     if testz(cTerminal) then
        cTerminal:=TERMINAL_NUMERO;

     SESSAO   :=JSessao.Value;
     param_   :=JConf.Value;
     id       :=JPedido.Value;

     kProdutos:=TStringList.Create();
     kProdutos.Clear();

     //
     //     Pega os items do pedido
     //
     //
     if JItems <> nil then
     begin
          for i:=0 to pred(JItems.Count) do
          begin
               JItem:=TlkJSONObject(JItems).child[i];
               JProd:=JItem.Field['i' + inttostr(i)];

               if JProd <> nil then
                  kProdutos.Add(JProd.Value);
          end;
     end;

     if SATEXT_DEBUG then
     begin
          log_sat_service('sessao: '   + sessao   ,nil,xTCP,True);
          log_sat_service('id: '       + id       ,nil,xTCP,True);
          log_sat_service('usuario: '  + cuser    ,nil,xTCP,True);
          log_sat_service('terminal: ' + cterminal,nil,xTCP,True);
          log_sat_service('conf: '     + param_   ,nil,xTCP,True);
          log_sat_service('dados'                 ,kProdutos,xTCP,True);
     end;

     //
     //     Abrindo conexão com SQL
     //
     //
     novaConexaoDb_();

     vTurno   :='';
     vTerminal:='';

     try
          if SATEXT_DEBUG then log_sat_service('passo 1',nil,xTCP,True);
          //  Identifica o atendente
          //

          if dbx(xTCP.DB,'select * from vendedor where cadastro=' + cUser) > 0 then
          begin
               cUser:=dfx(xTCP.DB,0,'id','0');

               if CEL_USUARIO_POR_VEZ then
               begin
                    vTurno   :=dfx(xTCP.DB,0,'turno'   ,'0');
                    vTerminal:=dfx(xTCP.DB,0,'terminal','0');
               end;
          end;

          if SATEXT_DEBUG then log_sat_service('passo 2',nil,xTCP,True);
          //  Identifica o pedido
          //
          dbx(xTCP.DB,'select id,idcliente,referencia,mesa,infomesa,turno,bloqueado from pedidos where id=' + id);
          cliente   :=dfx(xTCP.DB,0,'idcliente','0');
          referencia:=dfx(xTCP.DB,0,'referencia'   );
          comanda   :=dfx(xTCP.DB,0,'mesa'         );
          infomesa  :=dfx(xTCP.DB,0,'infomesa'     );
          turno     :=dfx(xTCP.DB,0,'turno'    ,'0');
          pedBloque :=dfx(xTCP.DB,0,'bloqueado','0') = 1;
          terBloque :=False;

          if SATEXT_DEBUG then log_sat_service('passo 3',nil,xTCP,True);

          if CEL_USUARIO_POR_VEZ then
          begin
               if (turno = vTurno) and (cTerminal = vTerminal) then
               begin
               end
               else
               begin
                    if dbx(xTCP.DB,'select * from vendedor where id=' + cUser + ' and turno=' + turno) = 0 then
                    begin
                         with xTCP.DB do
                         begin
                              query.reset;
                              modify.reset;
                              modify.add('terminal',sch(zedb(cTerminal)));
                              modify.add('turno'   ,sch(zedb(turno)));
                              modify.prepareupdatetask('vendedor',sch('where id=' + cUser),'',nil,nil);
                              execute;
                         end;
                    end
                    else
                    begin
                         if dfx(xTCP.DB,0,'terminal','0') <> cTerminal then
                            terBloque:=True;
                    end;
               end;
          end;


          if SATEXT_DEBUG then log_sat_service('passo 4',nil,xTCP,True);
          //  Pega data e hora do servidor
          //
          sql_dateTime(data,hora,0,xTCP.DB);

          //
          //     Se o pedido estiver bloqueado ou sem produtos
          //     gera um erro para o client
          //

          if SATEXT_DEBUG then log_sat_service('passo 5',nil,xTCP,True);

          if (kProdutos.Count = 0) or pedBloque or terBloque then
          begin
               if terBloque then
               begin
                    xTCP.ERRO :=63;
                    xTCP.DERRO:='USUARIO BLOQUEADO NO TERMINAL';
               end
               else
               begin
                    if pedBloque then
                    begin
                         xTCP.ERRO :=62;
                         xTCP.DERRO:='PEDIDO BLOQUEADO NA PRE-CONTA';
                    end
                    else
                    begin
                         xTCP.ERRO :=61;
                         xTCP.DERRO:='PRODUTOS COM DADOS INVALIDOS';
                    end;
               end;
          end
          else
          begin
               //
               //   Tudo ok, vamos processar os dados
               //
               //

               //   Qtde de items no pedido para conferencia
               //
               xSize    :=picf(cs(param_,'|'));

               //   Se = 1 enviar para producao
               //
               eProducao:=cs(param_,'|') = '1';
               nItems   :=0;

               PED_QTDES:='0';
               PED_VALOR:='0,00';
               PED_TOTAL:='0,00';

               //   Se o tamanho da lista for diferente do enviado pelo
               //   client, gerar erro
               //
               if xSize <> kProdutos.Count then
               begin
                    xTCP.ERRO :=62;
                    xTCP.DERRO:='PRODUTOS COM DADOS INVALIDOS - TAMANHO';
               end
               else
               begin
                    if SATEXT_DEBUG then log_sat_service('passo 6',nil,xTCP,True);
                    //   Tudo Certo
                    //
                    nItems:=dbx(xTCP.DB,'select id from auxiliar where idtimer=' + sdb(SESSAO));

                    //   Se a sessao ja foi processado
                    //   avisar o client
                    //
                    if nItems > 0 then
                    begin
                         IOK       :=True;
                         xTCP.ERRO :=0;
                         xTCP.DERRO:='0';

                         notificar_terminal(xTCP);
                    end
                    else
                    begin
                         //
                         //   Processar a inclusao dos items no pedido
                         //
                         //
                         nItems:=0;

                         if SATEXT_DEBUG then log_sat_service('passo 7',nil,xTCP,True);

                         for i:=0 to kProdutos.Count -1 do
                         begin
                              param_   :=kProdutos[i];
                              codigo   :=cs(param_);
                              qtde     :=picf(cs(param_));
                              itemObs  :=cs(param_);
                              opcoes   :=cs(param_);
                              adicional:=picf(cs(param_));

                              cRef     :='';
                              preco    :=0;
                              unidade  :='un';
                              descricao:='diversos';

                              if itemObs <> '' then
                                 itemObs:=arquivos_hex_string(itemObs);

                              if opcoes <> '' then
                                 opcoes:=arquivos_hex_string(opcoes);

                              if SATEXT_DEBUG then log_sat_service('passo 7A-' + inttostr(i) ,nil,xTCP,True);

                              //  Pega detalhes do produto no cadastro
                              //
                              if dbx(xTCP.DB,'select * from estoque where codigo=' + codigo) > 0 then
                              begin
                                   cRef     :=dfx(xTCP.DB,0,'referencia');
                                   preco    :=dfx(xTCP.DB,0,'preco','f');
                                   unidade  :=dfx(xTCP.DB,0,'undv');
                                   descricao:=dfx(xTCP.DB,0,'descricao');

                                   log_sat_service('VALORES? ' + dfx(xTCP.DB,0,'preco','f') + '/' + dfx(xTCP.DB,0,'preco') + '/' + floattostr(preco) + '/' + DecimalSeparator + '/' + picdb(floattostr(preco)),nil,xTCP,True);
                              end;

                              if SATEXT_DEBUG then log_sat_service('passo 7B-' + inttostr(i) ,nil,xTCP,True);

                              total:=(preco + adicional) * qtde;

                              //   Salvando item no pedido
                              //
                              with xTCP.DB do
                              begin
                                   query.reset;
                                   modify.reset;
                                   modify.Add('idpedido'  , sch(iDb(id)));
                                   modify.Add('original'  , sch(iDb(codigo)));
                                   if cRef <> '' then
                                   modify.Add('referencia', sch(sdb(cRef)));
                                   modify.Add('qtde'      , sch(fDb(qtde)));
                                   modify.Add('unidade'   , sch(sdb(unidade)));
                                   modify.Add('nome'      , sch(sdb(descricao)));
                                   modify.Add('valor'     , sch(fDb(preco)));
                                   modify.Add('preco'     , sch(fDb(preco)));
                                   modify.Add('total'     , sch(fDb(total)));

                                   modify.Add('idcliente' , sch(iDb(cliente)));
                                   modify.Add('data'      , sch(datdb(data)));
                                   modify.Add('hora'      , sch(sdb(hora)));
                                   modify.Add('itemobs'   , sch(sdb(itemObs)));
                                // modify.Add('ctl'       , sch(zedb(inttostr(Upd.ctl))));
                                   modify.Add('opcoes'    , sch(sdb(opcoes)));
                                   modify.Add('adicional' , sch(fDb(adicional)));
                                   modify.Add('turno'     , sch(zedb(turno)));
                                // modify.Add('promocao'  , sch(zedb(Upd.promocao)));
                                   modify.Add('atendente' , sch(zedb(cUser)));
                                   modify.Add('producao'  , '0');
                                   modify.Add('terminal'  , sch(zedb(cTerminal)));
                                   modify.Add('idtimer'   , sch(sdb(SESSAO)));
                                   modify.prepareinserttask('auxiliar', 'i', nil, nil);
                                   execute;
                              end;

                              if SATEXT_DEBUG then log_sat_service('passo 7C-' + inttostr(i) ,nil,xTCP,True);

                              inc(nItems);

                              //   Saida do estoque
                              //
                              produtos_ajusta_estoque(codigo, qtde, '0', True, xTCP.DB);

                              if SATEXT_DEBUG then log_sat_service('passo 7D-' + inttostr(i) ,nil,xTCP,True);
                         end;

                         if SATEXT_DEBUG then log_sat_service('passo 8',nil,xTCP,True);

                         //  Totalizar Produtos
                         //
                         totalizar_produtos_pedidos(id,xTCP.DB);

                         SERRO:='';
                         XERRO:='';

                         if SATEXT_DEBUG then log_sat_service('passo 9',nil,xTCP,True);

                         if eProducao then
                         begin
                              imprimir_producao(xTCP,id,cUser,cTerminal,'',sessao,False);

                              SERRO:=inttostr(xTCP.ERRO);
                              XERRO:=xTCP.DERRO;
                         end;
                    end;

                    if SATEXT_DEBUG then log_sat_service('passo 10',nil,xTCP,True);

                    IOK       :=True;
                    xTCP.ERRO :=0;
                    xTCP.DERRO:='0|' + inttostr(nItems) + '|' + PED_QTDES + '|' + PED_VALOR + '|' + PED_TOTAL + '|' + SERRO + '|' + XERRO;
               end;

               notificar_terminal(xTCP);
          end;

     except on e:Exception do
            begin
                 xTCP.ERRO :=3;
                 xTCP.DERRO:='ERRO NO PROCESSAMENTO DO PEDIDO ' + id;
                 IOK       :=False;
            end;
     end;

     registraPIT();

     kProdutos.Text:=jsonTxt + ' ' + floattostr((tpEND - tpINI) / 1000) + 't ' + ifthen(IOK,'OK','ERRO');

     log_sat_service('',kProdutos,xTCP);

     xTCP.FecharSQL;

     FreeAndNil(kProdutos);
end;

procedure TConectLabMobile64.servico_status(xTCP:TrcsCnService;jsonTxt:WideString);
const
   op = 'status';

var
   JSON :TlkJSONobject;
   c1,c2:TlkJSONbase;

   id,
   nome,
   xjson:String;

   i:Integer;
begin
     log_sat_service('servico_status: ' + jsonTxt,nil,nil,True);

     try
          JSON:=TlkJSON.ParseText(jsonTxt) as TlkJSONobject;

          c1:=JSON.Field['id'];

          xjson:='{"status":"erro","erro":"$code","aviso":"$msg"}';

          if c1 = nil then
             GOERROS(xTCP,xjson,jsonTxt,op,'100','ID invalido do dispositivo')
          else
          begin
               id:=c1.Value;

               if xTCP.DB = nil then
               begin
                    xTCP.DB         :=TMyClient.Create(nil);
                    xTCP.DB.Hostname:=CSQL.Hostname;
                    xTCP.DB.Port    :=CSQL.Port;
                    xTCP.DB.Database:=CSQL.Database;
                    xTCP.DB.Username:=CSQL.Username;
                    xTCP.DB.Password:=CSQL.Password;
               end;

               if not xTCP.DB.conectado then
                  xTCP.DB.Open;

               nome:='';

               if dbx(xTCP.DB,'select id,empresa,fantasia from rclsoft order by id') > 0 then
               begin
                    nome:=dfx(xTCP.DB,0,'fantasia');

                    if nome = '' then
                       nome:=dfx(xTCP.DB,0,'empresa');
               end;

               for i:=1 to 2 do
               begin
                    if dbx(xTCP.DB,'select * from regtermi where modelocpu="' + id + '" order by id') > 0 then
                    begin
                         xTCP.terminal:=dfx(xTCP.DB,0,'id','0');

                         jsonTxt:='{"status":"ok"' +
                                  ',"terminal":"'  + xTCP.terminal + '"' +
                                  ',"nome":"'      + nome + '"' +
                                  ',"code":"200"'  +
                                  ',"aviso":"Em operacao"' +
                                  ',"timeout":'    + IntToStr(APP_TIMEOUT) + '}';
                         break;
                    end
                    else
                    begin
                         with xTCP.DB do
                         begin
                              query.reset;
                              modify.reset;
                              modify.add('terminal' ,sdb(id));
                              modify.add('modelocpu',sdb(id));
                              modify.add('irq'      ,sdb('1011'));
                              modify.add('local'    ,sdb(id));
                              modify.prepareinserttask('regtermi','',nil,nil);
                              execute;
                         end;
                    end;
               end;

               xTCP.FecharSQL;
          end;

     except on e:exception do
            begin
                 GOERROS(xTCP,xjson,jsonTxt,op,'051','Erro de excecao')
            end;
     end;

     log_sat_service('servico_status: ' + jsonTxt,nil,nil,True);

     notificar_terminal(xTCP,jsonTxt);
end;

procedure TConectLabMobile64.servico_mysql(xTCP:TrcsCnService;jsonTxt:WideString);
const
   op = 'mysql';

var
   xjson:String;
begin
     log_sat_service('servico_mysql GET: ' + jsonTxt,nil,nil,True);

     xjson:='{"status":"erro","erro":"$code","aviso":"$msg"}';

     try

        jsonTxt:='{"status":"ok",' +
                 '"ip":"'          + CSQL.hostname       + '",' +
                 '"porta":"'       + IntToStr(CSQL.port) + '",' +
                 '"database":"'    + CSQL.database       + '",' +
                 '"username":"'    + encrypt_str(CSQL.username) + '",' +
                 '"password":"'    + encrypt_str(CSQL.password) + '"}';

     except on e:exception do
            begin
                 GOERROS(xTCP,xjson,jsonTxt,op,'051','Erro de excecao')
            end;
     end;

     log_sat_service('servico_mysql PUT: ' + jsonTxt,nil,nil,True);

     notificar_terminal(xTCP,jsonTxt);
end;

procedure TConectLabMobile64.servico_login(xTCP:TrcsCnService;jsonTxt:WideString);
const
   op = 'login';

var
   JSON:TlkJSONobject;

   c1,c2,c3:TlkJSONbase;

   cp,
   codigo,
   usuario,
   senha,
   terminal,
   comanda,
   xjson:String;

   i:Integer;
begin
     log_sat_service('servico_login GET: ' + jsonTxt,nil,nil,True);

     xjson:='{"status":"erro","erro":"$code","aviso":"$msg"}';

     try

          JSON:=TlkJSON.ParseText(jsonTxt) as TlkJSONobject;
          c1  :=JSON.Field['terminal'];
          c2  :=JSON.Field['usuario' ];
          c3  :=JSON.Field['senha'   ];

          if (c2 = nil) or (c3 = nil) then
              GOERROS(xTCP,xjson,jsonTxt,op,'101','Usuario ou Senha invalida')
          else
          begin
               terminal:='';
               usuario :='';
               senha   :='';

               if c1 <> nil then
                  terminal:=c1.Value;

               if c2 <> nil then
                  usuario:=c2.Value;

               if c3 <> nil then
                  senha:=encrypt_str(c3.Value);

               try

                    usuario:=decrypt_str(usuario);
                    senha  :=decrypt_str(senha);

               except on e:exception do
                      begin
                           usuario:='';
                           senha  :='';
                      end;
               end;

               if (usuario = '') and (senha = '') then
                   GOERROS(xTCP,xjson,jsonTxt,op,'101','Usuario ou Senha invalida *')
               else
               begin
                    if xTCP.terminal <> '' then
                       terminal:=xTCP.terminal;

                    if picF(terminal) = 0 then
                       GOERROS(xTCP,xjson,jsonTxt,op,'102','Solicite o status antes do login')
                    else
                    begin
                         if xTCP.DB = nil then
                         begin
                              xTCP.DB         :=TMyClient.Create(nil);
                              xTCP.DB.Hostname:=CSQL.Hostname;
                              xTCP.DB.Port    :=CSQL.Port;
                              xTCP.DB.Database:=CSQL.Database;
                              xTCP.DB.Username:=CSQL.Username;
                              xTCP.DB.Password:=CSQL.Password;
                         end;

                         if not xTCP.DB.conectado then
                            xTCP.DB.Open;

                         if dbx(xTCP.DB,'select * from usuarios where nome=' + sdb(usuario) + ' and senha=' + sdb(senha)) > 0 then
                         begin
                              if dfx(xTCP.DB,0,'bloqueado','0') > 0 then
                                 jsonTxt:='{"status":"erro"' +
                                          ',"codigo":"'      + dfx(xTCP.DB,0,'codigo','0') + '"' +
                                          ',"code":"103"'    +
                                          ',"aviso":"Usuario Bloqueado"}'
                              else
                              begin
                                   codigo  :=dfx(xTCP.DB,0,'codigo','0');
                                   jsonTxt:='{"status":"ok"' +
                                            ',"codigo":"'    + codigo + '"' +
                                            ',"code":"201"'  +
                                            ',"aviso":"Conectado"' +
                                            ',"timeout":'    + IntToStr(LOG_TIMEOUT) +
                                            ',"comanda":"';

                                   comanda:='';
                                   //
                                   //  Validando lista de Atendentes
                                   //
                                   if dbx(xTCP.DB,'select id from vendedor where cadastro=' + codigo) = 0 then
                                   begin
                                        with xTCP.DB do
                                        begin
                                             query.reset;
                                             modify.reset;
                                             modify.add('cadastro',codigo);
                                             modify.add('nome'    ,sdb(usuario));
                                             modify.add('ativo'   ,'1');
                                             modify.prepareinserttask('vendedor','',nil,nil);
                                             execute;
                                        end;

                                        if dbx(xTCP.DB,'select id from vendedor where cadastro=' + codigo) > 0 then
                                        begin
                                             ATENDENTES.Add(dfx(xTCP.DB,0,'id','0'),
                                                            codigo,
                                                            usuario);
                                        end;
                                   end;

                                   if dbx(xTCP.DB,'select * from set_mult where nome="CONTROLE_INTERNO_DE_COMANDAS"') > 0 then
                                   begin
                                        comanda:=comanda + dfx(xTCP.DB,0,'id_1','0') + ';' +
                                                           dfx(xTCP.DB,0,'id_2','0') + ';' +
                                                           dfx(xTCP.DB,0,'id_3','0') + ';' +
                                                           dfx(xTCP.DB,0,'id_4','0');
                                   end;

                                   jsonTxt:=jsonTxt + comanda + '"}';
                              end;
                         end
                         else
                             GOERROS(xTCP,xjson,jsonTxt,op,'104','Usuario nao cadastrado');

                         xTCP.FecharSQL;
                    end;
               end;
          end;

     except on e:exception do
            begin
                 GOERROS(xTCP,xjson,jsonTxt,op,'051','Erro de excecao')
            end;
     end;

     log_sat_service('servico_login PUT: ' + jsonTxt,nil,nil,True);

     notificar_terminal(xTCP,jsonTxt);
end;

procedure TConectLabMobile64.servico_logoff(xTCP:TrcsCnService;jsonTxt:WideString);
const
   op = 'logoff';

var
   JSON :TlkJSONobject;
   c1,c2:TlkJSONbase;

   codigo,
   terminal,
   xjson:String;
begin
     log_sat_service('servico_logoff GET: ' + jsonTxt,nil,nil,True);

     xjson:='{"status":"erro","erro":"$code","aviso":"$msg"}';

     try

        JSON:=TlkJSON.ParseText(jsonTxt) as TlkJSONobject;

        c1:=JSon.Field['terminal'];
        c2:=JSon.Field['codigo'  ];

        if (c1 = nil) or (c2 = nil) then
            GOERROS(xTCP,xjson,jsonTxt,op,'105','Codigo do usuario invalido')
        else
        begin
             terminal:='';
             codigo  :='';

             if c1 <> nil then terminal:=c1.Value;
             if c2 <> nil then codigo  :=c2.Value;

             if (terminal = '') or (codigo = '') then
                 GOERROS(xTCP,xjson,jsonTxt,op,'105','Codigo do usuario invalido')
             else
                 jsonTxt:='{"status":"ok"' +
                          ',"code":"202"' +
                          ',"aviso":"Desconectado"}';
        end;

     except on e:exception do
            begin
                 GOERROS(xTCP,xjson,jsonTxt,op,'051','Erro de excecao')
            end;
     end;

     log_sat_service('servico_logoff PUT: ' + jsonTxt,nil,nil,True);

     notificar_terminal(xTCP,jsonTxt);
end;

function TConectLabMobile64.TokenValido(ntoken:String):Boolean;
begin
     result:=Length(ntoken) = 8;
end;

procedure TAtendentes.Add(id,codigo,nome:String);
var
   p:Integer;
begin
     p:=High(Users) + 1;
     SetLength(Users,p + 1);
     Users[p]         :=TIAtendente.Create;
     Users[p].id      :=id;
     Users[p].cadastro:=codigo;
     Users[p].nome    :=nome;
end;

function TAtendentes.idAtendente(codigo:String):String;
var
   i:Integer;
begin
     result:='';

     for i:=0 to High(Users) do
     begin
          if Users[i].cadastro = codigo then
          begin
               result:=Users[i].id;
               break;
          end;
     end;
end;

function TAtendentes.codigoAtendente(id:String):String;
var
   i:Integer;
begin
     result:='';

     for i:=0 to High(Users) do
     begin
          if Users[i].id = id then
          begin
               result:=Users[i].cadastro;
               break;
          end;
     end;
end;

end.
