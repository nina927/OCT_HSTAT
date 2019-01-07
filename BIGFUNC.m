%{
Variable Structure

image.directory
image.pix [.x .z]
image.pix_scaled [.x, .z]
image.range_um [.x, .z]
image.pix2um [.x, .z]
image.preview
image.data {images} (z-data, x-data)
image.pressure

results.pts [.x,.z]
results.pts_scaled [.x,.z]
results.ref_size [.frac,.x,.z] fraction of image & size in pixels before interp
results.temp_size [.frac,.x,.z] fraction of ref img & size before interp
results.interp_step [.x,.z]
results.pix [.x,.z]
results.pix_scaled [.x,.z]
results.pix2um [.x,.z]
results.offset [.x,.z] (image,point)

%}

%% MAIN FUNCTION
function [image,results] = BIGFUNC(file_dir)
  image = get_image_data(file_dir);   % create/load image data structure
  results = choose_pts(image);        % select points to analyze
  [image,results] = image_corr(image,results);  % compute results
  save_results(image,results);
end

%% CREATE OR LOAD IMAGE DATA STRUCTURE
function image = get_image_data(file_dir)
  if file_dir(end) ~= filesep         % verify path syntax       
      file_dir(end+1) = filesep;
  end
  data_file = [file_dir,'image_data.mat']; 
  if exist(data_file,'file')          % if file exists, load it
    load(data_file);
  else                                % if not, create it
    image = extract_OCT_image_data(file_dir);
  end
end


%% Choose Points (either from a previous run (saved data file) or manually select them)

function results = choose_pts(image)
quest = 'Use points from previous result file?';
answer = questdlg(quest,'Point Selection','Yes','No','No');
switch answer
    case 'Yes'
        results = extract_previous_pts;
    case 'No'
        results = manually_select_pts(image);
end
end

function results = extract_previous_pts
uiopen
old_results = results;
clear('results')
results.pts = old_results.pts;
results.pts_scaled = old_results.pts_scaled;
end

function results = manually_select_pts(image)
figure, imshow(image.preview);
[results.pts_scaled.x, results.pts_scaled.z] = getpts();
results.pts.x = round(results.pts_scaled.x*image.pix.x/image.pix_scaled.x);
results.pts.z = round(results.pts_scaled.z*image.pix.z/image.pix_scaled.z);
hold on; plot(results.pts_scaled.x,results.pts_scaled.z,'o');
end

%% Define Parameters
function [image,results] = define_correlation_parameters(image,results)
  addpath('~/Documents/MATLAB/ImageAnalysis/normxcorr2_general/')
  results.ref_size.frac = 0.03; %fraction of image that will be cropped for ref
  results.temp_size.frac = 0.5; %fraction of ref image size that will be size of temp
  results.ref_size.x = round(image.pix.x*results.ref_size.frac/2)*2;
  results.ref_size.z = round(image.pix.z*results.ref_size.frac/2)*2;
  results.temp_size.x = round(results.ref_size.x*results.temp_size.frac/2)*2;
  results.temp_size.z = round(results.ref_size.z*results.temp_size.frac/2)*2;
  
  results.interp_step.x = 1; %fraction of pixel to interpolate
  results.interp_step.z = 1;
  results.pix.x = length(1:results.interp_step.x:image.pix.x);
  results.pix.z = length(1:results.interp_step.z:image.pix.z);
  results.pix2um.x = image.range_um.x/results.pix.x;
  results.pix2um.z = image.range_um.z/results.pix.z;
  results.pix_scaled.x = round(image.range_um.x/results.pix2um.z);
  results.pix_scaled.z = results.pix.z;

  pts = length(results.pts.x);
  temps = length(image.data)-1;
  results.offset.x = zeros(temps,pts);
  results.offset.z = zeros(temps,pts);
  results.cc = zeros(temps,pts); % NEW
  
end

%% 2D Interpolation
function new_image = interpolate_image(original_image,new_x_res,new_z_res)
  [size_z, size_x] = size(original_image);
  [z,x] = ndgrid(1:size_z,1:size_x);
  [zq,xq] = ndgrid(1:new_z_res:size_z , 1:new_x_res:size_x);
  new_image = griddata(z,x,original_image,zq,xq);
end

%% Image Correlation
function [image,results] = image_corr(image,results)
  [image,results] = define_correlation_parameters(image,results);

  for point = 1:length(results.pts.x)
    xx = results.pts.x(point);
    zz = results.pts.z(point);
    ref_crop = [xx-results.ref_size.x/2, zz-results.ref_size.z/2, results.ref_size.x, results.ref_size.z];
    temp_crop = [xx-results.temp_size.x/2, zz-results.temp_size.z/2, results.temp_size.x, results.temp_size.z];
    ref_img = imcrop(image.data{1},ref_crop);
    ref_img = interpolate_image(ref_img,results.interp_step.x,results.interp_step.z);
    fprintf('\npoint %d\n',point)
    
    for temp = 1:(length(image.data)-1)
      temp_img = imcrop(image.data{temp+1},temp_crop);
      temp_img = interpolate_image(temp_img,results.interp_step.x,results.interp_step.z);
      c = normxcorr2_general(temp_img,ref_img,numel(temp_img));
      results.cc(temp,point) = max(c(:));
      [zpeak, xpeak] = find(c==max(c(:)));   % IMPORTANT THAT ORDER IS [Zp,Xp]
      results.offset.x(temp,point) = (xpeak-size(temp_img,2))*results.pix2um.x; %double check this
      results.offset.z(temp,point) = (zpeak-size(temp_img,1))*results.pix2um.z; %double check this
      fprintf('image %2d\tcc %.2f\n',temp,max(c(:)))
    end   
  end
  
end


%% Save data to mat file
function save_results(image,results)
%prompt user to input save name and any comments
ans = inputdlg({'Filename','Comments'},'Save As',1,{'trial',''});
save_name = [ans{1},'.mat']; comments = ans{2};
% save image struct, results struct, and comments to mat file in image directory
save([image.directory,save_name],'image','results','comments'); %save data
fprintf('Data saved in image directory as: %s\n', save_name)
end


