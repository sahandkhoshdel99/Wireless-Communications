function [output, correlation, sep] = RX(input, pilot, SNR_dB, Hk, FFT_points, nc, equalizer)
sfc = ceil(2^13/nc);
frame_len = (1024 * (sfc+1));

% 1. Equalizer 
if(equalizer == "eqz_on") 
    SNR = 10^(SNR_dB/10);
    Weights = conj(Hk)./(abs(Hk).^2+1./(length(input)*SNR));
    input = input.*Weights;
end

% 2. Synchronization with Correlating the Pilot Signal
[temp,sep]=xcorr(input(1:3*length(pilot)),pilot);
correlation = temp;
temp=temp(sep>=0);
idx=find(temp==max(temp));

% 3. Frames Detection
input = input(idx:end);
header_len = 8 * frame_len;
input   = input (header_len+1:length(input)- header_len); 
Frames_Detection_output = reshape(input , frame_len*(1+1/4), []); 

% 4. Serial to Parallel
s2p_output = reshape(Frames_Detection_output, [],(1024*(1+1/4)),size(Frames_Detection_output, 2));

% 5. CP Removal
CP_Remove_output = s2p_output(:,(size(s2p_output, 2)/5+1):size(s2p_output, 2),:);

% 6. FFT
FFT_output = fft(CP_Remove_output, FFT_points, 2);

% 7. Extract Carriers
Extract_Carriers_output = FFT_output(:,113:113+nc-1,:);

% 8. DPSK Demodulator
distance = zeros(size(Extract_Carriers_output, 1), size(Extract_Carriers_output, 2), size(Extract_Carriers_output, 3), 4);
distance(:,:,:,1) = (real(Extract_Carriers_output)-1).^2 + imag(Extract_Carriers_output).^2;
distance(:,:,:,2) = (real(Extract_Carriers_output)).^2 + (imag(Extract_Carriers_output)-1).^2;
distance(:,:,:,3) = (real(Extract_Carriers_output)+1).^2 + imag(Extract_Carriers_output).^2;
distance(:,:,:,4) = (real(Extract_Carriers_output)).^2 + (imag(Extract_Carriers_output)+1).^2;
[~, detected] = min(distance, [], 4);
detected=detected - 1;
for row = 2:size(Extract_Carriers_output, 1)
    detected(row,:,:) = mod(detected((row),:,:)-detected((row-1),:,:), 4);
end
DPSK_output = detected((2:size(Extract_Carriers_output, 1)),:,:);

% 8. Parallel to Serial
p2s_output = reshape(DPSK_output, size(DPSK_output, 1)*size(DPSK_output, 2), size(DPSK_output, 3));

% 9. Cascade Frames
Cascade_Frames_output = reshape(p2s_output, size(p2s_output,1)*size(p2s_output,2), 1);

% 10. QPSK Demodulator
output = de2bi(changem(Cascade_Frames_output, [0 1 2 3], [0 1 3 2]));

end