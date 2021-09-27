function [output, corr, corr_index] = OFDM(input, FFT_points, nc, SNR, clip_threshold, channel, equalizer)
[out_tx, pilot] = TX(input, nc, clip_threshold, FFT_points);
[out_ch, Hk] = Channel(out_tx, SNR, channel);
[output, corr, corr_index] = RX(out_ch, pilot, SNR, Hk, FFT_points, nc, equalizer);
end

