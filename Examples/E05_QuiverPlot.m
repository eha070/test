% ------------------------------------------------------------------------- 
%                               E05_QuiverPlot 
% 
% Loads qmat and shows a quiver plot of the flow
% 
% 
% 
%                                          (c)Constantin Heck, 23-Feb-2015 
%                                                http://mic.uni-luebeck.de
% ------------------------------------------------------------------------- 




clear;
clc;
close all;

plotVectorField2D   = 1;
plotStreamlines3D   = 1;
vectorFieldAndSinks = 1;


%% setup data

%prepare pathnames
prm          = settings;
basenameFlow = perfusion1c.struct2nameIndicator(prm,'phiopt','Kopt','dim');
foldername   = './results/';
pathloadFlow = [foldername,'synt-createflowTPFA-' basenameFlow '.mat'];


%setup data
msg = ['Loading ' pathloadFlow];
disp(msg);
load(pathloadFlow);

%setup domain
omega = [0,1,0,1];
m     = size(pmat);


%% convert flow

%get flow
qcc = perfusion1c.convertFlowStagToCC(qmat);
qy  = qcc{1};
qx  = qcc{2};



%% show 2D-streamlines

if plotVectorField2D
    %get meshgrid to plot qcc, the cell-centered flow
    ygv   = linspace(omega(2),omega(1),m(1)); %from (0 to 1)
    xgv   = linspace(omega(3),omega(4),m(2)); %this goes from (1 to 0) (matlab, duh)
    [x,y] = meshgrid(xgv,ygv);



    
    %create a a semi-circle with radius epsilon from -(n-1)/n*pi + pi/4:
    %(n-1)/n*pi + pi/4 where to start the k streamlines
    k                 = 100; %number of streamlines
    n                 = 4;
    epsilon           = .03;    
    streamStart       = -(n-1)/n*pi - pi/4;
    streamStop        = (n-1)/n*pi - pi/4;
    [streamx,streamy] = pol2cart(linspace(streamStart,streamStop,k),epsilon); 
    
	%this will be the new center of the semi-circle
    sourcex = epsilon + streamx;
    sourcey = 1-epsilon + streamx;
    
    %shift the semi-circle to the source
    streamx = streamx + sourcex;
    streamy = streamy + sourcey;



    %create quiver plot. Notice that flow in y-direction is reversed since the
    %grid is reversed
    figure(1);clf;
    quiver(x(:),y(:),qx(:),-qy(:),10)
    streamline(x,y,qx,-qy,streamx,streamy)
    xlabel('x');
    ylabel('y');
    set(gca,'FontSize',15);

end

%% show 3D-streamlines


if plotStreamlines3D
    %number of timepoints to simulate
    k = 100;

    %start-coordinates for the streamlines
    xstart = .1;
    ystart = .9;
    tstart = 0;
    numt   = 1;

    tend   = 10;



    %setup starting points for streamlines
    startx = xstart*ones(numt,1);
    starty = ystart*ones(numt,1);
    startz = linspace(tstart,tend,numt)';

    %setup stepsizes to downsample the data for visualization
    stepxy = 5;
    stepz = 20;

    %get 3D-flow
    qx3D = repmat(qx,[1,1,k]);
    qy3D = repmat(qy,[1,1,k]);
    qz3D = ones([m,k]);

    %get meshgrid to plot qcc, the cell-centered flow
    ygv   = linspace(omega(2),omega(1),m(1)); %from (0 to 1)
    xgv   = linspace(omega(3),omega(4),m(2)); %this goes from (1 to 0) (matlab, duh)
    zgv   = linspace(0,60,k);
    [x,y,z] = meshgrid(xgv,ygv,zgv);


    %downsample the vector-fields for display
    idxX = (1:stepxy:m(2));
    idxY = (1:stepxy:m(1));
    idxZ = (1:stepz:k);

    qxLow = qx3D(idxY,idxX,idxZ);
    qyLow = qx3D(idxY,idxX,idxZ);
    qzLow = qx3D(idxY,idxX,idxZ);
    xLow  = x(idxY,idxX,idxZ);
    yLow  = y(idxY,idxX,idxZ);
    zLow  = z(idxY,idxX,idxZ);



    %create quiver plot with streamlines. Notice that flow in y-direction is reversed since the
    %grid is reversed
    figure(2);clf;
    hq = quiver3(xLow,yLow,zLow,qxLow,-qyLow,qzLow,1.5);
    hs = streamline(x,y,z,qx3D,-qy3D,qz3D,startx,starty,startz);
    xlabel('x');
    ylabel('y');
    zlabel('time');
    set(hs,'LineWidth',2);
    set(gca,'FontSize',15);
end
    
%% show surce and sink and vectorField

if vectorFieldAndSinks
    
    
	%get meshgrid to plot qcc, the cell-centered flow
    ygv   = linspace(omega(2),omega(1),m(1)); %from (0 to 1)
    xgv   = linspace(omega(3),omega(4),m(2)); %this goes from (1 to 0) (matlab, duh)
    [x,y] = meshgrid(xgv,ygv);
    
    %setup center (x,y) and radius for source and sinks
    r       = .05;
    sourcex = r;
    sourcey = 1-r;
    
    sinkx   = 1-r;
    sinky   = r;


    %setup points where to follow the streamlines

    
    
    %setup the source and the sink
    [dx,dy] = pol2cart(linspace(0,2*pi,100),r);
    xSource = sourcex + dx;
    ySource = sourcey + dy;
    xSink = sinkx + dx;
    ySink = sinky + dy;    

    %setup the coordinates to start k different streamlines
    k       = 10;    
    
    %create a a semi-circle with radius epsilon from -(n-1)/n*pi - pi/4 to
    %(n-1)/n*pi - pi/4
    n                 = 4;
    epsilon           = .03;    
    streamStart       = -(n-1)/n*pi - pi/4;
    streamStop        = (n-1)/n*pi - pi/4;
    [streamx,streamy] = pol2cart(linspace(streamStart,streamStop,k),epsilon); 
    
    %shift the semi-circle
    streamx = streamx + sourcex;
    streamy = streamy + sourcey;
    
    %setup the actual disc B_\eps where to start the streamlines
    [dx,dy] = pol2cart(linspace(0,2*pi,100),epsilon);
    xStart = sourcex + dx;
    yStart = sourcey + dy;
    

    %actual plotting
    figure(3);clf;
    hold on;
    
    %plot source/sink 
    fill(xSource,ySource,'r');
    fill(xSink,ySink,'r');    
        
    %plot vector-field
    quiver(x(:),y(:),qx(:),-qy(:),10)
    
    %plot streamline
    streamline(x,y,qx,-qy,streamx,streamy)
    
    %plot B_epsilon ball where to start the streamlines
    fill(xStart,yStart,'k');        

    hold off;
    
    xlabel('x');
    ylabel('y');
    
    axis image;
    set(gca,'FontSize',15);
    
    

end