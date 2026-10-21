function salida = simulacion_aro_resorte(caso, mostrar)
% ARO Y RESORTE. Una escena animada; seis escenarios; sin graficas auxiliares.
% Uso: simulacion_aro_resorte       o simulacion_aro_resorte(3)
% Datos sin abrir ventana: s=simulacion_aro_resorte(3,false);
% s.q contiene [l,theta,phi], en m y rad. MATLAB R2016b+, sin toolboxes.
% x=R*cos(theta)+l*sin(phi); y=R*sin(theta)-l*cos(phi).
% theta: enganche desde OX; phi: resorte desde la vertical descendente.
% mu=0: enganche ideal sin inercia. mu>0: variante con masa en el enganche.
if nargin<1, caso=1; end
if nargin<2, mostrar=true; end
validateattributes(caso,{'numeric'},{'scalar','integer','>=',1,'<=',6});
[p,ini,nombre]=escenario(caso); salida=resolver(p,ini);
if ~mostrar, return; end
azul=[.09 .20 .30]; verde=[.03 .50 .55]; coral=[.90 .42 .33]; oro=[.76 .57 .24];
fondo=[.96 .98 .99]; gris=[.36 .44 .51];
f=figure('Name','Resorte sobre un aro vertical','NumberTitle','off', ...
    'Color',fondo,'Position',[120 60 960 800],'MenuBar','none','ToolBar','none');
uicontrol(f,'Style','text','Units','normalized','Position',[.05 .935 .90 .04], ...
    'String','RESORTE SOBRE UN ARO VERTICAL','FontSize',17,'FontWeight','bold', ...
    'HorizontalAlignment','left','ForegroundColor',azul,'BackgroundColor',fondo);
menu=uicontrol(f,'Style','popupmenu','Units','normalized','Position',[.05 .87 .53 .045], ...
    'String',{'4.1  Oscilacion acoplada','4.2  Modo radial puro', ...
    '4.3  Resonancia interna 2:1','4.4  Limite de resorte rigido', ...
    '4.5  Sin gravedad','4.6  Enganche con inercia'},'Value',caso, ...
    'FontSize',11,'BackgroundColor','white','Callback',@cambiar);
boton=uicontrol(f,'Style','pushbutton','Units','normalized','Position',[.61 .87 .15 .045], ...
    'String','Pausa','FontSize',11,'Callback',@pausar);
uicontrol(f,'Style','pushbutton','Units','normalized','Position',[.78 .87 .17 .045], ...
    'String','Reiniciar','FontSize',11,'Callback',@reiniciar);
ax=axes('Parent',f,'Position',[.05 .20 .90 .63]); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
a=linspace(0,2*pi,250);
aro=plot(ax,p.R*cos(a),p.R*sin(a),'Color',azul,'LineWidth',2);
radA=plot(ax,nan,nan,'--','Color',verde,'LineWidth',.7);
radM=plot(ax,nan,nan,':','Color',coral,'LineWidth',.7);
traza=plot(ax,nan,nan,'Color',[.72 .86 .87],'LineWidth',1.1);
muelle=plot(ax,nan,nan,'Color',oro,'LineWidth',2.2);
enganche=plot(ax,nan,nan,'o','MarkerFaceColor',verde,'MarkerEdgeColor','w','MarkerSize',9);
masa=plot(ax,nan,nan,'o','MarkerFaceColor',coral,'MarkerEdgeColor','w','MarkerSize',14);
plot(ax,0,0,'.','Color',azul,'MarkerSize',10);
reloj=text(ax,.02,.98,'','Units','normalized','VerticalAlignment','top','Color',gris,'FontSize',11);
lectura=uicontrol(f,'Style','text','Units','normalized','Position',[.05 .15 .90 .035], ...
    'FontSize',12,'ForegroundColor',azul,'BackgroundColor',fondo);
claves={'m','k','R','l0'}; etiquetas={'m (kg)','k (N/m)','R (m)','l_0 (m)'};
ediciones=gobjects(1,4);
for j=1:4
    x=.05+(j-1)*.19;
    uicontrol(f,'Style','text','Units','normalized','Position',[x .097 .17 .025], ...
        'String',etiquetas{j},'FontSize',10,'BackgroundColor',fondo,'ForegroundColor',gris);
    ediciones(j)=uicontrol(f,'Style','edit','Units','normalized','Position',[x .052 .17 .04], ...
        'String',num2str(p.(claves{j})),'FontSize',11,'BackgroundColor','white');
end
uicontrol(f,'Style','pushbutton','Units','normalized','Position',[.83 .052 .12 .04], ...
    'String','Aplicar','FontSize',11,'Callback',@aplicar);
nota=uicontrol(f,'Style','text','Units','normalized','Position',[.05 .005 .90 .03], ...
    'String','','ForegroundColor',gris,'BackgroundColor',fondo,'FontSize',9);
activo=true; pendiente=false; tiempo=0; limite=0; ultimo=tic; nombreAnterior=nombre; casoActivo=caso;
preparar();
while isgraphics(f)
    if pendiente
        try
            salida=resolver(p,ini); preparar(); nombreAnterior=nombre; casoActivo=get(menu,'Value'); tiempo=0; activo=true;
            set(boton,'String','Pausa');
        catch err
            activo=false; p=salida.p; ini=salida.ini; nombre=nombreAnterior; set(menu,'Value',casoActivo);
            for n=1:4, set(ediciones(n),'String',num2str(p.(claves{n}))); end
            set(boton,'String','Continuar'); set(nota,'String',err.message);
        end
        pendiente=false; ultimo=tic;
    end
    dt=toc(ultimo); ultimo=tic;
    if activo, tiempo=min(tiempo+dt,salida.t(end)); end
    indice=min(numel(salida.t),1+round(tiempo/.025));
    l=salida.q(indice,1); th=salida.q(indice,2); ph=salida.q(indice,3);
    A=p.R*[cos(th);sin(th)]; B=A+l*[sin(ph);-cos(ph)];
    d=B-A; l=norm(d); normal=[-d(2);d(1)]/l;
    u=linspace(0,1,160); onda=min(.03,.10*l)*sin(20*pi*u).*sin(pi*u);
    curva=A+d*u+normal*onda;
    set(aro,'XData',p.R*cos(a),'YData',p.R*sin(a));
    set(radA,'XData',[0 A(1)],'YData',[0 A(2)]);
    set(radM,'XData',[A(1) A(1)],'YData',[A(2) A(2)-.25]);
    set(muelle,'XData',curva(1,:),'YData',curva(2,:));
    set(enganche,'XData',A(1),'YData',A(2)); set(masa,'XData',B(1),'YData',B(2));
    ii=max(1,indice-120):indice;
    set(traza,'XData',salida.xy(ii,1),'YData',salida.xy(ii,2));
    set(reloj,'String',sprintf('%s\nt = %.2f s',nombre,salida.t(indice)));
    set(lectura,'String',sprintf('l = %.3f m       theta = %.3f rad       phi = %.3f rad',l,th,ph));
    if tiempo>=salida.t(end), activo=false; set(boton,'String','Continuar'); end
    drawnow; pause(.012);
end

    function preparar()
        limite=1.13*max([salida.r;p.R*1.2]);
        axis(ax,[-limite limite -limite limite]);
        set(nota,'String',sprintf('Enganche verde | masa coral | resorte dorado    g = %.2f m/s^2    mu = %.3f kg',p.g,p.mu));
    end
    function cambiar(~,~)
        [p,ini,nombre]=escenario(get(menu,'Value'));
        for n=1:4, set(ediciones(n),'String',num2str(p.(claves{n}))); end
        pendiente=true;
    end
    function aplicar(~,~)
        nuevos=zeros(1,4);
        for n=1:4, nuevos(n)=str2double(get(ediciones(n),'String')); end
        if any(~isfinite(nuevos)) || any(nuevos<=0)
            set(nota,'String','Introduce valores positivos para m, k, R y l_0.'); return;
        end
        for n=1:4, p.(claves{n})=nuevos(n); end
        pendiente=true;
    end
    function pausar(~,~)
        if tiempo>=salida.t(end), tiempo=0; end
        activo=~activo; ultimo=tic;
        if activo, set(boton,'String','Pausa'); else, set(boton,'String','Continuar'); end
    end
    function reiniciar(~,~)
        tiempo=0; activo=true; ultimo=tic; set(boton,'String','Pausa');
    end
end

function [p,ini,nombre]=escenario(n)
p=struct('m',.2,'k',20,'R',.5,'l0',.4,'g',9.81,'mu',0);
% ini=[l(0)-l_eq, phi, theta, dl, dphi, dtheta, duracion].
% En los casos ideales, theta=phi-pi/2 es resultado del balance del enganche.
lista={'Oscilacion acoplada','Modo radial puro','Resonancia interna 2:1', ...
    'Limite de resorte rigido','Sin gravedad','Enganche con inercia'};
nombre=lista{n};
switch n
    case 1, ini=[.06 .45 .45-pi/2 0 0 0 18];
    case 2, ini=[.08 0 -pi/2 0 0 0 12];
    case 3, p.k=6.54; ini=[.16 .03 .03-pi/2 0 0 0 25];
    case 4, p.k=2000; ini=[0 .45 .45-pi/2 0 0 0 12];
    case 5, p.g=0; ini=[.10 .20 .20-pi/2 .10 .70 .70 18];
    case 6
        p.mu=.04;
        % Misma configuracion fisica anterior, expresada en los angulos del folio.
        lInicial=.6362035853594032;
        ini=[lInicial-(p.l0+p.m*p.g/p.k),.9488790589835482, ...
            -1.4207963267948966,0,0,0,18];
end
end

function s=resolver(p,ini)
lInicial=p.l0+p.m*p.g/p.k+ini(1); t=(0:.025:ini(7))';
op=odeset('RelTol',1e-9,'AbsTol',1e-11,'MaxStep',.025,'Events',@(t,z)dominio(t,z,p));
if p.mu==0
    % Reduccion de las tres ecuaciones de Euler-Lagrange: phi=theta+pi/2.
    [t,z,te]=ode45(@(t,z)ideal(t,z,p),t,[lInicial;ini(2);ini(4);ini(5)],op);
    l=z(:,1); ph=z(:,2); th=ph-pi/2;
else
    % Tres coordenadas inerciales: [l,theta,phi,dl,dtheta,dphi].
    [t,z,te]=ode45(@(t,z)conInercia(t,z,p),t, ...
        [lInicial;ini(3);ini(2);ini(4);ini(6);ini(5)],op);
    l=z(:,1); th=z(:,2); ph=z(:,3);
end
if ~isempty(te), error('Se alcanza el limite exterior del modelo; modifica los datos.'); end
xy=[p.R*cos(th)+l.*sin(ph),p.R*sin(th)-l.*cos(ph)];
s=struct('t',t,'q',[l th ph],'r',hypot(xy(:,1),xy(:,2)), ...
    'xy',xy,'p',p,'ini',ini);
end

function dz=ideal(~,z,p)
l=z(1); ph=z(2); v=z(3); w=z(4);
dz=[v;w;(p.R+l)*w*w+p.g*cos(ph)-p.k/p.m*(l-p.l0); ...
    -(2*v*w+p.g*sin(ph))/(p.R+l)];
end

function dz=conInercia(~,z,p)
l=z(1); th=z(2); ph=z(3); v=z(4); w=z(5); h=z(6);
c=cos(th-ph); s=sin(th-ph); m=p.m; R=p.R; g=p.g;
% Las tres ecuaciones del documento de calculos, ordenadas como M*q''=b.
% La masa mu del enganche anade mu*R^2 a M(2,2).
M=m*[1 -R*c 0; -R*c R^2 -R*l*s; 0 -R*l*s l^2];
M(2,2)=M(2,2)+p.mu*R^2;
b=[m*(l*h*h-R*s*w*w+g*cos(ph))-p.k*(l-p.l0); ...
    m*(2*R*s*v*h-R*l*c*h*h)-(m+p.mu)*g*R*cos(th); ...
    m*(-2*l*v*h+R*l*c*w*w-g*l*sin(ph))];
dz=[z(4:6);M\b];
end

function [valor,terminar,direccion]=dominio(~,z,p)
l=z(1);
if p.mu==0
    distancia=p.R+l;
else
    th=z(2); ph=z(3);
    distancia=hypot(p.R*cos(th)+l*sin(ph),p.R*sin(th)-l*cos(ph));
end
valor=min(l-1e-5,distancia-p.R); terminar=1; direccion=-1;
end
