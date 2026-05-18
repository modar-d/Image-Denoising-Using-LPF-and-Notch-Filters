% Sinusoidal noise injection and frequency-domain denoising
% We add a 2D sinusoid to an image, then try to remove it using
% two different filters: a low-pass filter and a notch filter.

%% Load image
img = imread('cameraman.tif');
img = im2double(img);
[m, n] = size(img);

%% Add sinusoidal noise
% meshgrid gives us the (x,y) coordinate at every pixel so we can
% evaluate the sinusoid across the whole image at once
[x, y] = meshgrid(1:n, 1:m);   % x = column index, y = row index
noise   = 0.2 * sin(2*pi*30*x/n + 2*pi*40*y/m);
noisy   = img + noise;

%% 2D DFT of the noisy image
% fftshift moves DC to the center so the spectrum is easier to read
% and the filter geometry (circles centered at origin) just makes sense
F = fftshift(fft2(noisy));

% frequency coordinate grid, centered at (0,0)
[u, v] = meshgrid((0:n-1)-n/2, (0:m-1)-m/2);
d = sqrt(u.^2 + v.^2);   % radial distance from DC

%% Filter 1: Low-pass filter
% Our noise spike sits at radius sqrt(30^2 + 40^2) = 50,
% so a cutoff of 45 will cut it out -- but it also blurs the image.
H_lpf   = double(d <= 45);
img_lpf = real(ifft2(ifftshift(H_lpf .* F)));

%% Filter 2: Notch filter
% Since the noise is a single sinusoid, it only occupies two points
% in the spectrum: (u,v) = (+30,+40) and (-30,-40).
% A notch filter zeros out just those two spots and leaves everything else.
d_pos = sqrt((u - 30).^2 + (v - 40).^2);
d_neg = sqrt((u + 30).^2 + (v + 40).^2);

H_notch = ones(m, n);
H_notch(d_pos <= 6) = 0;
H_notch(d_neg <= 6) = 0;

img_notch = real(ifft2(ifftshift(H_notch .* F)));

%% Quality metrics
% clip to [0,1] first -- the added noise can push values outside that range
noisy_c     = max(0, min(1, noisy));
img_lpf_c   = max(0, min(1, img_lpf));
img_notch_c = max(0, min(1, img_notch));

fprintf('PSNR  -- noisy: %.1f dB  |  LPF: %.1f dB  |  Notch: %.1f dB\n', ...
    psnr(noisy_c, img), psnr(img_lpf_c, img), psnr(img_notch_c, img));
fprintf('SSIM  -- noisy: %.3f    |  LPF: %.3f    |  Notch: %.3f\n', ...
    ssim(noisy_c, img), ssim(img_lpf_c, img), ssim(img_notch_c, img));

%% Results
figure;

subplot(231);
imshow(img, []);
title('Original');

subplot(232);
imshow(noisy_c, []);
title('Noisy');

subplot(233);
imshow(noise, []);
title('Noise pattern');

subplot(234);
imshow(log(1 + abs(F)), []);
title('DFT magnitude (noisy) - spot the spikes');

subplot(235);
imshow(img_lpf_c, []);
title('LPF denoised');

subplot(236);
imshow(img_notch_c, []);
title('Notch denoised');
