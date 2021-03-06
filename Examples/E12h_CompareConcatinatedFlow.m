% ------------------------------------------------------------------------- 
%                    E12h_CompareConcatinatedFlow
% 
% For a voxel in the top-row, a residue function 
%
%   I  := I1\conv...\conv Il is set up for
%   Ii := Fi*exp(-Fi*t) and Fi a local flow constant.
%
% Then Ci is setup by convolving I with aif and compared to Cmat(i).
% Additionally I is compared to IRec, the recovered residue function from 
% Cmat.
%
%                                      (c)Constantin Sandmann, 27-Feb-2016 
%                                                http://mic.uni-luebeck.de
% ------------------------------------------------------------------------- 

clear;
clc;
close all;

%setup parameters
l             = 20;
OI            = 1e-2;

%% setup main variables

load smallDataSet;

%timleine
timelineH = linspace(0,90,5e6);
aif       = perfusion1c.getGammaAIF(timelineH'/60)*1e-6;

%setup other parameters
kH  = numel(timelineH);
dtH = timelineH(2)-timelineH(1);
hd  = prod(prm.h);   %voxel volume in mm^3


%% setup residue functinons Ii

I     = zeros(kH,l);
FTrue = zeros(l,1);
phi   = zeros(l,1);
G     = zeros(l,1);
for i = 1:l

    %setup voxel flow
    q1       = qmat{1}(1,i);
    q2       = qmat{2}(1,i);
    F        = (q1 + q2); %flow in mm^3/s
    FTrue(i) = (F + abs(Fmat(1,i)))/hd;

    %setup voxel porosity
    phi(i) = phimat(1,i);
    
    %setup Ii
    G(i)   = FTrue(i)/phi(i);
    I(:,i) = G(i)*exp(-G(i)*timelineH(:));
    
end

%% get analytic IR

%analytic solution for n points
IAna = zeros(numel(timelineH),1);
for i = 1:l
    idx = (1:l); idx(i)=[];
    nom   = G;
    denom = [G(idx)-G(i);1];
    fi    = prod(nom./denom);
    IAna  = IAna + fi*exp(-G(i)*timelineH(:));
end

fprintf('Setting up IAna*aif...'); tic;
cAna = conv(IAna,aif)*dtH;
CAna = phi(l)*cAna(1:kH);
fprintf('...done, %1.4fs\n',toc);



%% get data curve and recover flow by deconvolution

%setup dt
CData = squeeze(Cmat(1,l,1,:));
dt    = timeline(2)-timeline(1);

%prepare deconvolution
A       = perfusion1c.getLinearConvolutionMatrix(aifval,dt);
tic; fprintf('Starting SVD...');
[U,S,V] = svd(A);
fprintf('finished: %1.2fs\n',toc);

%do deconvolution
[FRec,IRec,CRec] = perfusion1c.linearDeconvolution(CData,timelineL,OI,U,S,V);

%% show results

idx  = (timeline  <4);
idxH = (timelineH <4);

figure(1);clf;
subplot(1,2,1);
plot(timelineL(idx),IRec(idx),timelineH(idxH),phi(l)*IAna(idxH));
legend('IRec','IAna');    

subplot(1,2,2);
plot(timelineL,CData,timelineH,CAna);
legend('CData','CAna');    

return;

%% nice plots for paper

figure(1);clf;
plot(timelineH(idxH),phi(l)*IAna(idxH),timelineL(idx),IRec(idx),'linewidth',3);
set(gca,'fontsize',20);
legend('Analytic','Deconvolution');
xlabel('time [s]');
ylabel('Impuls Response [mmol/s/mm^3]');
export_fig IDecVsIAna.pdf -transparent