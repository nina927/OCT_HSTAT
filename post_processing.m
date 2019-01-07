function h = post_processing(image,results)
h = struct;
results = correlation_check(results);
h = plot_pts(image,results,h);
h = plot_offset(image,results,h);
h = plot_disp(image,results,h);

end

%% correlation failures
function results = correlation_check(results)
fail_cnt = 0;
fail_pts = 0;
for pt = 1:length(results.pts.x)
    if mean(results.cc(:,pt)) < 0.5
       fprintf('%d ',N)
       fail_cnt = fail_cnt + 1;
       fail_pts(fail_cnt) = pt;
    end
end
       
results.pts.x(fail_pts) = [];
results.pts.z(fail_pts) = [];
results.pts_scaled.x(fail_pts) = [];
results.pts_scaled.z(fail_pts) = [];
results.cc(:,fail_pts) = [];
results.offset.x(:,fail_pts) = [];
results.offset.z(:,fail_pts) = [];

end

%% plot scaled image and points
function h = plot_pts(image,results,h)
figure, imshow(image.preview); hold on 
  for ii = 1: length(results.pts.x)
  h.pt(ii) = plot(results.pts_scaled.x(ii),results.pts_scaled.z(ii),'o');
  end
  rpt = [results.pts_scaled.x(1), results.pts_scaled.z(1)];
  rectdim = results.ref_size.frac*[image.pix_scaled.x, image.pix_scaled.z];
  h.rec = rectangle('Position',[rpt-rectdim/2,rectdim]);
end

%% plot interpolated image and points (in progress)
function h = plot_pts_original(image,results,h)
x = results.pts.x*results.pix.x/image.pix.x;
z = results.pts.x*results.pix.z/image.pix.z;
figure, imshow(results.interp_img);
hold on 
  for ii = 1: length(x)
  h.ptO(ii) = plot(x(ii),z(ii),'o');
  end
  rpt = [x(1), z(1)];
  rectdim = results.ref_size.frac*[results.pix.x, results.pix.x];
  h.recO = rectangle('Position',[rpt-rectdim/2,rectdim]);
end

%% plot offset curves
function h = plot_offset(image,results,h)
figure
subplot(1,2,1); ax1 = gca; hold on
subplot(1,2,2); ax2 = gca; hold on
title(ax1, 'Z Offset'); title(ax2, 'X Offset');
xlabel(ax1, 'Pressure (Pa)'); xlabel(ax2, 'Pressure (Pa)');
ylabel(ax1, 'Offset (um)'); ylabel(ax2, 'Offset (um)'); 

for ii = 1:length(results.pts.x)
    h.offz(ii) = plot(ax1,image.pressure, results.offset.z(:,ii));
    h.offx(ii) = plot(ax2,image.pressure, results.offset.x(:,ii));
end
end

%% plot displacement curves and find best fit line
function h = plot_disp(image,results,h)
zero = find(image.pressure==0);
Z = cell(length(results.pts.x),1);
X=Z;
for ii = 1:length(results.pts.x)
Z{ii} = results.offset.z(:,ii) - results.offset.z(zero,ii);
X{ii} = results.offset.x(:,ii) - results.offset.x(zero,ii);
end

figure,
subplot(1,2,1); ax1 = gca; hold on;
subplot(1,2,2); ax2 = gca; hold on;
title(ax1, 'Z Disp'); title(ax2, 'X Disp');
xlabel(ax1, 'Pressure (Pa)'); xlabel(ax2, 'Pressure (Pa)');
ylabel(ax1, 'Displacement (um)'); ylabel(ax2, 'Displacement (um)');

for ii = 1:length(Z)
    h.dz(ii) = plot(ax1,image.pressure, Z{ii});
    h.dx(ii) = plot(ax2,image.pressure, X{ii});
    [fz,gfz] = fit(image.pressure',Z{ii},'poly1');
    [fx,gfx] = fit(image.pressure',X{ii},'poly1');
    h.dzfit(ii,:) = [coeffvalues(fz), gfz.rsquare];
    h.dxfit(ii,:) = [coeffvalues(fx), gfx.rsquare];
end
end