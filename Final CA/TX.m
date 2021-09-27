function [output, header] = TX(input, nc, clipping, IFFT_points)

sfc = ceil(2^13/nc);
frame_length = sfc*nc;

% 1. QPSK Modulator:
QPSK_output = changem(bi2de(input,2), [0 1 3 2], [0 1 2 3]);

% 2. Frame Divider: 
r = frame_length - mod(length(QPSK_output'), frame_length);
Frame_Divider_output = reshape(cat(2, QPSK_output', zeros(1, r)), frame_length, length(cat(2, QPSK_output', zeros(1, r)))/frame_length);

% 3. Serial to Parallel: 
s2p_output = reshape(Frame_Divider_output, sfc, nc, size(Frame_Divider_output, 2));

% 4. DPSK Modulator: 
reference_addded = zeros(size(s2p_output, 1)+1, size(s2p_output, 2),size(s2p_output, 3));
reference_addded(1,:,:) = randi([0 3], size(s2p_output, 2), size(s2p_output, 3));
reference_addded(2:(size(s2p_output, 1)+1),:,:) = s2p_output;

DPSK_output = zeros(size(s2p_output, 1)+1, size(s2p_output, 2), size(s2p_output, 3));
for row = 2:(size(s2p_output, 1)+1)
    DPSK_output(row,:,:) = mod(reference_addded(row,:,:)+reference_addded(row-1,:,:),4);
end
DPSK_output(1,:,:) = reference_addded(1,:,:);
DPSK_output = changem(DPSK_output, [1 -1 j -j], [0 2 1 3]);

% 5. IFFT bins: 
IFFT_bins_output = zeros(size(DPSK_output, 1), 1024, size(DPSK_output, 3));
IFFT_bins_output(:,(113:113+size(DPSK_output, 2)-1),:) = DPSK_output;
IFFT_bins_output(:,(513:513+size(DPSK_output, 2)-1),:) = conj(DPSK_output);

% 6. IFFT: 
IFFT_output = ifft(IFFT_bins_output, IFFT_points, 2);

% 7. CP Addition: 
CP_output = zeros(size(IFFT_output, 1 ), 1024*(1+1/4), size(IFFT_output, 3));
CP_output(:, (257:1280), :) = IFFT_output;
CP_output(:, (1:256), :) = IFFT_output(:, (769:1024), :);

% 8. Parallel to Serial:
p2s_output = reshape(CP_output, size(CP_output,1)*size(CP_output,2), size(CP_output,3));

% 9. Cascade Frames:
Cascade_Frames_output = reshape(p2s_output, 1, size(p2s_output, 1)* size(p2s_output, 2));
header = randi([0 1], 1, 8*1024*(sfc+1));
Cascade_Frames_output = cat(2, header, Cascade_Frames_output);
Cascade_Frames_output = cat(2, Cascade_Frames_output, header);
predicted_delay = randi([1 8*1024*(sfc+1)]); 
Cascade_Frames_output = cat(2, randi([0 1], 1, predicted_delay), Cascade_Frames_output);

% 10. Clipping:
clipping = 10^(clipping/10);
amp_max = max(abs(Cascade_Frames_output));
Cascade_Frames_output(abs(Cascade_Frames_output)>amp_max/clipping)= amp_max/clipping;
output = Cascade_Frames_output;

end