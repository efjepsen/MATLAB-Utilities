function [varargout] = projectionView(I, varargin)
%% Unit Test
if nargin == 0
   unittest;
   return
end

%% Parse Inputs
%%% Check Inputs
assert(any(ndims(I) == [3, 4]), ['I must be a grayscale (3D) or color (4D)', ...
   'volumetric image.']);
if ndims(I) == 4
   assert(size(I, 4) == 3, 'I must have exactly 3 color channels');
   isColorIm = true;
else
   isColorIm = false;
end
p = inputParser;
p.addParameter('FillValue', 1, @(x) isnumeric(x) && isreal(x) ...
   && isscalar(x));
p.addParameter('Margin', 10, @(x)  isnumeric(x) && isreal(x) && x >= 0);
p.addParameter('ProjectionFun', @(varargin) utils.maxProject(varargin{:}), ...
   @(x) isa(x, 'function_handle'));
p.addParameter('ColorWeight', []);
p.parse(varargin{:});

%%% Assign Inputs
margin = p.Results.Margin;
fillValue = p.Results.FillValue;
pFun = p.Results.ProjectionFun;
colorwt = p.Results.ColorWeight;

if ~isempty(colorwt)
   pFun = @(I, dim) pFun(I, dim, 'ColorWeight', colorwt);
end

%% Create Projection View
sz = arrayfun(@(dim) size(I, dim), 1:4);
totalSize = [sz(1:2) + sz(3) + margin, sz(4)];
alphaData = zeros(totalSize(1:2)); 
Iout = ones(totalSize) * fillValue;

bounds = cell(1, 3);
bounds{1} = [1, 1; sz(1), sz(2)];
start = [sz(1) + margin + 1, 1];
bounds{2} = [start; start + [sz(3), sz(2)] - 1];
start = [1, sz(2) + margin + 1];
bounds{3} = [start; start + [sz(1), sz(3)] - 1];

projOrder = [3 1 2]; % XY, XZ, YZ
sels = cell(1, 3);
for i = 1:length(bounds)
   b = bounds{i};
   sel = {b(1, 1):b(2, 1), b(1, 2):b(2, 2), 1:totalSize(3)}; 
   view = pFun(I, projOrder(i));
   if i == 2
      view = permute(view, [2, 1, 3]);
   end
   alphaData(sel{:}) = 1;
   sels{i} = sel;
   Iout(sel{:}) = view;
end

% convert to true bounds in world coordinates
bounds = cellfun(@(b) [b(1, :) - 0.5; b(2, :) + 0.5], ...
   bounds, 'UniformOutput', false);

switch nargout
   case 1
      varargout = {Iout};
   otherwise
      varargout = {Iout, bounds, sels, alphaData};
end
end

function unittest
mri = load('mri');
V = im2double(squeeze(mri.D));
V = V(1:floor(end / 2), :, :);
[I, bounds, sel, ad] = utils.projectionView(V);
figure; clf; hold on;
imagesc(I, 'AlphaData', ad);
for i = 1:3
   plot(bounds{i}(:, 2), bounds{i}(:, 1), ...
      'r+-', 'LineWidth', 1, 'MarkerSize', 10);
end
ax = gca;
ax.YDir = 'reverse';
colorbar(ax);

figure; clf; hold on;
h = imagesc(I, 'AlphaData', ad);
for i = 1:3
   plot(flip(bounds{i}(:, 2)), bounds{i}(:, 1), ...
      'r+-', 'LineWidth', 1, 'MarkerSize', 10);
end
ax = gca;
ax.YDir = 'reverse';
h.CData(sel{1}{:}) = 0;
h.CData(sel{2}{:}) = 1;
h.CData(sel{3}{:}) = 1;
colorbar(ax);
end
