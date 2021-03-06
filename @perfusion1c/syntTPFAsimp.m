function [pmat,flowmat] = syntTPFAsimp(Kmat,Qmat,prm)


% Here we make the code from Aarnes, Gimse and Lie for incompressible
% single phase flow: "An introduction to the Numerivs of Flow in Porous
% Media using Matlab"


% dimension of problem
dim = prm.dim;
ndim = numel(dim);
nvox = prod(dim);
h = prm.h;
voxelvol = prod(h);

msg = ['This is ' mfilename ' using settings'];
disp(msg);
printstructscreen(prm);

% make source/sink into a vector
Q = Qmat(:);


% K = K/mu
Kmat = Kmat/prm.mu;


% initialization of the transmissibilities
trmat = cell(ndim,1);
for i = 1 : ndim
    v = dim;
    v(i) = v(i) + 1;
    trmat{i} = zeros(v);
end;

% the term |gamma|/delta x_j
tr = zeros(ndim,1);
for i = 1 : ndim
    v = h;
    v(i) = [];
    tr(i) = prod(v)/h(i);
end;
trmat{1}(2:dim(1),:,:) = tr(1).*(Kmat(1:dim(1)-1,:,:,1) + Kmat(2:dim(1),:,:,1))/2;
trmat{2}(:,2:dim(2),:) = tr(2).*(Kmat(:,1:dim(2)-1,:,2) + Kmat(:,2:dim(2),:,2))/2;
trmat{3}(:,:,2:dim(3)) = tr(3).*(Kmat(:,:,1:dim(3)-1,3) + Kmat(:,:,2:dim(3),3))/2;



% Assemble TPFA discretization matrix
v = cell(6,1);
% x, above
v{1} = trmat{1}(1:dim(1),:,:);
% x, below
v{2} = trmat{1}(2:dim(1)+1,:,:);
% y, left
v{3} = trmat{2}(:,1:dim(2),:);
% y, right
v{4} = trmat{2}(:,2:dim(2)+1,:);
% z, above
v{5} = trmat{3}(:,:,1:dim(3));
% z, below
v{6} = trmat{3}(:,:,2:dim(3)+1);
sumv = zeros(nvox,1);
for i = 1 : numel(v)
    v{i} = v{i}(:);
    sumv = sumv + v{i};
end;

% value and position of bands in the matrix
vals = [-v{6}, -v{4}, -v{2}, sumv, -v{1}, -v{3}, -v{5}];
index = [-dim(1)*dim(2),-dim(1),-1,0,1,dim(1),dim(1)*dim(2)];

% make matrix
A = spdiags(vals,index,nvox,nvox);
A(1,1) = A(1,1) + sum(Kmat(:,1,1,1));

% solve linear system for the pressure p
%u = minres(A,Q);

b = voxelvol*Q;

p = A\b;
pmat = reshape(p,dim(1),dim(2),dim(3));

% flow is gradient of pressure
flowmat{1} = zeros(dim(1)+1,dim(2),dim(3));
flowmat{1}(2:end-1,:,:) = -(pmat(2:end,:,:) - pmat(1:end-1,:,:)).*trmat{1}(2:end-1,:,:);
flowmat{2} = zeros(dim(1),dim(2)+1,dim(3));
flowmat{2}(:,2:end-1,:) = -(pmat(:,2:end,:) - pmat(:,1:end-1,:)).*trmat{2}(:,2:end-1,:);
flowmat{3} = zeros(dim(1),dim(2),dim(3)+1);
flowmat{3}(:,:,2:end-1) = -(pmat(:,:,2:end) - pmat(:,:,1:end-1)).*trmat{3}(:,:,2:end-1);

