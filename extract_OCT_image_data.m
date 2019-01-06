% CREATE IMAGE DATA STRUCTURE FROM OCT FILES

function image = extract_OCT_image_data(file_dir)

image.directory = file_dir;
files = dir([image.directory,'*.oct']);
image.data = cell(length(files),1);

% Extract data from each file
for ii = 1:length(files)
    file = [image.directory,files(ii).name];
    unzip(file);
    % Get header data and create image preview for first image (zero Pa)
    % Extract only intensity data for remaining images
    if ii == 1
        image = extract_header_data(image);
        image.data{ii} = extract_intensity_data(image);
        image.preview = imresize(image.data{ii},[image.pix_scaled.z, image.pix_scaled.x]);
    else
        image.data{ii} = extract_intensity_data(image);
    end
    fprintf('extracted image %d\n',ii)
end
image = pressure_sort(image);
save([image.directory,'image_data.mat'],'image');
fprintf('Data saved in image directory as: image_data.mat\n')


    function image = extract_header_data(image)
        % Find size and range of images from header file
        fid = fopen('Header.xml', 'r'); % open file
        text = char(fread(fid)');  % read text to variable
        fclose(fid); delete('Header.xml'); % close file and delete
        % Match line containing intensity data, then match size and range definitions
        line = regexp(text, '[^\n]+data\\Intensity.data</DataFile>', 'match');
        dimensions = regexp(line{1}, 'SizeZ="(\d+)".*SizeX="(\d+)".*RangeZ="(.*)".*RangeX="(.*)" .*', 'tokens');
        image.pix.z = eval(dimensions{1}{1});
        image.pix.x = eval(dimensions{1}{2});
        image.range_um.z = eval(dimensions{1}{3})*1000; % Range is given in mm
        image.range_um.x = eval(dimensions{1}{4})*1000;
        image.pix2um.x = image.range_um.x/image.pix.x; % Calc size in um of each pixel
        image.pix2um.z = image.range_um.z/image.pix.z;
        image.pix_scaled.x = round(image.range_um.x*image.pix.z/image.range_um.z);
        image.pix_scaled.z = image.pix.z;
    end

    function intensity_data = extract_intensity_data(image)
        fid = fopen('data/Intensity.data', 'r'); %open intensity file
        intensity_data = fread(fid, image.pix.x* image.pix.z, 'float32'); %read data
        intensity_data = reshape(intensity_data, [image.pix.z, image.pix.x]); % reshape
        max_I = max(intensity_data(:)); min_I = min(intensity_data(:));
        intensity_data = (intensity_data - min_I)/ (max_I-min_I); % normalize
        fclose(fid); rmdir('data', 's'); % close and delete files
    end

    function p_vals = pressure_input
        % Input pressure range parameters
        prompt = {'Pressure Min:', 'Pressure Max:','Pressure Inc:'};
        answer = inputdlg(prompt,'Pressure Range',1,{'-20','20','4'});
        p_min = eval(answer{1}); p_max = eval(answer{2}); p_inc = eval(answer{3});
        p_vals=[p_inc:p_inc:p_max, p_min:p_inc:0]; % Sort based on this order
    end

    function image = pressure_sort(image)
        pressure = pressure_input;
        while length(pressure) ~= length(image.data)-1
            fprintf("ERROR: Input parameters don't match number of images\n")
            pressure = pressure_input;
        end
        [image.pressure, idx] = sort(pressure,'ascend');
        image.data(2:end) = image.data(idx+1); % order is [0, pmin:pinc:pmax]
    end
end